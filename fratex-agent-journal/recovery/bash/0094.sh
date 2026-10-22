cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/settings/connections" && python3 - <<'EOF'
p="page.tsx"
s=open(p).read()
start=s.index("	const rows = [")
end=s.index("function ConnectionsFallback()")
new='''	const team: ConnectionItem[] = [
		{
			id: "google",
			name: "Google Workspace",
			purpose: "Classe les courriels Gmail sur la fiche du bon prospect.",
			logo: GoogleLogo,
			state: google.linked ? "ready" : "missing",
			status: google.linked ? "Connecté" : "Non connecté",
			explanation: google.linked
				? "Les courriels échangés avec vos prospects apparaissent dans la boîte de réception et sur leur fiche. Lecture seule."
				: "Facultatif. Reliez Gmail pour voir les courriels des prospects à côté des SMS.",
			action: (
				<TeamAction
					href={`/${slug}/settings/connections/google`}
					ready={google.linked}
				/>
			),
		},
		{
			id: "microsoft",
			name: "Microsoft 365",
			purpose: "Classe les courriels Outlook sur la fiche du bon prospect.",
			logo: MicrosoftLogo,
			state: microsoft.linked ? "ready" : "missing",
			status: microsoft.linked ? "Connecté" : "Non connecté",
			explanation: microsoft.linked
				? "Les courriels Outlook échangés avec vos prospects apparaissent sur leur fiche. Lecture seule."
				: "Facultatif. Pour les équipes qui utilisent Outlook plutôt que Gmail.",
			action: (
				<TeamAction
					href={`/${slug}/settings/connections/microsoft`}
					ready={microsoft.linked}
				/>
			),
		},
		{
			id: "slack",
			name: "Slack",
			purpose: "Prévient l'équipe quand un prospect demande un humain.",
			logo: SlackLogo,
			state: slack.connected ? "ready" : "missing",
			status: slack.connected
				? slack.workspace
					? `Connecté à ${slack.workspace}`
					: "Connecté"
				: "Non connecté",
			explanation: slack.connected
				? "Les agents peuvent écrire dans les canaux et aux personnes autorisés."
				: "Facultatif. Utile pour recevoir les alertes de reprise humaine dans Slack.",
			action: (
				<TeamAction
					href={`/${slug}/settings/connections/slack`}
					ready={slack.connected}
				/>
			),
		},
	];

	return (
		<main className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto px-(--spacing-page-inline) pt-(--spacing-page-top) pb-(--spacing-page-bottom)">
			<div className="mx-auto flex w-full max-w-(--container-page) flex-col gap-4">
				<header className="flex items-start justify-between gap-4">
					<div className="flex flex-col gap-1">
						<h1 className="font-medium text-2xl tracking-tight">Connexions</h1>
						<p className="max-w-2xl text-muted-foreground text-sm">
							Les outils qui apportent les prospects à Fratex et ce que
							l'assistant a le droit d'envoyer en votre nom.
						</p>
					</div>
					<Button asChild variant="outline">
						<Link href={`/${slug}/settings/connections?add=1`}>
							Ajouter un outil
						</Link>
					</Button>
				</header>
				<SdrConnectionsOverview slug={slug} />
				<ConnectionList
					index={1}
					title="Outils de l'équipe"
					description="Facultatifs. Ils complètent la fiche du prospect avec vos courriels et alertent l'équipe."
					items={team}
				/>
			</div>
			<AddConnectionDialog
				slug={slug}
				open={first(query.add) === "1"}
				connected={team
					.filter((item) => item.state === "ready")
					.map((item) => item.id)}
			/>
		</main>
	);
}

function TeamAction({ href, ready }: { href: string; ready: boolean }) {
	return (
		<Button asChild size="sm" variant="outline">
			<Link href={href}>{ready ? "Gérer" : "Connecter"}</Link>
		</Button>
	);
}

'''
s=s[:start]+new+s[end:]
cut=s.index("function ConnectionCard(")
cut2=s.index("function first(")
s=s[:cut]+s[cut2:]
s=s.replace('''import GeminiLogo from "@crm/ui/components/brand-logos/gemini";
import GoogleLogo from "@crm/ui/components/brand-logos/google";
import MetaLogo from "@crm/ui/components/brand-logos/meta";
import MicrosoftLogo from "@crm/ui/components/brand-logos/microsoft";
import SlackLogo from "@crm/ui/components/brand-logos/slack";
import TwilioLogo from "@crm/ui/components/brand-logos/twilio";
import { Button } from "@crm/ui/components/button";''','''import GoogleLogo from "@crm/ui/components/brand-logos/google";
import MicrosoftLogo from "@crm/ui/components/brand-logos/microsoft";
import SlackLogo from "@crm/ui/components/brand-logos/slack";
import { Button } from "@crm/ui/components/button";
import {
	type ConnectionItem,
	ConnectionList,
} from "@crm/ui/components/connection-list";''')
s=s.replace('''import { AddConnectionDialog } from "./add-connection-dialog";''','''import { AddConnectionDialog } from "./add-connection-dialog";
import { SdrConnectionsOverview } from "./sdr-connections-overview";''')
s=s.replace('export const metadata: Metadata = { title: "Connections" };','export const metadata: Metadata = { title: "Connexions" };')
open(p,"w").write(s)
EOF
sed -n 80,158p add-connection-dialog.tsx