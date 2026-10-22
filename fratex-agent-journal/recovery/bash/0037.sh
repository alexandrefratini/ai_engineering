cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
D="apps/app/app/(app)/[slug]/real-estate/realtors/"
p=D+"realtor-onboarding.tsx"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:70]
    s=s.replace(a,b)
rep('''		await cache.invalidateQueries({ queryKey: trpc.realEstate.pathKey() });
		const query = `?agencyId=${created.agencyId}&client=${created.id}`;
		return {
			steps: [
				{
					label: "Relier un formulaire Meta Lead Ads",''','''		await cache.invalidateQueries({ queryKey: trpc.realEstate.pathKey() });
		const roster = await cache.fetchQuery(
			trpc.realEstate.clients.queryOptions({ agencyId: created.agencyId }),
		);
		const setup = roster.clients.find(
			(client) => client.id === created.id,
		)?.setup;
		const query = `?agencyId=${created.agencyId}&client=${created.id}`;
		return {
			steps: [
				{
					label: "Relier un formulaire Meta Lead Ads",''')
rep('''					href: workspaceUrl(slug, `/settings/connections/meta-ads${query}`),
				},''','''					href: workspaceUrl(slug, `/settings/connections/meta-ads${query}`),
					done: setup?.metaForm,
				},''')
rep('''						`/settings/connections/realtor-calendar${query}`,
					),
				},''','''						`/settings/connections/realtor-calendar${query}`,
					),
					done: setup?.calendar,
				},''')
rep('''					href: workspaceUrl(slug, `/settings/connections/twilio${query}`),
				},''','''					href: workspaceUrl(slug, `/settings/connections/twilio${query}`),
					done: setup?.sms,
				},''')
rep('''					onSubmitSuccess={handleSubmit}
				/>''','''					onSubmitSuccess={handleSubmit}
					successActions={
						<>
							<Button asChild variant="outline" size="sm">
								<Link href={workspaceUrl(slug, "/real-estate/realtors")}>
									Voir tous les courtiers
								</Link>
							</Button>
							<Button
								variant="outline"
								size="sm"
								onClick={() => setRound((value) => value + 1)}
							>
								Ajouter un autre courtier
							</Button>
						</>
					}
				/>''')
rep('''					key={scope.agencyId}''','''					key={`${scope.agencyId}-${round}`}''')
rep('''	const cache = useQueryClient();''','''	const cache = useQueryClient();
	const [round, setRound] = useState(0);''')
rep('''import { RealEstateWorkspace } from "@crm/ui/components/real-estate-workspace";''','''import { Button } from "@crm/ui/components/button";
import { RealEstateWorkspace } from "@crm/ui/components/real-estate-workspace";''')
rep('''import { useMutation, useQueryClient } from "@tanstack/react-query";''','''import { useMutation, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { useState } from "react";''')
open(p,"w").write(s)

p=D+"realtors-view.tsx"
s=open(p).read()
rep('''import { RealtorRoster } from "@crm/ui/components/realtor-roster";''','''import {
	RealtorRoster,
	RealtorRosterSummary,
} from "@crm/ui/components/realtor-roster";''')
rep('''				) : (
					<RealtorRoster
						realtors={clients.data.clients.map((client) => ({
							...client,
							lastLeadAt: client.lastLeadAt
								? new Date(client.lastLeadAt).toISOString()
								: null,
						}))}''','''				) : (
					<>
						<RealtorRosterSummary realtors={clients.data.clients} />
						<RealtorRoster
						realtors={clients.data.clients.map((client) => ({
							...client,
							lastLeadAt: client.lastLeadAt
								? new Date(client.lastLeadAt).toISOString()
								: null,
						}))}''')
rep('''							);
						}}
					/>
				))}''','''							);
						}}
					/>
					</>
				))}''')
open(p,"w").write(s)

p="packages/ui/src/components/realtor-roster.tsx"
s=open(p).read()
rep('''import { Avatar, AvatarFallback } from "./avatar";''','''import { Avatar, AvatarFallback } from "./avatar";
import { MetricGrid, MetricTile, SegmentMeter } from "./real-estate-visuals";''')
rep('''<AvatarFallback>{initialsFromName(realtor.name)}</AvatarFallback>''','''<AvatarFallback>{initialsFromName(realtor.name.split(",")[0] ?? realtor.name)}</AvatarFallback>''')
rep('''export function RealtorRoster({''','''export function RealtorRosterSummary({
	realtors,
}: {
	realtors: Pick<RosterRealtor, "status" | "leadsCount" | "appointmentsCount" | "setup">[];
}) {
	const active = realtors.filter((realtor) => realtor.status === "ACTIVE").length;
	const ready = realtors.filter((realtor) => SETUP_STEPS.every((step) => realtor.setup[step.key])).length;
	const leads = realtors.reduce((sum, realtor) => sum + realtor.leadsCount, 0);
	const appointments = realtors.reduce((sum, realtor) => sum + realtor.appointmentsCount, 0);
	return (
		<MetricGrid>
			<MetricTile
				index={0}
				label="Courtiers actifs"
				value={active}
				hint={`${realtors.length} au total`}
				info="Courtiers au statut Actif. Les courtiers en pause ou partis restent visibles, mais l'assistant ne leur attribue plus de prospects."
			/>
			<MetricTile
				index={1}
				label="Prêts à recevoir"
				value={`${ready}/${realtors.length}`}
				hint={ready === realtors.length ? "Tous configurés" : `${realtors.length - ready} à terminer`}
				info="Courtiers dont le formulaire Meta, l'agenda et le numéro SMS sont tous reliés. Sans ces trois éléments, l'assistant ne peut pas recevoir, contacter et réserver seul."
			>
				<SegmentMeter value={ready} total={Math.max(realtors.length, 1)} label="Courtiers entièrement configurés" />
			</MetricTile>
			<MetricTile
				index={2}
				label="Prospects reçus"
				value={leads}
				hint="Tous courtiers, depuis le début"
				info="Nombre total de prospects attribués à ces courtiers, toutes sources confondues."
			/>
			<MetricTile
				index={3}
				label="Rendez-vous obtenus"
				value={appointments}
				hint={leads > 0 ? `${Math.round((appointments / leads) * 100)} % des prospects` : "Aucun prospect pour l'instant"}
				info="Rendez-vous réservés pour ces courtiers, quel que soit leur statut. Le pourcentage compare ce nombre au total des prospects reçus."
			/>
		</MetricGrid>
	);
}

export function RealtorRoster({''')
open(p,"w").write(s)
EOF
grep -n "export function SegmentMeter" -A14 packages/ui/src/components/real-estate-visuals.tsx