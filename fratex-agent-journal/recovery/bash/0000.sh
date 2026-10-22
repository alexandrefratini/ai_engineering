D="/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/real-estate/realtors"; mkdir -p "$D/new" && cat > "$D/realtor-onboarding.tsx" <<'EOF'
"use client";

import { RealEstateWorkspace } from "@crm/ui/components/real-estate-workspace";
import {
	type RealtorOnboardingData,
	RealtorOnboardingForm,
} from "@crm/ui/components/realtor-onboarding-form";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useTRPC } from "@/lib/trpc/client";
import { workspaceUrl } from "@/lib/workspace-url";
import { AgencyControl, useAgency } from "../use-agency";

export function RealtorOnboarding({ slug }: { slug: string }) {
	const trpc = useTRPC();
	const scope = useAgency();
	const cache = useQueryClient();
	const createClient = useMutation(
		trpc.realEstate.createClient.mutationOptions(),
	);
	const agencyName = scope.query.data?.agencies.find(
		(agency) => agency.id === scope.agencyId,
	)?.name;

	async function handleSubmit(data: RealtorOnboardingData) {
		const created = await createClient.mutateAsync({
			agencyId: scope.agencyId,
			brokerage: data.agency,
			licenseNumber: data.licenseNumber,
			propertyTypes: data.propertyTypes,
			crmChoice: data.crmChoice,
			calendarLink: data.calendarLink || undefined,
			timezone: data.timezone,
			name: data.name,
			email: data.email,
			phone: data.phone || undefined,
			targetZones: data.targetZones,
		});
		await cache.invalidateQueries({ queryKey: trpc.realEstate.pathKey() });
		const query = `?agencyId=${created.agencyId}&client=${created.id}`;
		return {
			steps: [
				{
					label: "Relier un formulaire Meta Lead Ads",
					description:
						"Les prospects de ses publicités arriveront ici en moins d'une minute.",
					href: workspaceUrl(slug, `/settings/connections/meta-ads${query}`),
				},
				{
					label: "Connecter son agenda",
					description:
						"L'assistant proposera de vrais créneaux et réservera les visites.",
					href: workspaceUrl(
						slug,
						`/settings/connections/realtor-calendar${query}`,
					),
				},
				{
					label: "Vérifier le numéro SMS de l'agence",
					description: "Indispensable pour le premier contact automatique.",
					href: workspaceUrl(slug, `/settings/connections/twilio${query}`),
				},
				{
					label: "Ouvrir son portail",
					description: "Ses résultats s'afficheront dès le premier prospect.",
					href: workspaceUrl(slug, `/real-estate/portal${query}`),
				},
			],
		};
	}

	return (
		<RealEstateWorkspace>
			<AgencyControl scope={scope} />
			{scope.agencyId && (
				<RealtorOnboardingForm
					key={scope.agencyId}
					defaults={{ agency: agencyName }}
					onSubmitSuccess={handleSubmit}
				/>
			)}
		</RealEstateWorkspace>
	);
}
EOF
cat > "$D/new/page.tsx" <<'EOF'
import type { Metadata } from "next";
import { Suspense } from "react";
import {
	PageShell,
	PageShellContent,
	PageShellDescription,
	PageShellHeader,
	PageShellHeading,
	PageShellLoading,
	PageShellTitle,
} from "@/components/page-shell";
import { requireSession } from "@/lib/session";
import { RealtorOnboarding } from "../realtor-onboarding";

export const metadata: Metadata = {
	title: "Nouveau courtier",
};

export default function NewRealtorPage({
	params,
}: PageProps<"/[slug]/real-estate/realtors/new">) {
	return (
		<PageShell className="min-h-0">
			<PageShellHeader>
				<PageShellHeading>
					<PageShellTitle>Nouveau courtier</PageShellTitle>
					<PageShellDescription>
						Trois minutes pour créer son profil. Les connexions (Meta, agenda,
						SMS) se font ensuite, étape par étape.
					</PageShellDescription>
				</PageShellHeading>
			</PageShellHeader>

			<PageShellContent className="min-h-0">
				<Suspense fallback={<PageShellLoading />}>
					<NewRealtorLoader params={params} />
				</Suspense>
			</PageShellContent>
		</PageShell>
	);
}

async function NewRealtorLoader({
	params,
}: Pick<PageProps<"/[slug]/real-estate/realtors/new">, "params">) {
	await requireSession();
	const { slug } = await params;

	return <RealtorOnboarding slug={slug} />;
}
EOF
cat > "$D/realtors-view.tsx" <<'EOF'
"use client";

import { Button } from "@crm/ui/components/button";
import {
	RealEstateWorkspace,
	WorkspaceLoading,
	WorkspaceNotice,
} from "@crm/ui/components/real-estate-workspace";
import { RealtorRoster } from "@crm/ui/components/realtor-roster";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { useTRPC } from "@/lib/trpc/client";
import { useWorkspaceUrl } from "@/lib/use-workspace-url";
import { AgencyControl, useAgency } from "../use-agency";

export function RealtorsView() {
	const trpc = useTRPC();
	const href = useWorkspaceUrl();
	const scope = useAgency();
	const clients = useQuery(
		trpc.realEstate.clients.queryOptions(
			{ agencyId: scope.agencyId },
			{ enabled: Boolean(scope.agencyId) },
		),
	);

	return (
		<RealEstateWorkspace>
			<AgencyControl scope={scope} />
			{scope.agencyId &&
				(clients.isPending ? (
					<WorkspaceLoading />
				) : clients.error ? (
					<WorkspaceNotice
						title="Courtiers indisponibles"
						error={clients.error.message}
						onRetry={() => {
							void clients.refetch();
						}}
					/>
				) : clients.data.clients.length === 0 ? (
					<WorkspaceNotice title="Aucun courtier. Ajoutez le premier pour recevoir des prospects." />
				) : (
					<RealtorRoster
						realtors={clients.data.clients.map((client) => ({
							...client,
							lastLeadAt: client.lastLeadAt
								? new Date(client.lastLeadAt).toISOString()
								: null,
						}))}
						renderActions={(realtor) => {
							const query = `?agencyId=${scope.agencyId}&client=${realtor.id}`;
							const missing = !(
								realtor.setup.metaForm &&
								realtor.setup.calendar &&
								realtor.setup.sms
							);
							return (
								<>
									{missing && (
										<Button asChild variant="outline" size="sm">
											<Link
												href={href(
													`/settings/connections/${!realtor.setup.metaForm ? "meta-ads" : !realtor.setup.calendar ? "realtor-calendar" : "twilio"}${query}`,
												)}
											>
												Terminer la configuration
											</Link>
										</Button>
									)}
									<Button asChild variant="outline" size="sm">
										<Link href={href(`/real-estate/portal${query}`)}>Portail</Link>
									</Button>
								</>
							);
						}}
					/>
				))}
		</RealEstateWorkspace>
	);
}
EOF
cat > "$D/page.tsx" <<'EOF'
import { Button } from "@crm/ui/components/button";
import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import {
	PageShell,
	PageShellActions,
	PageShellContent,
	PageShellDescription,
	PageShellHeader,
	PageShellHeading,
	PageShellLoading,
	PageShellTitle,
} from "@/components/page-shell";
import { requireSession } from "@/lib/session";
import { workspaceUrl } from "@/lib/workspace-url";
import { RealtorsView } from "./realtors-view";

export const metadata: Metadata = {
	title: "Courtiers",
};

export default function RealtorsPage({
	params,
}: PageProps<"/[slug]/real-estate/realtors">) {
	return (
		<PageShell className="min-h-0">
			<PageShellHeader>
				<PageShellHeading>
					<PageShellTitle>Courtiers</PageShellTitle>
					<PageShellDescription>
						Les courtiers servis par l'agence, leurs résultats et ce qu'il reste
						à configurer pour que l'assistant travaille pour eux.
					</PageShellDescription>
				</PageShellHeading>
				<PageShellActions>
					<Suspense fallback={null}>
						<NewRealtorButton params={params} />
					</Suspense>
				</PageShellActions>
			</PageShellHeader>

			<PageShellContent className="min-h-0">
				<Suspense fallback={<PageShellLoading />}>
					<RealtorsLoader />
				</Suspense>
			</PageShellContent>
		</PageShell>
	);
}

async function NewRealtorButton({
	params,
}: Pick<PageProps<"/[slug]/real-estate/realtors">, "params">) {
	const { slug } = await params;

	return (
		<Button asChild>
			<Link href={workspaceUrl(slug, "/real-estate/realtors/new")}>
				Ajouter un courtier
			</Link>
		</Button>
	);
}

async function RealtorsLoader() {
	await requireSession();

	return <RealtorsView />;
}
EOF
cd "/home/user/endsi3g/fratex-agent/apps/app/app/(landing)/onboarding/realtor" && cat > realtor-onboarding-view.tsx <<'EOF'
"use client";

import { RealtorOnboarding } from "@/app/(app)/[slug]/real-estate/realtors/realtor-onboarding";

export function RealtorOnboardingView({ slug }: { slug: string }) {
	return <RealtorOnboarding slug={slug} />;
}
EOF
python3 - <<'EOF'
p="page.tsx"
s=open(p).read()
s=s.replace('''	title: "Intégration Partenaire Courtier — Fratex Agent",
	description:
		"Rejoignez le réseau de courtiers partenaires Fratex et recevez des leads immobiliers ultra-qualifiés par IA.",''','''	title: "Ajouter un courtier — Fratex Agent",
	description:
		"Créez le profil d'un courtier partenaire Fratex pour qu'il reçoive des rendez-vous qualifiés par l'assistant IA.",''')
s=s.replace('''		<div className="flex min-h-screen flex-col items-center justify-center bg-background px-4 py-12">
			<div className="mb-6 flex flex-col items-center gap-2 text-center">
				<span className="font-mono text-xs tracking-wider text-primary uppercase">
					Plateforme Partenaire Fratex
				</span>
				<h1 className="font-bold text-3xl tracking-tight text-foreground sm:text-4xl">
					Onboarding Courtier Immobilier
				</h1>
				<p className="max-w-md text-muted-foreground text-sm">
					Paramétrez vos territoires de prospection et connectez votre agenda
					pour recevoir des rendez-vous qualifiés.
				</p>
			</div>

			<RealtorOnboardingView slug={workspace?.slug ?? "workspace"} />
		</div>''','''		<div className="flex min-h-screen flex-col items-center bg-background px-4 py-10">
			<div className="flex w-full max-w-3xl flex-col gap-6">
				<div className="flex flex-col gap-1.5">
					<span className="text-xs font-medium text-primary">Fratex Agent</span>
					<h1 className="font-medium text-2xl tracking-tight text-foreground">
						Ajouter un courtier
					</h1>
					<p className="text-muted-foreground text-sm">
						Ses secteurs, ses types de propriété et ses outils. L'assistant s'en
						sert pour qualifier les prospects et réserver ses rendez-vous.
					</p>
				</div>

				<RealtorOnboardingView slug={workspace?.slug ?? "workspace"} />
			</div>
		</div>''')
open(p,"w").write(s)
EOF
cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/app/lib/navigation.ts"
s=open(p).read()
s=s.replace('''	{
		label: "Estimateur et offres",''','''	{
		label: "Courtiers",
		href: "/real-estate/realtors",
		group: "Immobilier",
		keywords: ["partenaires", "clients", "configuration", "onboarding"],
	},
	{
		label: "Ajouter un courtier",
		href: "/real-estate/realtors/new",
		group: "Immobilier",
		keywords: ["nouveau", "onboarding", "intégration"],
	},
	{
		label: "Estimateur et offres",''')
s=s.replace('''	valuation: "Estimateur et offres",''','''	valuation: "Estimateur et offres",
	realtors: "Courtiers",
	new: "Nouveau",''')
open(p,"w").write(s)
EOF
bunx biome check --write "apps/app/app/(app)/[slug]/real-estate/realtors" "apps/app/app/(landing)/onboarding/realtor" apps/app/lib/navigation.ts packages/ui/src/components/realtor-onboarding-form.tsx packages/ui/src/components/realtor-roster.tsx >/dev/null 2>&1; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -5); (cd packages/ui && bunx tsc --noEmit 2>&1 | tail -5)