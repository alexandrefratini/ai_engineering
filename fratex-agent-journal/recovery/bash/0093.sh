cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/settings/connections" && cat > sdr-connections-overview.tsx <<'EOF'
"use client";

import GeminiLogo from "@crm/ui/components/brand-logos/gemini";
import GoogleCalendarLogo from "@crm/ui/components/brand-logos/google-calendar";
import MetaLogo from "@crm/ui/components/brand-logos/meta";
import TwilioLogo from "@crm/ui/components/brand-logos/twilio";
import { Button } from "@crm/ui/components/button";
import {
	type ConnectionItem,
	ConnectionList,
} from "@crm/ui/components/connection-list";
import {
	WorkspaceLoading,
	WorkspaceNotice,
} from "@crm/ui/components/real-estate-workspace";
import { formatPhone } from "@crm/ui/lib/real-estate";
import Link from "next/link";
import { AgencyControl } from "../../real-estate/use-agency";
import { useSdrConnections } from "./use-sdr-connections";

function plural(count: number, word: string) {
	return `${count} ${word}${count > 1 ? "s" : ""}`;
}

export function SdrConnectionsOverview({ slug }: { slug: string }) {
	const { scope, query } = useSdrConnections();
	if (!scope.agencyId) return <AgencyControl scope={scope} />;
	if (query.isPending) return <WorkspaceLoading />;
	if (query.error)
		return (
			<WorkspaceNotice
				title="État des connexions indisponible"
				error={query.error.message}
				onRetry={() => {
					void query.refetch();
				}}
			/>
		);
	const status = query.data;
	const href = (path: string) =>
		`/${slug}/settings/connections/${path}?agencyId=${status.agencyId}`;
	const manage = (path: string, ready: boolean) => (
		<Button asChild size="sm" variant={ready ? "outline" : "default"}>
			<Link href={href(path)}>{ready ? "Gérer" : "Configurer"}</Link>
		</Button>
	);
	const calendar = status.calendar;
	const items: ConnectionItem[] = [
		{
			id: "meta",
			name: "Meta Lead Ads",
			purpose: "Reçoit les prospects des formulaires Facebook et Instagram.",
			logo: MetaLogo,
			state: status.meta.connected
				? status.meta.webhookActive
					? "ready"
					: "pending"
				: "missing",
			status: status.meta.connected
				? status.meta.webhookActive
					? "Reçoit des prospects"
					: "En attente du 1er prospect"
				: "À relier",
			explanation: status.meta.connected
				? status.meta.webhookActive
					? "Meta a déjà envoyé au moins un prospect signé à cette agence."
					: "Le compte est relié, mais aucun prospect n'est encore arrivé. Vérifiez que l'application Meta est abonnée au formulaire."
				: "Aucun compte publicitaire relié : les prospects des publicités n'arrivent pas dans Fratex.",
			detail: status.meta.connected
				? `${plural(status.meta.formCount, "formulaire")}${status.meta.capiEnabled ? " · CAPI" : ""}`
				: undefined,
			action: manage("meta-ads", status.meta.connected),
		},
		{
			id: "sms",
			name: "SMS Twilio",
			purpose: "Envoie le premier SMS en moins de 2 minutes et reçoit les réponses.",
			logo: TwilioLogo,
			state: status.twilio.connected ? "ready" : "missing",
			status: status.twilio.connected ? "Numéro actif" : "À configurer",
			explanation: status.twilio.connected
				? "Le numéro Twilio de l'agence envoie et reçoit les SMS. Les accusés de livraison confirment chaque envoi."
				: "Sans numéro SMS, l'assistant ne peut pas contacter les prospects.",
			detail: status.twilio.phoneNumber
				? formatPhone(status.twilio.phoneNumber)
				: undefined,
			action: manage("twilio", status.twilio.connected),
		},
		{
			id: "ai",
			name: "Assistant IA",
			purpose: "Qualifie le prospect par SMS et propose un rendez-vous.",
			logo: GeminiLogo,
			state: status.ai.configured ? "ready" : "missing",
			status: status.ai.configured ? "Prêt" : "Clé manquante",
			explanation: status.ai.configured
				? `Fournisseur ${status.ai.provider}, modèle ${status.ai.model}.`
				: "Le serveur n'a pas de clé pour le modèle d'IA. L'équipe technique doit l'ajouter dans les variables d'environnement.",
			detail: status.ai.configured ? status.ai.model : undefined,
			action: manage("gemini", status.ai.configured),
		},
		{
			id: "calendar",
			name: "Google Agenda des courtiers",
			purpose: "Disponibilités réelles et réservation des visites.",
			logo: GoogleCalendarLogo,
			state:
				calendar.total > 0 && calendar.connected === calendar.total
					? "ready"
					: calendar.connected > 0
						? "partial"
						: "missing",
			status:
				calendar.total === 0
					? "Aucun courtier"
					: calendar.connected === calendar.total
						? "Tous connectés"
						: `${calendar.total - calendar.connected} à connecter`,
			explanation:
				calendar.total === 0
					? "Ajoutez d'abord un courtier, puis connectez son agenda."
					: "Chaque courtier connecte son propre Google Agenda. Sans agenda, l'assistant ne peut pas réserver de rendez-vous pour lui.",
			detail:
				calendar.total > 0
					? `${calendar.connected}/${plural(calendar.total, "courtier")}`
					: undefined,
			action: manage(
				"realtor-calendar",
				calendar.total > 0 && calendar.connected === calendar.total,
			),
		},
	];
	return (
		<>
			<AgencyControl scope={scope} />
			<ConnectionList
				index={0}
				progress
				title="Chaîne de prospection"
				description="Les quatre maillons qui transforment une publicité en rendez-vous. Tant qu'un maillon manque, l'assistant ne peut pas travailler seul."
				items={items}
			/>
		</>
	);
}
EOF
echo ok