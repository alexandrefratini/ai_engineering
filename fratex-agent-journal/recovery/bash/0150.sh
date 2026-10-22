cd /home/user/endsi3g/fratex-agent && cat > apps/app/lib/use-audience.ts <<'EOF'
"use client";

import { useQuery } from "@tanstack/react-query";
import { useTRPC } from "@/lib/trpc/client";

export type Audience = "staff" | "realtor";

export function audienceOf(roles: string[]): Audience {
	return roles.length > 0 && roles.every((role) => role === "REALTOR")
		? "realtor"
		: "staff";
}

export function useAudience(): Audience {
	const trpc = useTRPC();
	const agencies = useQuery(trpc.realEstate.agencies.queryOptions());
	return audienceOf(
		agencies.data?.agencies.map((agency) => agency.role) ?? [],
	);
}
EOF
python3 - <<'EOF'
p="apps/app/components/app-icon-rail.tsx"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:60]
    s=s.replace(a,b)
rep('''	group: "real-estate" | "crm" | "system";
	iconClassName?: string;''','''	group: "real-estate" | "crm" | "system";
	staffOnly?: boolean;
	iconClassName?: string;''')
rep('''		title: "Courtiers",
		href: "/real-estate/realtors",
		icon: IdManagement,
		group: "real-estate",''','''		title: "Courtiers",
		href: "/real-estate/realtors",
		icon: IdManagement,
		group: "real-estate",
		staffOnly: true,''')
s=s.replace('''		group: "crm",''','''		group: "crm",
		staffOnly: true,''')
rep('''	const prefetchSection = usePrefetchSection();

	const items = useMemo(
		() =>
			ITEMS.map((item) => ({
				...item,
				section: item.href,
				href: workspaceUrl(item.href),
				related: item.related?.map((path) => workspaceUrl(path)),
			})),
		[workspaceUrl],
	);''','''	const prefetchSection = usePrefetchSection();
	const audience = useAudience();

	const items = useMemo(
		() =>
			ITEMS.filter((item) => audience === "staff" || !item.staffOnly).map(
				(item) => ({
					...item,
					section: item.href,
					href: workspaceUrl(item.href),
					related: item.related?.map((path) => workspaceUrl(path)),
				}),
			),
		[workspaceUrl, audience],
	);''')
rep('''import { useWorkspaceUrl } from "@/lib/use-workspace-url";''','''import { useAudience } from "@/lib/use-audience";
import { useWorkspaceUrl } from "@/lib/use-workspace-url";''')
open(p,"w").write(s)
EOF
grep -c "staffOnly: true" apps/app/components/app-icon-rail.tsx; cat > apps/app/test/audience.spec.ts <<'EOF'
import { describe, expect, it } from "bun:test";
import { audienceOf } from "@/lib/use-audience";

describe("audienceOf", () => {
	it("treats a user who is only a realtor in every agency as a realtor", () => {
		expect(audienceOf(["REALTOR"])).toBe("realtor");
		expect(audienceOf(["REALTOR", "REALTOR"])).toBe("realtor");
	});

	it("keeps the full navigation for staff and for users without an agency", () => {
		expect(audienceOf(["REALTOR", "ADMIN"])).toBe("staff");
		expect(audienceOf(["OWNER"])).toBe("staff");
		expect(audienceOf(["MARKETER"])).toBe("staff");
		expect(audienceOf([])).toBe("staff");
	});
});
EOF
bunx biome check --write apps/app/lib/use-audience.ts apps/app/components/app-icon-rail.tsx apps/app/test/audience.spec.ts 2>&1 | tail -1; cd apps/app && bunx tsc --noEmit 2>&1 | tail -4; echo tsc $?; bun test test/audience.spec.ts 2>&1 | tail -3