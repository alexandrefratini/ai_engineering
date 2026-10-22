cd /home/user/endsi3g/fratex-agent/packages/ui/src/components && cat > calendar-connect-panel.tsx <<'EOF'
"use client";

import { type ReactNode, useState } from "react";
import { REVEAL, staggerStyle } from "../lib/motion";
import { formatDateTime } from "../lib/real-estate";
import { cn } from "../lib/utils";
import GoogleCalendarLogo from "./brand-logos/google-calendar";
import { Button } from "./button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./card";
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "./collapsible";
import { Field, FieldDescription, FieldLabel } from "./field";
import { WorkspaceNotice, WorkspaceSelect } from "./real-estate-workspace";
import { ToggleGroup, ToggleGroupItem } from "./toggle-group";

export type CalendarRealtor = { id: string; name: string; connected: boolean; timezone: string };

export type CalendarHours = {
	timezone: string;
	days: number[];
	startHour: number;
	endHour: number;
	slotDuration: number;
};

const DAYS = [
	{ id: 1, short: "Lun", name: "lundi" },
	{ id: 2, short: "Mar", name: "mardi" },
	{ id: 3, short: "Mer", name: "mercredi" },
	{ id: 4, short: "Jeu", name: "jeudi" },
	{ id: 5, short: "Ven", name: "vendredi" },
	{ id: 6, short: "Sam", name: "samedi" },
	{ id: 0, short: "Dim", name: "dimanche" },
];

const HOURS = Array.from({ length: 25 }, (_, hour) => ({ id: String(hour), name: `${hour} h` }));

const DURATIONS = [
	{ id: "30", name: "30 minutes" },
	{ id: "45", name: "45 minutes" },
	{ id: "60", name: "1 heure" },
	{ id: "90", name: "1 h 30" },
];

export function CalendarConnectPanel({
	realtors,
	selectedId,
	onSelect,
	oauthAvailable,
	canManage,
	onCreateLink,
	advanced,
}: {
	realtors: CalendarRealtor[];
	selectedId: string;
	onSelect: (id: string) => void;
	oauthAvailable: boolean;
	canManage: boolean;
	onCreateLink: (hours: CalendarHours) => Promise<{ url: string | null; expiresAt: string | null }>;
	advanced: ReactNode;
}) {
	const selected = realtors.find((realtor) => realtor.id === selectedId);
	const [days, setDays] = useState(["1", "2", "3", "4", "5"]);
	const [startHour, setStartHour] = useState("9");
	const [endHour, setEndHour] = useState("17");
	const [slot, setSlot] = useState("30");
	const [busy, setBusy] = useState<"open" | "copy" | null>(null);
	const [error, setError] = useState<string | null>(null);
	const [copied, setCopied] = useState<string | null>(null);
	const connected = realtors.filter((realtor) => realtor.connected).length;
	const invalidHours = Number(endHour) <= Number(startHour);

	async function request(mode: "open" | "copy") {
		if (!selected) return;
		setBusy(mode);
		setError(null);
		setCopied(null);
		try {
			const link = await onCreateLink({
				timezone: selected.timezone,
				days: days.map(Number),
				startHour: Number(startHour),
				endHour: Number(endHour),
				slotDuration: Number(slot),
			});
			if (!link.url) {
				setError("Google n'est pas configuré sur ce serveur.");
				return;
			}
			if (mode === "open") {
				window.location.assign(link.url);
				return;
			}
			await navigator.clipboard.writeText(link.url);
			setCopied(link.expiresAt);
		} catch (failure) {
			setError(failure instanceof Error ? failure.message : "Lien impossible à créer.");
		} finally {
			setBusy(null);
		}
	}

	return (
		<div className="flex flex-col gap-4">
			<Card className={REVEAL} style={staggerStyle(0)}>
				<CardHeader>
					<CardTitle>Courtiers</CardTitle>
					<CardDescription>
						{connected}/{realtors.length} agenda{realtors.length > 1 ? "s" : ""} connecté
						{connected > 1 ? "s" : ""}. Un clic choisit le courtier à connecter.
					</CardDescription>
				</CardHeader>
				<CardContent>
					<ul className="-my-1 flex flex-col divide-y">
						{realtors.map((realtor) => (
							<li key={realtor.id}>
								<button
									type="button"
									onClick={() => onSelect(realtor.id)}
									aria-pressed={realtor.id === selectedId}
									className={cn(
										"flex w-full items-center gap-3 rounded-md px-2 py-2 text-left text-sm transition-colors hover:bg-muted/60 focus-visible:outline-2 focus-visible:outline-ring",
										realtor.id === selectedId && "bg-muted",
									)}
								>
									<span className="min-w-0 flex-1 truncate font-medium">{realtor.name}</span>
									<span className="flex items-center gap-1.5 text-xs">
										<span
											aria-hidden="true"
											className={cn(
												"size-2 rounded-full",
												realtor.connected ? "bg-primary" : "bg-muted-foreground/40",
											)}
										/>
										<span className={cn(!realtor.connected && "text-muted-foreground")}>
											{realtor.connected ? "Agenda connecté" : "Non connecté"}
										</span>
									</span>
								</button>
							</li>
						))}
					</ul>
				</CardContent>
			</Card>

			{selected && (
				<Card className={REVEAL} style={staggerStyle(1)}>
					<CardHeader>
						<CardTitle className="flex items-center gap-2">
							<GoogleCalendarLogo className="size-5" />
							{selected.connected ? `Reconnecter l'agenda de ${selected.name}` : `Connecter l'agenda de ${selected.name}`}
						</CardTitle>
						<CardDescription>
							L'assistant ne propose que des créneaux libres dans ces heures, puis inscrit la visite dans Google
							Agenda. Fuseau : {selected.timezone}.
						</CardDescription>
					</CardHeader>
					<CardContent className="flex flex-col gap-4 @container">
						<div className="grid gap-4 @2xl:grid-cols-[auto_1fr_1fr_1fr]">
							<Field>
								<FieldLabel>Jours de visite</FieldLabel>
								<ToggleGroup
									type="multiple"
									variant="outline"
									size="sm"
									value={days}
									onValueChange={(value) => value.length > 0 && setDays(value)}
									aria-label="Jours de visite"
								>
									{DAYS.map((day) => (
										<ToggleGroupItem key={day.id} value={String(day.id)} aria-label={day.name}>
											{day.short}
										</ToggleGroupItem>
									))}
								</ToggleGroup>
							</Field>
							<WorkspaceSelect label="Début" value={startHour} options={HOURS.slice(0, 24)} onChange={setStartHour} />
							<WorkspaceSelect label="Fin" value={endHour} options={HOURS.slice(1)} onChange={setEndHour} />
							<WorkspaceSelect label="Durée d'une visite" value={slot} options={DURATIONS} onChange={setSlot} />
						</div>
						{invalidHours && <WorkspaceNotice title="L'heure de fin doit suivre l'heure de début." />}
						{!canManage ? (
							<WorkspaceNotice title="La connexion d'un agenda nécessite un rôle propriétaire ou administrateur." />
						) : oauthAvailable ? (
							<div className="flex flex-col gap-2">
								<div className="flex flex-wrap gap-2">
									<Button disabled={busy !== null || invalidHours} onClick={() => void request("open")}>
										{busy === "open" ? "Ouverture de Google…" : "Connecter Google Agenda"}
									</Button>
									<Button
										variant="outline"
										disabled={busy !== null || invalidHours}
										onClick={() => void request("copy")}
									>
										{busy === "copy" ? "Création du lien…" : "Copier le lien pour le courtier"}
									</Button>
								</div>
								<FieldDescription>
									Vous n'avez pas accès à son compte Google ? Envoyez-lui le lien par SMS ou courriel : il
									accepte l'accès en un clic, sans créer de compte Fratex.
								</FieldDescription>
								{copied && (
									<WorkspaceNotice
										title={`Lien copié. Valide jusqu'au ${formatDateTime(copied)}.`}
									/>
								)}
							</div>
						) : (
							<WorkspaceNotice title="Connexion Google indisponible : le serveur n'a pas GOOGLE_CLIENT_ID et GOOGLE_CLIENT_SECRET. Utilisez la saisie avancée ci-dessous, ou demandez à l'équipe technique d'ajouter ces clés." />
						)}
						{error && <WorkspaceNotice title="Connexion impossible" error={error} />}
					</CardContent>
				</Card>
			)}

			<Collapsible defaultOpen={!oauthAvailable} className={cn("rounded-lg border bg-card", REVEAL)} style={staggerStyle(2)}>
				<CollapsibleTrigger className="flex w-full items-center justify-between gap-2 px-4 py-3 text-left text-sm font-medium outline-none focus-visible:ring-2 focus-visible:ring-ring">
					Saisie avancée des jetons OAuth
					<span className="text-xs font-normal text-muted-foreground">Pour l'équipe technique</span>
				</CollapsibleTrigger>
				<CollapsibleContent className="border-t p-4">{advanced}</CollapsibleContent>
			</Collapsible>
		</div>
	);
}
EOF
echo ok