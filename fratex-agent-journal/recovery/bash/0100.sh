cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/settings/connections" && cat > realtor-calendar/realtor-calendar-connection.tsx <<'EOF'
"use client";
import { CalendarConnectPanel } from "@crm/ui/components/calendar-connect-panel";
import { ConnectionSetup } from "@crm/ui/components/connection-setup";
import {
	RealEstateWorkspace,
	WorkspaceLoading,
	WorkspaceNotice,
} from "@crm/ui/components/real-estate-workspace";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { parseAsString, useQueryState } from "nuqs";
import { useTRPC } from "@/lib/trpc/client";
import { AgencyControl } from "../../../real-estate/use-agency";
import { useSdrConnections } from "../use-sdr-connections";

export function RealtorCalendarConnection() {
	const trpc = useTRPC();
	const cache = useQueryClient();
	const { scope, query, clients } = useSdrConnections();
	const [chosen, setChosen] = useQueryState("client", parseAsString);
	const link = useMutation(trpc.realEstate.calendarConnectLink.mutationOptions());
	const manual = useMutation(
		trpc.realEstate.configureCalendar.mutationOptions(),
	);
	const realtors = (clients.data?.clients ?? []).map((client) => ({
		id: client.id,
		name: client.name,
		connected: client.setup.calendar,
		timezone: client.timezone,
	}));
	const clientId = realtors.some((realtor) => realtor.id === chosen)
		? (chosen ?? "")
		: (realtors.find((realtor) => !realtor.connected)?.id ??
			realtors[0]?.id ??
			"");

	return (
		<RealEstateWorkspace>
			<AgencyControl scope={scope} />
			{scope.agencyId &&
				(query.isPending || clients.isPending ? (
					<WorkspaceLoading />
				) : query.error || clients.error ? (
					<WorkspaceNotice
						title="Configuration indisponible"
						error={(query.error ?? clients.error)?.message}
					/>
				) : realtors.length === 0 ? (
					<WorkspaceNotice title="Ajoutez d'abord un courtier : chaque agenda appartient à un courtier." />
				) : (
					<CalendarConnectPanel
						realtors={realtors}
						selectedId={clientId}
						onSelect={(id) => {
							void setChosen(id);
						}}
						oauthAvailable={query.data.calendar.oauthAvailable}
						canManage={query.data.canManage}
						onCreateLink={(hours) =>
							link.mutateAsync({ agencyId: scope.agencyId, clientId, ...hours })
						}
						advanced={
							<ConnectionSetup
								title="Jetons Google fournis par l'équipe technique"
								description="Pour une intégration existante seulement. Le bouton « Connecter Google Agenda » remplit ces valeurs automatiquement."
								enabled={query.data.canManage}
								fields={[
									{
										name: "calendarId",
										label: "Identifiant de l'agenda",
										defaultValue: "primary",
									},
									{
										name: "accessToken",
										label: "Jeton d'accès OAuth",
										type: "password",
									},
									{
										name: "refreshToken",
										label: "Jeton de renouvellement OAuth",
										type: "password",
									},
									{
										name: "tokenExpiry",
										label: "Expiration ISO, par exemple 2026-12-01T12:00:00Z",
									},
									{
										name: "timezone",
										label: "Fuseau horaire",
										defaultValue: "America/Toronto",
									},
									{
										name: "days",
										label: "Jours : 0 dimanche, 1 lundi, jusqu'à 6 samedi",
										defaultValue: "1,2,3,4,5",
									},
									{
										name: "startHour",
										label: "Heure de début",
										type: "number",
										defaultValue: "9",
									},
									{
										name: "endHour",
										label: "Heure de fin",
										type: "number",
										defaultValue: "17",
									},
									{
										name: "slotDuration",
										label: "Durée en minutes",
										type: "number",
										defaultValue: "30",
									},
								]}
								onSubmit={async (data) => {
									await manual.mutateAsync({
										agencyId: scope.agencyId,
										clientId,
										calendarId: String(data.get("calendarId")),
										accessToken: String(data.get("accessToken")),
										refreshToken: String(data.get("refreshToken")),
										tokenExpiry: String(data.get("tokenExpiry")),
										timezone: String(data.get("timezone")),
										days: String(data.get("days")).split(",").map(Number),
										startHour: Number(data.get("startHour")),
										endHour: Number(data.get("endHour")),
										slotDuration: Number(data.get("slotDuration")),
									});
									await cache.invalidateQueries(
										trpc.realEstate.pathFilter(),
									);
								}}
							/>
						}
					/>
				))}
		</RealEstateWorkspace>
	);
}
EOF
cat > realtor-calendar/page.tsx <<'EOF'
import type { Metadata } from "next";
import { Suspense } from "react";
import { requireSession } from "@/lib/session";
import { ConnectionPage, ConnectionPageLoading } from "../connection-page";
import { ConnectionHeader } from "../connection-header";
import { RealtorCalendarConnection } from "./realtor-calendar-connection";

export const metadata: Metadata = { title: "Google Agenda des courtiers" };

export default function RealtorCalendarPage(
	props: PageProps<"/[slug]/settings/connections/realtor-calendar">,
) {
	return (
		<Suspense fallback={<ConnectionPageLoading />}>
			<RealtorCalendarPageContent {...props} />
		</Suspense>
	);
}

async function RealtorCalendarPageContent({
	params,
}: PageProps<"/[slug]/settings/connections/realtor-calendar">) {
	await requireSession();
	const { slug } = await params;

	return (
		<ConnectionPage className="gap-4">
			<ConnectionHeader
				slug={slug}
				title="Google Agenda des courtiers"
				description="Chaque courtier relie son propre agenda. L'assistant y lit les disponibilités et y inscrit les visites réservées."
			/>
			<RealtorCalendarConnection />
		</ConnectionPage>
	);
}
EOF
cat > connection-header.tsx <<'EOF'
import { Button } from "@crm/ui/components/button";
import Link from "next/link";

export function ConnectionHeader({
	slug,
	title,
	description,
}: {
	slug: string;
	title: string;
	description: string;
}) {
	return (
		<header className="flex flex-col gap-1">
			<Button asChild variant="link" size="sm" className="h-auto self-start p-0">
				<Link href={`/${slug}/settings/connections`}>← Connexions</Link>
			</Button>
			<h1 className="font-medium text-2xl tracking-tight">{title}</h1>
			<p className="max-w-2xl text-muted-foreground text-sm">{description}</p>
		</header>
	);
}
EOF
grep -n "instant" realtor-calendar/*.tsx ../../real-estate/portal/page.tsx 2>/dev/null | head