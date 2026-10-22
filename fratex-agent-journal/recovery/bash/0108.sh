mkdir -p "/home/user/endsi3g/fratex-agent/apps/app/app/(landing)/agenda-connecte" && cd "/home/user/endsi3g/fratex-agent/apps/app/app/(landing)/agenda-connecte" && cat > page.tsx <<'EOF'
import GoogleCalendarLogo from "@crm/ui/components/brand-logos/google-calendar";
import {
	Card,
	CardDescription,
	CardHeader,
	CardTitle,
} from "@crm/ui/components/card";
import type { Metadata } from "next";
import { Suspense } from "react";

export const metadata: Metadata = {
	title: "Google Agenda — Fratex Agent",
};

const RESULTS: Record<string, { title: string; description: string }> = {
	ok: {
		title: "Votre agenda est connecté",
		description:
			"L'assistant Fratex propose maintenant vos vraies disponibilités aux prospects et inscrit les visites dans votre Google Agenda. Vous pouvez fermer cette page.",
	},
	refused: {
		title: "Accès refusé",
		description:
			"Vous avez refusé l'accès dans Google. Rien n'a été enregistré. Rouvrez le lien reçu pour recommencer.",
	},
	expired: {
		title: "Lien expiré",
		description:
			"Ce lien n'est plus valide : il expire après 7 jours. Demandez un nouveau lien à votre agence.",
	},
	scope: {
		title: "Autorisation incomplète",
		description:
			"Google n'a pas accordé les deux accès à l'agenda (disponibilités et création d'événements). Rouvrez le lien et cochez les deux cases.",
	},
	google: {
		title: "Google n'a pas répondu",
		description:
			"La connexion n'a pas pu être finalisée. Réessayez dans quelques minutes avec le même lien.",
	},
};

const FALLBACK = {
	title: "Connexion impossible",
	description:
		"La connexion n'a pas pu être enregistrée. Contactez votre agence : elle peut vous envoyer un nouveau lien.",
};

export default function CalendarConnectedPage(
	props: PageProps<"/agenda-connecte">,
) {
	return (
		<div className="flex min-h-screen items-center justify-center bg-background px-4 py-10">
			<div className="w-full max-w-md">
				<Suspense fallback={null}>
					<CalendarResult {...props} />
				</Suspense>
			</div>
		</div>
	);
}

async function CalendarResult({
	searchParams,
}: PageProps<"/agenda-connecte">) {
	const { statut } = await searchParams;
	const result =
		RESULTS[Array.isArray(statut) ? (statut[0] ?? "") : (statut ?? "")] ??
		FALLBACK;
	return (
		<Card>
			<CardHeader>
				<GoogleCalendarLogo className="mb-2 size-8" />
				<CardTitle>{result.title}</CardTitle>
				<CardDescription>{result.description}</CardDescription>
			</CardHeader>
		</Card>
	);
}
EOF
cd /home/user/endsi3g/fratex-agent && sed -i 's/const ANONYMOUS = \["\/t"\];/const ANONYMOUS = ["\/t", "\/agenda-connecte"];/' apps/app/proxy.ts && grep -n "ANONYMOUS =" apps/app/proxy.ts && bunx biome check --write "apps/app/app/(landing)/agenda-connecte" apps/app/proxy.ts 2>&1 | tail -1; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -5; echo app $?); grep -n "ANONYMOUS\|/t\b" apps/app/test/onboarding-gate.spec.ts | head -5