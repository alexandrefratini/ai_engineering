cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/lib/real-estate.ts"
s=open(p).read()
s=s.replace('''export const APPOINTMENT_STATUS_LABELS: Record<string, string> = {''','''export const LEAD_SOURCE_OPTIONS = [
	{ id: "REFERRAL", name: "Référence" },
	{ id: "INBOUND_CALL", name: "Appel entrant" },
	{ id: "WEBSITE", name: "Site web" },
	{ id: "SIGN", name: "Pancarte" },
	{ id: "OPEN_HOUSE", name: "Visite libre" },
	{ id: "SOCIAL", name: "Réseaux sociaux" },
	{ id: "OTHER", name: "Autre" },
] as const;

export const LEAD_SOURCE_LABELS: Record<string, string> = Object.fromEntries(
	LEAD_SOURCE_OPTIONS.map((option) => [option.id, option.name]),
);

export function consentSourceLabel(source: string | null): string | null {
	if (!source) return null;
	if (source.startsWith("manual:")) return "confirmé à l'équipe";
	if (source.startsWith("meta:")) return "case cochée dans le formulaire Meta";
	if (source.startsWith("sms:")) return "réponse par SMS";
	return source;
}

export const APPOINTMENT_STATUS_LABELS: Record<string, string> = {''',1)
open(p,"w").write(s)

p="packages/ui/src/components/lead-profile.tsx"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:70]
    s=s.replace(a,b,1)
rep('''	campaignName: string | null;
	formName: string | null;
	property: {''','''	campaignName: string | null;
	formName: string | null;
	source: string | null;
	property: {''')
rep('''export type LeadProfileAppointment = {
	id: string;
	title: string;
	startTime: string;
	status: string;
	clientName: string;
};''','''export type LeadProfileAppointment = {
	id: string;
	title: string;
	startTime: string;
	status: string;
	clientName: string;
	description?: string | null;
};

export type AppointmentOutcome = "CONFIRMED" | "COMPLETED" | "NO_SHOW" | "CANCELLED";

export type NewAppointment = {
	title: string;
	startTime: string;
	durationMinutes: number;
	location?: string;
};''')
start=s.index("export function LeadAppointments({")
end=s.index("export function LeadSuggestedListings({")
s=s[:start]+'''const OUTCOME_DOT: Record<string, string> = {
	SCHEDULED: "bg-primary/50",
	CONFIRMED: "bg-primary",
	RESCHEDULED: "bg-primary/50",
	COMPLETED: "bg-foreground",
	NO_SHOW: "bg-muted-foreground/40",
	CANCELLED: "bg-muted-foreground/40",
};

const DURATIONS = [
	{ id: "30", name: "30 min" },
	{ id: "45", name: "45 min" },
	{ id: "60", name: "1 h" },
	{ id: "90", name: "1 h 30" },
	{ id: "120", name: "2 h" },
];

function AppointmentForm({
	onCreate,
	onDone,
}: {
	onCreate: (appointment: NewAppointment) => Promise<void>;
	onDone: () => void;
}) {
	const [duration, setDuration] = useState("60");
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState<string | null>(null);
	async function submit(form: HTMLFormElement) {
		const data = new FormData(form);
		const value = (key: string) => String(data.get(key) ?? "").trim();
		const start = new Date(`${value("date")}T${value("time")}`);
		if (Number.isNaN(start.getTime())) {
			setError("Choisissez une date et une heure.");
			return;
		}
		setBusy(true);
		setError(null);
		try {
			await onCreate({
				title: value("title") || "Visite",
				startTime: start.toISOString(),
				durationMinutes: Number(duration),
				location: value("location") || undefined,
			});
			onDone();
		} catch (failure) {
			setError(failure instanceof Error ? failure.message : "Rendez-vous non enregistré.");
		} finally {
			setBusy(false);
		}
	}
	return (
		<form
			className="flex flex-col gap-3 rounded-md border bg-muted/30 p-3"
			onSubmit={(event) => {
				event.preventDefault();
				void submit(event.currentTarget);
			}}
		>
			<div className="grid gap-3 sm:grid-cols-[1fr_auto_auto_auto]">
				<Field>
					<FieldLabel htmlFor="appointment-title">Objet</FieldLabel>
					<Input id="appointment-title" name="title" placeholder="Visite" />
				</Field>
				<Field>
					<FieldLabel htmlFor="appointment-date">Date</FieldLabel>
					<Input id="appointment-date" name="date" type="date" required />
				</Field>
				<Field>
					<FieldLabel htmlFor="appointment-time">Heure</FieldLabel>
					<Input id="appointment-time" name="time" type="time" step={900} required />
				</Field>
				<WorkspaceSelect label="Durée" value={duration} options={DURATIONS} onChange={setDuration} />
			</div>
			<Field>
				<FieldLabel htmlFor="appointment-location">
					Lieu <span className="font-normal text-muted-foreground">(facultatif)</span>
				</FieldLabel>
				<Input id="appointment-location" name="location" placeholder="Adresse de la propriété ou lien de visioconférence" />
			</Field>
			{error && <WorkspaceNotice title="Rendez-vous non enregistré" error={error} />}
			<div className="flex justify-end gap-2">
				<Button type="button" variant="ghost" size="sm" onClick={onDone}>
					Annuler
				</Button>
				<Button size="sm" disabled={busy}>
					{busy ? "Enregistrement…" : "Enregistrer le rendez-vous"}
				</Button>
			</div>
		</form>
	);
}

export function LeadAppointments({
	appointments,
	index,
	canWrite = false,
	onCreate,
	onOutcome,
}: {
	appointments: LeadProfileAppointment[];
	index?: number;
	canWrite?: boolean;
	onCreate?: (appointment: NewAppointment) => Promise<void>;
	onOutcome?: (id: string, status: AppointmentOutcome) => void;
}) {
	const [adding, setAdding] = useState(false);
	const now = Date.now();
	return (
		<LeadPanel
			index={index}
			title="Rendez-vous"
			description="Rendez-vous réservés par l'assistant ou ajoutés par l'équipe. Indiquez l'issue après la visite : elle met à jour le pipeline et les conversions Meta."
			action={
				canWrite && onCreate && !adding ? (
					<Button variant="outline" size="sm" onClick={() => setAdding(true)}>
						Ajouter
					</Button>
				) : undefined
			}
		>
			<div className="flex flex-col gap-3">
				{adding && onCreate && <AppointmentForm onCreate={onCreate} onDone={() => setAdding(false)} />}
				{appointments.length === 0 ? (
					!adding && <Muted>Aucun rendez-vous planifié.</Muted>
				) : (
					<ul className="flex flex-col divide-y text-sm">
						{appointments.map((appointment) => {
							const active = UPCOMING_STATUSES.has(appointment.status);
							const past = new Date(appointment.startTime).getTime() < now;
							return (
								<li
									key={appointment.id}
									className="flex flex-wrap items-center justify-between gap-2 py-2 first:pt-0 last:pb-0"
								>
									<span className="flex min-w-0 flex-col">
										<span className="font-medium">{formatDateTime(appointment.startTime)}</span>
										<span className="truncate text-muted-foreground">
											{[appointment.title, appointment.clientName, appointment.description]
												.filter(Boolean)
												.join(" · ")}
										</span>
									</span>
									<span className="flex flex-wrap items-center gap-2">
										<span className="flex items-center gap-1.5 text-xs">
											<span
												aria-hidden="true"
												className={cn("size-2 rounded-full", OUTCOME_DOT[appointment.status] ?? "bg-muted-foreground/40")}
											/>
											{labelOf(APPOINTMENT_STATUS_LABELS, appointment.status)}
										</span>
										{canWrite && onOutcome && active && (
											<span className="flex gap-1">
												{past ? (
													<>
														<Button size="sm" variant="outline" onClick={() => onOutcome(appointment.id, "COMPLETED")}>
															Réalisé
														</Button>
														<Button size="sm" variant="ghost" onClick={() => onOutcome(appointment.id, "NO_SHOW")}>
															Absent
														</Button>
													</>
												) : (
													<>
														{appointment.status === "SCHEDULED" && (
															<Button
																size="sm"
																variant="outline"
																onClick={() => onOutcome(appointment.id, "CONFIRMED")}
															>
																Confirmer
															</Button>
														)}
														<Button size="sm" variant="ghost" onClick={() => onOutcome(appointment.id, "CANCELLED")}>
															Annuler
														</Button>
													</>
												)}
											</span>
										)}
									</span>
								</li>
							);
						})}
					</ul>
				)}
			</div>
		</LeadPanel>
	);
}

'''+s[end:]
rep('''						{
							label: "Source",
							value: [lead.campaignName, lead.formName].filter(Boolean).join(" · ") || (
								<Muted>Non renseignée</Muted>
							),
						},''','''						{
							label: "Source",
							value: [lead.campaignName, lead.formName, lead.source ? labelOf(LEAD_SOURCE_LABELS, lead.source) : null]
								.filter(Boolean)
								.join(" · ") || <Muted>Non renseignée</Muted>,
						},''')
rep('''								`Consentement du ${formatDateTime(lead.consentedAt)}${lead.consentSource ? ` · ${lead.consentSource}` : ""}`''','''								`Consentement du ${formatDateTime(lead.consentedAt)}${consentSourceLabel(lead.consentSource) ? ` · ${consentSourceLabel(lead.consentSource)}` : ""}`''')
rep('''import type { ReactNode } from "react";''','''import { type ReactNode, useState } from "react";''')
rep('''	ESCALATION_LABELS,
	EVENT_LABELS,''','''	consentSourceLabel,
	ESCALATION_LABELS,
	EVENT_LABELS,''')
rep('''	LANGUAGE_LABELS,
	LEAD_JOURNEY,''','''	LANGUAGE_LABELS,
	LEAD_JOURNEY,
	LEAD_SOURCE_LABELS,''')
rep('''import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "./collapsible";''','''import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "./collapsible";
import { Field, FieldLabel } from "./field";
import { Input } from "./input";''')
rep('''import { LeadJourney, MetricGrid, MetricTile, ScoreRing, SegmentMeter } from "./real-estate-visuals";''','''import { LeadJourney, MetricGrid, MetricTile, ScoreRing, SegmentMeter } from "./real-estate-visuals";
import { WorkspaceNotice, WorkspaceSelect } from "./real-estate-workspace";''')
open(p,"w").write(s)
EOF
cd packages/ui && bunx tsc --noEmit 2>&1 | tail -8; echo ui $?