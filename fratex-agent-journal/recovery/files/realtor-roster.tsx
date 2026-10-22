"use client";

import type { ReactNode } from "react";
import { initialsFromName } from "../lib/format";
import { REVEAL, staggerStyle } from "../lib/motion";
import { formatDateTime, formatPhone } from "../lib/real-estate";
import { cn } from "../lib/utils";
import { Avatar, AvatarFallback } from "./avatar";
import { Tooltip, TooltipContent, TooltipTrigger } from "./tooltip";

export type RosterRealtor = {
	id: string;
	name: string;
	email: string;
	phone: string | null;
	status: "ACTIVE" | "PAUSED" | "CHURNED";
	brokerage: string | null;
	targetZones: string[];
	leadsCount: number;
	appointmentsCount: number;
	lastLeadAt: string | null;
	setup: { metaForm: boolean; calendar: boolean; sms: boolean };
};

const SETUP_STEPS: { key: keyof RosterRealtor["setup"]; label: string; done: string; missing: string }[] = [
	{
		key: "metaForm",
		label: "Meta",
		done: "Un formulaire Meta Lead Ads envoie ses prospects à ce courtier.",
		missing: "Aucun formulaire Meta n'est relié : ce courtier ne reçoit pas de prospects automatiquement.",
	},
	{
		key: "calendar",
		label: "Agenda",
		done: "L'agenda du courtier est connecté : l'assistant propose de vrais créneaux.",
		missing: "Agenda non connecté : l'assistant ne peut pas réserver de rendez-vous.",
	},
	{
		key: "sms",
		label: "SMS",
		done: "Le numéro SMS de l'agence est configuré.",
		missing: "Aucun numéro SMS dans l'agence : aucun premier contact automatique possible.",
	},
];

const STATUS_LABELS: Record<RosterRealtor["status"], string> = {
	ACTIVE: "Actif",
	PAUSED: "En pause",
	CHURNED: "Parti",
};

export function RealtorRoster({
	realtors,
	renderActions,
}: {
	realtors: RosterRealtor[];
	renderActions: (realtor: RosterRealtor) => ReactNode;
}) {
	return (
		<ul className="flex flex-col divide-y rounded-lg border bg-card">
			{realtors.map((realtor, index) => {
				const done = SETUP_STEPS.filter((step) => realtor.setup[step.key]).length;
				return (
					<li
						key={realtor.id}
						className={cn("flex flex-col gap-3 p-4 lg:flex-row lg:items-center", REVEAL)}
						style={staggerStyle(index)}
					>
						<div className="flex min-w-0 flex-1 items-center gap-3">
							<Avatar>
								<AvatarFallback>{initialsFromName(realtor.name)}</AvatarFallback>
							</Avatar>
							<div className="flex min-w-0 flex-col">
								<span className="flex items-baseline gap-2">
									<span className="truncate font-medium">{realtor.name}</span>
									{realtor.status !== "ACTIVE" && (
										<span className="text-xs text-muted-foreground">{STATUS_LABELS[realtor.status]}</span>
									)}
								</span>
								<span className="flex flex-wrap gap-x-3 text-sm text-muted-foreground">
									<span className="truncate">
										{[realtor.brokerage, realtor.targetZones.join(", ")].filter(Boolean).join(" · ")}
									</span>
									{realtor.phone && (
										<a className="hover:text-foreground" href={`tel:${realtor.phone}`}>
											{formatPhone(realtor.phone)}
										</a>
									)}
									<a className="truncate hover:text-foreground" href={`mailto:${realtor.email}`}>
										{realtor.email}
									</a>
								</span>
							</div>
						</div>
						<div className="grid grid-cols-3 gap-4 text-sm lg:w-80">
							<div className="flex flex-col">
								<span className="text-xs text-muted-foreground">Prospects</span>
								<span className="font-medium tabular-nums">{realtor.leadsCount}</span>
							</div>
							<div className="flex flex-col">
								<span className="text-xs text-muted-foreground">Rendez-vous</span>
								<span className="font-medium tabular-nums">{realtor.appointmentsCount}</span>
							</div>
							<div className="flex min-w-0 flex-col">
								<span className="text-xs text-muted-foreground">Dernier prospect</span>
								<span className="truncate tabular-nums">
									{realtor.lastLeadAt ? formatDateTime(realtor.lastLeadAt).split(",")[0] : "—"}
								</span>
							</div>
						</div>
						<div className="flex flex-col gap-1 lg:w-44">
							<span className="text-xs text-muted-foreground">
								Configuration {done}/{SETUP_STEPS.length}
							</span>
							<span className="flex gap-3">
								{SETUP_STEPS.map((step) => {
									const ok = realtor.setup[step.key];
									return (
										<Tooltip key={step.key}>
											<TooltipTrigger asChild>
												<span
													tabIndex={0}
													className={cn(
														"flex items-center gap-1 rounded-sm text-xs outline-none focus-visible:ring-2 focus-visible:ring-ring",
														ok ? "text-foreground" : "text-muted-foreground line-through decoration-muted-foreground/40",
													)}
												>
													<span
														aria-hidden="true"
														className={cn("size-1.5 rounded-full", ok ? "bg-primary" : "bg-muted-foreground/40")}
													/>
													{step.label}
												</span>
											</TooltipTrigger>
											<TooltipContent className="block max-w-xs px-3 py-2 text-left">
												{ok ? step.done : step.missing}
											</TooltipContent>
										</Tooltip>
									);
								})}
							</span>
						</div>
						<div className="flex flex-wrap gap-2 lg:justify-end">{renderActions(realtor)}</div>
					</li>
				);
			})}
		</ul>
	);
}
