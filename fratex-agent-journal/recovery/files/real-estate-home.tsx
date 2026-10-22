"use client";

import type { ReactNode } from "react";
import { REVEAL, staggerStyle } from "../lib/motion";
import {
	APPOINTMENT_STATUS_LABELS,
	ESCALATION_LABELS,
	formatDateTime,
	formatDuration,
	formatPhone,
	labelOf,
} from "../lib/real-estate";
import { cn } from "../lib/utils";
import { Button } from "./button";
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from "./card";
import { LEAD_STATUS_OPTIONS } from "./lead-status-badge";
import { MetricGrid, MetricTile, Sparkline, type StageGroup, StageBreakdown } from "./real-estate-visuals";

export type HomeToDo = {
	leadId: string;
	name: string;
	phone: string;
	reason: "UNREAD" | "HUMAN" | "NOT_CONTACTED";
	detail: string | null;
	at: string;
};

export type RealEstateHomeData = {
	today: { newLeads: number; appointments: number };
	week: {
		newLeads: number;
		qualified: number;
		appointments: number;
		medianResponseMinutes: number | null;
	};
	toDo: HomeToDo[];
	appointments: { id: string; leadId: string; leadName: string; startTime: string; status: string }[];
	stages: { status: string; count: number }[];
	trend: { day: string; count: number }[];
};

const REASONS: Record<HomeToDo["reason"], { label: string; dot: string }> = {
	UNREAD: { label: "Message non lu", dot: "bg-primary" },
	HUMAN: { label: "Reprise humaine", dot: "bg-foreground" },
	NOT_CONTACTED: { label: "Jamais contacté", dot: "bg-muted-foreground/50" },
};

const STATUS_LABEL = new Map<string, string>(LEAD_STATUS_OPTIONS.map((option) => [option.id, option.name]));

const GROUPS: (Omit<StageGroup, "stages"> & { statuses: string[] })[] = [
	{
		id: "progress",
		label: "En cours",
		description: "Reçus, contactés ou en train de répondre aux questions de l'assistant.",
		tone: "progress",
		statuses: ["NEW", "CONTACTED", "QUALIFYING"],
	},
	{
		id: "won",
		label: "Qualifiés",
		description: "Projet confirmé par le prospect, avec ou sans rendez-vous.",
		tone: "won",
		statuses: ["QUALIFIED", "APPOINTMENT_BOOKED", "APPOINTMENT_HELD"],
	},
	{
		id: "out",
		label: "Sortis du parcours",
		description: "À relancer plus tard, non intéressés ou coordonnées invalides.",
		tone: "out",
		statuses: ["NURTURE", "LOST", "INVALID"],
	},
];

function Panel({
	title,
	description,
	action,
	index,
	children,
}: {
	title: string;
	description: string;
	action?: ReactNode;
	index: number;
	children: ReactNode;
}) {
	return (
		<Card className={REVEAL} style={staggerStyle(index)}>
			<CardHeader>
				<CardTitle>{title}</CardTitle>
				<CardDescription>{description}</CardDescription>
				{action && <CardAction>{action}</CardAction>}
			</CardHeader>
			<CardContent>{children}</CardContent>
		</Card>
	);
}

function Empty({ children }: { children: ReactNode }) {
	return <span className="text-sm text-muted-foreground">{children}</span>;
}

export function RealEstateHome({
	data,
	onOpenLead,
	onOpenStage,
	inboxLink,
	pipelineLink,
}: {
	data: RealEstateHomeData;
	onOpenLead: (leadId: string) => void;
	onOpenStage: (status: string) => void;
	inboxLink: ReactNode;
	pipelineLink: ReactNode;
}) {
	const counts = new Map(data.stages.map((stage) => [stage.status, stage.count]));
	const groups: StageGroup[] = GROUPS.map(({ statuses, ...group }) => ({
		...group,
		stages: statuses.map((status) => ({
			id: status,
			label: STATUS_LABEL.get(status) ?? status,
			count: counts.get(status) ?? 0,
		})),
	}));
	return (
		<div className="flex flex-col gap-4">
			<MetricGrid>
				<MetricTile
					index={0}
					label="Nouveaux prospects aujourd'hui"
					value={data.today.newLeads}
					hint={`${data.week.newLeads} sur les 7 derniers jours`}
					info="Prospects créés aujourd'hui (fuseau de Montréal), par un formulaire Meta ou une saisie. La courbe montre les 14 derniers jours."
				>
					<Sparkline values={data.trend.map((day) => day.count)} label="Prospects reçus sur 14 jours" />
				</MetricTile>
				<MetricTile
					index={1}
					label="À traiter"
					value={data.toDo.length}
					hint="Attendent une action de votre part"
					info="Nombre de prospects listés dans « À faire maintenant » : message non lu, reprise humaine en cours ou prospect jamais contacté."
				/>
				<MetricTile
					index={2}
					label="Rendez-vous aujourd'hui"
					value={data.today.appointments}
					hint={`${data.appointments.length} dans les 48 prochaines heures`}
					info="Rendez-vous planifiés, confirmés ou reportés qui commencent aujourd'hui. Les rendez-vous annulés ou passés ne sont pas comptés."
				/>
				<MetricTile
					index={3}
					label="Première réponse (7 jours)"
					value={data.week.medianResponseMinutes === null ? "—" : formatDuration(data.week.medianResponseMinutes)}
					hint={`${data.week.qualified} qualifiés · ${data.week.appointments} avec rendez-vous`}
					info="Délai médian entre l'arrivée d'un prospect et le premier SMS envoyé, sur les prospects reçus ces 7 derniers jours. La moitié des prospects ont été contactés plus vite que ce délai."
				/>
			</MetricGrid>

			<Panel
				index={4}
				title="À faire maintenant"
				description="Prospects qui attendent une action : un message non lu, une reprise humaine ou un premier contact jamais fait. Du plus récent au plus ancien. Un clic ouvre la fiche."
				action={inboxLink}
			>
				{data.toDo.length === 0 ? (
					<Empty>Rien d'urgent. L'assistant IA s'occupe du reste.</Empty>
				) : (
					<ul className="-my-1 flex flex-col divide-y">
						{data.toDo.map((item, index) => (
							<li key={item.leadId} className={cn("flex items-center gap-2", REVEAL)} style={staggerStyle(index)}>
								<button
									type="button"
									onClick={() => onOpenLead(item.leadId)}
									className="flex min-w-0 flex-1 items-center gap-3 rounded-md py-2 pr-2 text-left text-sm transition-colors hover:bg-muted/60 focus-visible:outline-2 focus-visible:outline-ring"
								>
									<span aria-hidden="true" className={cn("ml-1 size-2 shrink-0 rounded-full", REASONS[item.reason].dot)} />
									<span className="flex min-w-0 flex-1 flex-col">
										<span className="flex items-baseline gap-2">
											<span className="truncate font-medium">{item.name}</span>
											<span className="shrink-0 text-xs text-muted-foreground">{REASONS[item.reason].label}</span>
										</span>
										{item.detail && (
											<span className="truncate text-xs text-muted-foreground">
												{labelOf(ESCALATION_LABELS, item.detail)}
											</span>
										)}
									</span>
									<span className="hidden shrink-0 text-xs text-muted-foreground tabular-nums sm:inline">
										{formatDateTime(item.at)}
									</span>
								</button>
								<Button asChild variant="ghost" size="sm">
									<a href={`tel:${item.phone}`} aria-label={`Appeler ${item.name} au ${formatPhone(item.phone)}`}>
										Appeler
									</a>
								</Button>
							</li>
						))}
					</ul>
				)}
			</Panel>

			<Panel
				index={5}
				title="Rendez-vous des 48 prochaines heures"
				description="Rendez-vous planifiés, confirmés ou reportés dans les deux prochains jours. Un clic ouvre la fiche du prospect."
			>
				{data.appointments.length === 0 ? (
					<Empty>Aucun rendez-vous dans les 48 prochaines heures.</Empty>
				) : (
					<ul className="-my-1 flex flex-col divide-y">
						{data.appointments.map((item) => (
							<li key={item.id}>
								<button
									type="button"
									onClick={() => onOpenLead(item.leadId)}
									className="flex w-full items-center gap-3 rounded-md px-1 py-2 text-left text-sm transition-colors hover:bg-muted/60 focus-visible:outline-2 focus-visible:outline-ring"
								>
									<span className="w-40 shrink-0 font-medium tabular-nums">{formatDateTime(item.startTime)}</span>
									<span className="min-w-0 flex-1 truncate">{item.leadName}</span>
									<span className="shrink-0 text-xs text-muted-foreground">
										{labelOf(APPOINTMENT_STATUS_LABELS, item.status)}
									</span>
								</button>
							</li>
						))}
					</ul>
				)}
			</Panel>

			<Panel
				index={6}
				title="Pipeline"
				description="Répartition de tous vos prospects par étape. La barre est proportionnelle au total : une étape vide ne prend aucune place. Un clic sur une étape ouvre la liste filtrée."
				action={pipelineLink}
			>
				<StageBreakdown groups={groups} onSelect={onOpenStage} />
			</Panel>
		</div>
	);
}
