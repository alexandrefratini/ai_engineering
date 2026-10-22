cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/real-estate/leads" && cat > new-lead-control.tsx <<'EOF'
"use client";

import { Button } from "@crm/ui/components/button";
import { NewLeadDialog } from "@crm/ui/components/lead-tools";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useAudience } from "@/lib/use-audience";
import { useTRPC } from "@/lib/trpc/client";
import { useWorkspaceUrl } from "@/lib/use-workspace-url";

export function NewLeadControl({ agencyId }: { agencyId: string }) {
	const trpc = useTRPC();
	const cache = useQueryClient();
	const router = useRouter();
	const href = useWorkspaceUrl();
	const audience = useAudience();
	const clients = useQuery(
		trpc.realEstate.clients.queryOptions(
			{ agencyId },
			{ enabled: audience === "staff" },
		),
	);
	const create = useMutation(trpc.realEstate.createLead.mutationOptions());
	return (
		<NewLeadDialog
			trigger={<Button>Nouveau prospect</Button>}
			realtors={
				audience === "staff"
					? clients.data?.clients.map((client) => ({
							id: client.id,
							name: client.name,
						}))
					: undefined
			}
			onSubmit={async (data) => {
				const result = await create.mutateAsync({ agencyId, ...data });
				await cache.invalidateQueries(trpc.realEstate.pathFilter());
				return result;
			}}
			onOpenLead={(id) => {
				router.push(href(`/real-estate/leads/${id}?agencyId=${agencyId}`));
			}}
		/>
	);
}
EOF
python3 - <<'EOF'
p="leads-view.tsx"
s=open(p).read()
s=s.replace('''						<WorkspaceSelect
							label="Statut"
							value={status ?? "ALL"}
							options={[{ id: "ALL", name: "Tous" }, ...LEAD_STATUS_OPTIONS]}
							onChange={(value) => {
								void setStatus(value === "ALL" ? null : (value as LeadStatus));
							}}
						/>
					</WorkspaceToolbar>''','''						<WorkspaceSelect
							label="Statut"
							value={status ?? "ALL"}
							options={[{ id: "ALL", name: "Tous" }, ...LEAD_STATUS_OPTIONS]}
							onChange={(value) => {
								void setStatus(value === "ALL" ? null : (value as LeadStatus));
							}}
						/>
						<div className="ml-auto">
							<NewLeadControl agencyId={scope.agencyId} />
						</div>
					</WorkspaceToolbar>''')
lines=s.split("\n")
idx=max(i for i,l in enumerate(lines) if l.startswith("import "))
j=idx
while not lines[j].rstrip().endswith(";"): j+=1
lines.insert(j+1,'import { NewLeadControl } from "./new-lead-control";')
open(p,"w").write("\n".join(lines))
p="page.tsx"
s=open(p).read()
s=s.replace('''	title: "Prospects Immobiliers",''','''	title: "Prospects",''')
s=s.replace('''					<PageShellTitle>Prospects Immobiliers</PageShellTitle>
					<PageShellDescription>
						Tous les leads capturés depuis Meta Ads avec qualification SDR et
						routage courtier.
					</PageShellDescription>''','''					<PageShellTitle>Prospects</PageShellTitle>
					<PageShellDescription>
						Tous vos prospects : publicités Meta, références, appels et visites
						libres. Un clic ouvre la fiche.
					</PageShellDescription>''')
open(p,"w").write(s)
EOF
grep -n "WorkspaceToolbar" /home/user/endsi3g/fratex-agent/packages/ui/src/components/real-estate-workspace.tsx | head -2; grep -n "export function WorkspaceToolbar" -A6 /home/user/endsi3g/fratex-agent/packages/ui/src/components/real-estate-workspace.tsx