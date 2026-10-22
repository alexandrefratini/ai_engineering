cd /home/user/endsi3g/fratex-agent/packages/ui/src/components && cat > lead-tools.tsx <<'EOF'
"use client";

import { type ReactNode, useState } from "react";
import { REVEAL, staggerStyle } from "../lib/motion";
import { formatDateTime, INTENT_LABELS, LEAD_SOURCE_OPTIONS } from "../lib/real-estate";
import { cn } from "../lib/utils";
import { Button } from "./button";
import { Checkbox } from "./checkbox";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "./dialog";
import { Field, FieldDescription, FieldLabel } from "./field";
import { Input } from "./input";
import { LeadPanel } from "./lead-profile";
import { WorkspaceNotice, WorkspaceSelect } from "./real-estate-workspace";
import { Switch } from "./switch";
import { Textarea } from "./textarea";

export type LeadNote = { id: string; body: string; createdAt: string; authorName: string | null };

export function LeadNotes({
	notes,
	canWrite,
	onAdd,
	index,
}: {
	notes: LeadNote[];
	canWrite: boolean;
	onAdd: (body: string) => Promise<void>;
	index?: number;
}) {
	const [draft, setDraft] = useState("");
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState<string | null>(null);
	async function save() {
		const body = draft.trim();
		if (!body) return;
		setBusy(true);
		setError(null);
		try {
			await onAdd(body);
			setDraft("");
		} catch (failure) {
			setError(failure instanceof Error ? failure.message : "Note non enregistrée.");
		} finally {
			setBusy(false);
		}
	}
	return (
		<LeadPanel
			index={index}
			title="Notes"
			description="Ce que vous savez et que l'assistant ne voit pas : appel, rencontre, préférences. Visibles par l'équipe et le courtier."
		>
			<div className="flex flex-col gap-3">
				{canWrite && (
					<div className="flex flex-col gap-2">
						<Textarea
							aria-label="Nouvelle note"
							placeholder="Ex. : rappelé à 17 h, préfère un condo avec stationnement, prêt hypothécaire préautorisé."
							value={draft}
							rows={3}
							onChange={(event) => setDraft(event.target.value)}
							onKeyDown={(event) => {
								if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
									event.preventDefault();
									void save();
								}
							}}
						/>
						<div className="flex items-center justify-between gap-2">
							<span className="text-xs text-muted-foreground">Ctrl + Entrée pour enregistrer</span>
							<Button size="sm" disabled={busy || !draft.trim()} onClick={() => void save()}>
								{busy ? "Enregistrement…" : "Ajouter la note"}
							</Button>
						</div>
						{error && <WorkspaceNotice title="Note non enregistrée" error={error} />}
					</div>
				)}
				{notes.length === 0 ? (
					<span className="text-sm text-muted-foreground">Aucune note pour l'instant.</span>
				) : (
					<ul className="flex flex-col divide-y">
						{notes.map((note, position) => (
							<li key={note.id} className={cn("flex flex-col gap-1 py-2.5 first:pt-0 last:pb-0", REVEAL)} style={staggerStyle(position)}>
								<span className="text-xs text-muted-foreground">
									{note.authorName ?? "Membre retiré"} · {formatDateTime(note.createdAt)}
								</span>
								<p className="text-sm whitespace-pre-wrap">{note.body}</p>
							</li>
						))}
					</ul>
				)}
			</div>
		</LeadPanel>
	);
}

export type NewLeadData = {
	firstName: string;
	lastName?: string;
	phone: string;
	email?: string;
	source: (typeof LEAD_SOURCE_OPTIONS)[number]["id"];
	intent: "BUY" | "SELL" | "BUY_AND_SELL" | "RENT" | "INVEST" | "UNKNOWN";
	clientId?: string;
	note?: string;
	smsConsent: boolean;
	startAssistant: boolean;
};

export type NewLeadResult = { id: string | null; duplicate: boolean; assistantQueued: boolean };

const INTENTS = (["BUY", "SELL", "BUY_AND_SELL", "INVEST", "RENT", "UNKNOWN"] as const).map((id) => ({
	id,
	name: id === "UNKNOWN" ? "À confirmer" : (INTENT_LABELS[id] ?? id),
}));

function NewLeadForm({
	realtors,
	onSubmit,
	onOpenLead,
}: {
	realtors?: { id: string; name: string }[];
	onSubmit: (data: NewLeadData) => Promise<NewLeadResult>;
	onOpenLead: (id: string) => void;
}) {
	const [source, setSource] = useState<NewLeadData["source"]>("REFERRAL");
	const [intent, setIntent] = useState<NewLeadData["intent"]>("BUY");
	const [clientId, setClientId] = useState(realtors?.[0]?.id ?? "");
	const [consent, setConsent] = useState(false);
	const [assistant, setAssistant] = useState(true);
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState<string | null>(null);
	const [duplicate, setDuplicate] = useState<NewLeadResult | null>(null);

	async function submit(form: HTMLFormElement) {
		const data = new FormData(form);
		const value = (key: string) => String(data.get(key) ?? "").trim();
		setBusy(true);
		setError(null);
		setDuplicate(null);
		try {
			const result = await onSubmit({
				firstName: value("firstName"),
				lastName: value("lastName") || undefined,
				phone: value("phone"),
				email: value("email") || undefined,
				source,
				intent,
				clientId: clientId || undefined,
				note: value("note") || undefined,
				smsConsent: consent,
				startAssistant: consent && assistant,
			});
			if (result.duplicate) setDuplicate(result);
			else if (result.id) onOpenLead(result.id);
		} catch (failure) {
			setError(failure instanceof Error ? failure.message : "Prospect non enregistré.");
		} finally {
			setBusy(false);
		}
	}

	return (
		<form
			className="flex flex-col gap-4"
			onSubmit={(event) => {
				event.preventDefault();
				void submit(event.currentTarget);
			}}
		>
			<div className="grid gap-3 sm:grid-cols-2">
				<Field>
					<FieldLabel htmlFor="lead-first-name">Prénom</FieldLabel>
					<Input id="lead-first-name" name="firstName" required autoComplete="off" />
				</Field>
				<Field>
					<FieldLabel htmlFor="lead-last-name">
						Nom <span className="font-normal text-muted-foreground">(facultatif)</span>
					</FieldLabel>
					<Input id="lead-last-name" name="lastName" autoComplete="off" />
				</Field>
				<Field>
					<FieldLabel htmlFor="lead-phone">Cellulaire</FieldLabel>
					<Input
						id="lead-phone"
						name="phone"
						type="tel"
						required
						placeholder="514 555-0100"
						pattern="[\d\s\(\)\.\+\-]{10,20}"
						title="Numéro nord-américain à 10 chiffres, par exemple 514 555-0100."
					/>
				</Field>
				<Field>
					<FieldLabel htmlFor="lead-email">
						Courriel <span className="font-normal text-muted-foreground">(facultatif)</span>
					</FieldLabel>
					<Input id="lead-email" name="email" type="email" autoComplete="off" />
				</Field>
				<WorkspaceSelect
					label="Provenance"
					value={source}
					options={[...LEAD_SOURCE_OPTIONS]}
					onChange={(value) => {
						const option = LEAD_SOURCE_OPTIONS.find((item) => item.id === value);
						if (option) setSource(option.id);
					}}
				/>
				<WorkspaceSelect
					label="Projet"
					value={intent}
					options={INTENTS}
					onChange={(value) => {
						const option = INTENTS.find((item) => item.id === value);
						if (option) setIntent(option.id);
					}}
				/>
				{realtors && realtors.length > 0 && (
					<div className="sm:col-span-2">
						<WorkspaceSelect label="Courtier" value={clientId} options={realtors} onChange={setClientId} />
					</div>
				)}
			</div>
			<Field>
				<FieldLabel htmlFor="lead-note">
					Note <span className="font-normal text-muted-foreground">(facultatif)</span>
				</FieldLabel>
				<Textarea id="lead-note" name="note" rows={2} placeholder="Ex. : référé par M. Gagnon, cherche un plex à Rosemont." />
			</Field>
			<div className="flex flex-col gap-3 rounded-md border bg-muted/30 p-3">
				<label className="flex items-start gap-2 text-sm">
					<Checkbox className="mt-0.5" checked={consent} onCheckedChange={(checked) => setConsent(checked === true)} />
					<span>
						Le prospect accepte d'être contacté par SMS
						<span className="block text-xs text-muted-foreground">
							Exigé par la Loi canadienne anti-pourriel. Sans cette case, aucun SMS n'est envoyé.
						</span>
					</span>
				</label>
				<label className={cn("flex items-center justify-between gap-3 text-sm", !consent && "opacity-50")}>
					<span>
						Lancer l'assistant maintenant
						<span className="block text-xs text-muted-foreground">
							Premier SMS en moins de 2 minutes, puis qualification.
						</span>
					</span>
					<Switch checked={consent && assistant} disabled={!consent} onCheckedChange={setAssistant} />
				</label>
			</div>
			{duplicate && (
				<div className="flex flex-wrap items-center justify-between gap-2 rounded-md border p-3 text-sm">
					<span>
						{duplicate.id
							? "Ce numéro existe déjà. Rien n'a été créé."
							: "Ce numéro appartient déjà au prospect d'un autre courtier."}
					</span>
					{duplicate.id && (
						<Button type="button" size="sm" variant="outline" onClick={() => duplicate.id && onOpenLead(duplicate.id)}>
							Ouvrir la fiche
						</Button>
					)}
				</div>
			)}
			{error && <WorkspaceNotice title="Prospect non enregistré" error={error} />}
			<FieldDescription>La fiche s'ouvre dès l'enregistrement.</FieldDescription>
			<Button disabled={busy}>{busy ? "Enregistrement…" : "Créer le prospect"}</Button>
		</form>
	);
}

export function NewLeadDialog({
	trigger,
	realtors,
	onSubmit,
	onOpenLead,
}: {
	trigger: ReactNode;
	realtors?: { id: string; name: string }[];
	onSubmit: (data: NewLeadData) => Promise<NewLeadResult>;
	onOpenLead: (id: string) => void;
}) {
	const [open, setOpen] = useState(false);
	return (
		<Dialog open={open} onOpenChange={setOpen}>
			<DialogTrigger asChild>{trigger}</DialogTrigger>
			<DialogContent className="max-h-[90svh] overflow-y-auto sm:max-w-xl">
				<DialogHeader>
					<DialogTitle>Nouveau prospect</DialogTitle>
					<DialogDescription>
						Une référence, un appel, une visite libre : ajoutez-le ici pour qu'il suive le même parcours qu'un
						prospect Meta.
					</DialogDescription>
				</DialogHeader>
				{open && (
					<NewLeadForm
						realtors={realtors}
						onSubmit={onSubmit}
						onOpenLead={(id) => {
							setOpen(false);
							onOpenLead(id);
						}}
					/>
				)}
			</DialogContent>
		</Dialog>
	);
}
EOF
cd /home/user/endsi3g/fratex-agent && bunx biome check --write packages/ui/src/components/lead-tools.tsx packages/ui/src/components/lead-profile.tsx packages/ui/src/lib/real-estate.ts 2>&1 | tail -2; cd packages/ui && bunx tsc --noEmit 2>&1 | tail -8; echo ui $?