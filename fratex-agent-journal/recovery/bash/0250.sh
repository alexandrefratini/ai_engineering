cd /home/user/endsi3g/fratex-agent && cat >> apps/app/lib/navigation.ts <<'EOF'

export function presenceLabel(segments: string[]): string {
	const visible = segments.filter((segment) => !HIDDEN_SEGMENTS.has(segment));
	if (visible.length === 0) return "Accueil";
	const leadIndex = visible.indexOf("leads");
	if (leadIndex >= 0 && visible[leadIndex + 1] && visible[leadIndex + 1] !== "new")
		return "Fiche d'un prospect";
	const known = [...visible]
		.reverse()
		.map((segment) => SEGMENT_LABELS[segment])
		.find(Boolean);
	return known ?? "Fratex";
}
EOF
cat >> apps/app/test/navigation.spec.ts <<'EOF'

describe("what teammates see about the page you are on", () => {
	it("names the page without exposing a prospect", () => {
		expect(presenceLabel([])).toBe("Accueil");
		expect(presenceLabel(["real-estate", "inbox"])).toBe("Boîte de réception");
		expect(presenceLabel(["real-estate", "leads", "cmabc123"])).toBe(
			"Fiche d'un prospect",
		);
		expect(presenceLabel(["settings", "connections", "twilio"])).toBe(
			"SMS Twilio",
		);
		expect(presenceLabel(["something-unknown"])).toBe("Fratex");
	});
});
EOF
sed -i 's/import { matchPages, NAV_PAGES, SEGMENT_LABELS } from "..\/lib\/navigation";/import {\n\tmatchPages,\n\tNAV_PAGES,\n\tpresenceLabel,\n\tSEGMENT_LABELS,\n} from "..\/lib\/navigation";/' apps/app/test/navigation.spec.ts && python3 - <<'EOF'
p="/home/user/endsi3g/fratex-agent/apps/app/components/team-presence-control.tsx"
s=open(p).read()
s=s.replace('''import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import { PRESENCE } from "@/lib/presence-config";
import { useTRPC } from "@/lib/trpc/client";''','''import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect } from "react";
import { presenceLabel } from "@/lib/navigation";
import { PRESENCE } from "@/lib/presence-config";
import { useTRPC } from "@/lib/trpc/client";
import { useWorkspaceUrl } from "@/lib/use-workspace-url";''')
s=s.replace('''	const trpc = useTRPC();
	const cache = useQueryClient();''','''	const trpc = useTRPC();
	const cache = useQueryClient();
	const href = useWorkspaceUrl();
	const pathname = usePathname();
	const segments = pathname.split("/").filter(Boolean).slice(1);
	const path = `/${segments.join("/")}`;
	const label = presenceLabel(segments);''')
s=s.replace('''	useEffect(() => {
		const beat = () => {
			if (document.visibilityState === "visible") mutate();
		};''','''	useEffect(() => {
		const beat = () => {
			if (document.visibilityState === "visible") mutate({ path, label });
		};''')
s=s.replace('''	}, [mutate]);''','''	}, [mutate, path, label]);''')
s=s.replace('''		<TeamPresence
			onlineCount={team.data.onlineCount}''','''		<TeamPresence
			onlineCount={team.data.onlineCount}
			renderPageLink={(page) => (
				<Link href={href(page.path)}>{page.label}</Link>
			)}''')
open(p,"w").write(s)
EOF
echo ok