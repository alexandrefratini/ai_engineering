"use client";

import { type ReactNode, useState } from "react";
import { REVEAL, staggerStyle } from "../lib/motion";
import { cn } from "../lib/utils";
import { Button } from "./button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./card";
import { Checkbox } from "./checkbox";
import { Field, FieldDescription, FieldLabel } from "./field";
import { Input } from "./input";
import { WorkspaceNotice, WorkspaceSelect } from "./real-estate-workspace";

export type RealtorOnboardingData = {
	name: string;
	agency: string;
	email: string;
	phone: string;
	licenseNumber: string;
	targetZones: string[];
	propertyTypes: string[];
	crmChoice: "NONE" | "FOLLOW_UP_BOSS" | "KVCORE" | "HUBSPOT" | "OTHER";
	calendarLink: string;
	timezone: string;
};

export type OnboardingNextStep = { label: string; description: string; href: string };

const PROPERTY_TYPES = ["Condo", "Maison unifamiliale", "Plex", "Chalet", "Terrain", "Commercial", "Location"];

const CRM_OPTIONS: { id: RealtorOnboardingData["crmChoice"]; name: string }[] = [
	{ id: "NONE", name: "Aucun" },
	{ id: "FOLLOW_UP_BOSS", name: "Follow Up Boss" },
	{ id: "KVCORE", name: "kvCORE" },
	{ id: "HUBSPOT", name: "HubSpot" },
	{ id: "OTHER", name: "Autre" },
];

const TIMEZONES = [
	{ id: "America/Toronto", name: "Québec et Ontario (heure de l'Est)" },
	{ id: "America/Halifax", name: "Maritimes (heure de l'Atlantique)" },
	{ id: "America/Winnipeg", name: "Manitoba (heure du Centre)" },
	{ id: "America/Edmonton", name: "Alberta (heure des Rocheuses)" },
	{ id: "America/Vancouver", name: "Colombie-Britannique (heure du Pacifique)" },
];

function Section({
	title,
	description,
	index,
	children,
}: {
	title: string;
	description: string;
	index: number;
	children: ReactNode;
}) {
	return (
		<Card className={REVEAL} style={staggerStyle(index)}>
			<CardHeader>
				<CardTitle>{title}</CardTitle>
				<CardDescription>{description}</CardDescription>
			</CardHeader>
			<CardContent>
				<div className="grid gap-4 sm:grid-cols-2">{children}</div>
			</CardContent>
		</Card>
	);
}

function TextField({
	name,
	label,
	type = "text",
	optional,
	placeholder,
	description,
	defaultValue,
}: {
	name: string;
	label: string;
	type?: string;
	optional?: boolean;
	placeholder?: string;
	description?: string;
	defaultValue?: string;
}) {
	return (
		<Field>
			<FieldLabel htmlFor={`onboard-${name}`}>
				{label}
				{optional && <span className="font-normal text-muted-foreground"> (facultatif)</span>}
			</FieldLabel>
			<Input
				id={`onboard-${name}`}
				name={name}
				type={type}
				required={!optional}
				placeholder={placeholder}
				defaultValue={defaultValue}
			/>
			{description && <FieldDescription>{description}</FieldDescription>}
		</Field>
	);
}

export function RealtorOnboardingForm({
	onSubmitSuccess,
	defaults,
}: {
	onSubmitSuccess: (data: RealtorOnboardingData) => Promise<{ steps: OnboardingNextStep[] }>;
	defaults?: Partial<Pick<RealtorOnboardingData, "agency">>;
}) {
	const [crm, setCrm] = useState<RealtorOnboardingData["crmChoice"]>("NONE");
	const [timezone, setTimezone] = useState("America/Toronto");
	const [types, setTypes] = useState<string[]>([]);
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState<string | null>(null);
	const [steps, setSteps] = useState<OnboardingNextStep[] | null>(null);
	const [name, setName] = useState("");

	async function submit(form: HTMLFormElement) {
		if (types.length === 0) {
			setError("Choisissez au moins un type de propriété.");
			return;
		}
		setBusy(true);
		setError(null);
		const data = new FormData(form);
		const value = (key: string) => String(data.get(key) ?? "").trim();
		try {
			const result = await onSubmitSuccess({
				name: value("name"),
				agency: value("agency"),
				email: value("email"),
				phone: value("phone"),
				licenseNumber: value("licenseNumber"),
				targetZones: value("targetZones")
					.split(",")
					.map((zone) => zone.trim())
					.filter(Boolean),
				propertyTypes: types,
				crmChoice: crm,
				calendarLink: value("calendarLink"),
				timezone,
			});
			setName(value("name"));
			setSteps(result.steps);
		} catch (failure) {
			setError(failure instanceof Error ? failure.message : "Enregistrement impossible.");
		} finally {
			setBusy(false);
		}
	}

	if (steps)
		return (
			<Card className={REVEAL}>
				<CardHeader>
					<CardTitle>{name} est ajouté(e)</CardTitle>
					<CardDescription>
						Le profil est enregistré. Il reste ces étapes pour que l'assistant reçoive et contacte ses prospects.
					</CardDescription>
				</CardHeader>
				<CardContent>
					<ol className="flex flex-col divide-y">
						{steps.map((step, index) => (
							<li key={step.href} className="flex items-center gap-3 py-2.5 first:pt-0 last:pb-0">
								<span className="flex size-6 shrink-0 items-center justify-center rounded-full border text-xs tabular-nums">
									{index + 1}
								</span>
								<span className="flex min-w-0 flex-1 flex-col">
									<span className="text-sm font-medium">{step.label}</span>
									<span className="text-xs text-muted-foreground">{step.description}</span>
								</span>
								<Button asChild variant={index === 0 ? "default" : "outline"} size="sm">
									<a href={step.href}>Ouvrir</a>
								</Button>
							</li>
						))}
					</ol>
				</CardContent>
			</Card>
		);

	return (
		<form
			className="flex flex-col gap-4"
			onSubmit={(event) => {
				event.preventDefault();
				void submit(event.currentTarget);
			}}
		>
			<Section index={0} title="Identité" description="Ces coordonnées apparaissent dans le portail et dans les messages au prospect.">
				<TextField name="name" label="Nom complet" placeholder="Marie Tremblay" />
				<TextField name="email" label="Courriel" type="email" placeholder="marie@courtage.ca" />
				<TextField name="phone" label="Téléphone" type="tel" optional placeholder="514 555-0100" />
				<TextField
					name="agency"
					label="Bannière immobilière"
					placeholder="RE/MAX, Royal LePage, Via Capitale…"
					defaultValue={defaults?.agency}
				/>
				<TextField
					name="licenseNumber"
					label="Numéro de permis OACIQ"
					placeholder="Ex. : J1234"
					description="Exigé pour exercer au Québec."
				/>
			</Section>

			<Section
				index={1}
				title="Prospection"
				description="L'assistant utilise ces informations pour qualifier et orienter les prospects vers ce courtier."
			>
				<div className="sm:col-span-2">
					<TextField
						name="targetZones"
						label="Secteurs desservis"
						placeholder="Plateau-Mont-Royal, Rosemont, Laval"
						description="Séparez les secteurs par des virgules."
					/>
				</div>
				<fieldset className="flex flex-col gap-2 sm:col-span-2">
					<legend className="mb-2 text-sm font-medium">Types de propriété</legend>
					<div className="flex flex-wrap gap-x-5 gap-y-2">
						{PROPERTY_TYPES.map((type) => (
							<label key={type} className="flex items-center gap-2 text-sm">
								<Checkbox
									checked={types.includes(type)}
									onCheckedChange={(checked) =>
										setTypes((current) =>
											checked ? [...current, type] : current.filter((item) => item !== type),
										)
									}
								/>
								{type}
							</label>
						))}
					</div>
				</fieldset>
			</Section>

			<Section index={2} title="Outils" description="Où envoyer les prospects et comment réserver les rendez-vous.">
				<WorkspaceSelect
					label="CRM du courtier"
					value={crm}
					options={CRM_OPTIONS}
					onChange={(value) => {
						const choice = CRM_OPTIONS.find((option) => option.id === value);
						if (choice) setCrm(choice.id);
					}}
				/>
				<WorkspaceSelect label="Fuseau horaire" value={timezone} options={TIMEZONES} onChange={setTimezone} />
				<div className="sm:col-span-2">
					<TextField
						name="calendarLink"
						label="Lien de réservation"
						type="url"
						optional
						placeholder="https://calendly.com/…"
						description="Utilisé tant que l'agenda Google du courtier n'est pas connecté."
					/>
				</div>
			</Section>

			{error && <WorkspaceNotice title="Enregistrement impossible" error={error} />}
			<div className={cn("flex justify-end", REVEAL)} style={staggerStyle(3)}>
				<Button disabled={busy}>{busy ? "Enregistrement…" : "Ajouter le courtier"}</Button>
			</div>
		</form>
	);
}
