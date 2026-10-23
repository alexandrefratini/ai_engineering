import { db } from "./src/client";

const now = Date.now();
const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const ago = (ms: number) => new Date(now - ms);
const ahead = (ms: number) => new Date(now + ms);

const agency = await db.agency.findUniqueOrThrow({ where: { slug: "fratex-demo" } });
const leads = await db.lead.findMany({
	where: { agencyId: agency.id },
	orderBy: { createdAt: "asc" },
	take: 6,
});
const contact = await db.contact.findFirst({ orderBy: { createdAt: "asc" } });

await db.activity.deleteMany({ where: { id: { startsWith: "demo-team-" } } });
await db.leadNote.deleteMany({ where: { id: { startsWith: "demo-team-" } } });
await db.message.deleteMany({ where: { id: { startsWith: "demo-team-" } } });
await db.supportRequest.deleteMany({ where: { id: { startsWith: "demo-team-" } } });
await db.generatedContent.deleteMany({ where: { idempotencyKey: { startsWith: "demo-team-" } } });

const tasks: [string, string, string, number | null, number | null][] = [
	["demo-user", "Relancer les prospects sans réponse depuis 48 h", "overdue", -DAY, null],
	["demo-user", "Valider le gabarit du premier SMS avec Marie", "open", 2 * DAY, null],
	["demo-user", "Brancher le numéro Twilio de production", "done", -3 * DAY, 2 * DAY],
	["demo-samuel", "Appeler la notaire au sujet du dossier Gagnon", "overdue", -2 * DAY, null],
	["demo-samuel", "Préparer la comparaison d'offres pour Sophie", "open", DAY, null],
	["demo-samuel", "Mettre à jour les secteurs de Marie", "done", -5 * DAY, 4 * DAY],
	["demo-samuel", "Revoir les rendez-vous de la semaine", "open", 4 * DAY, null],
	["demo-marie", "Confirmer la visite de samedi", "open", DAY, null],
	["demo-marie", "Envoyer l'inscription à l'acheteur", "done", -2 * DAY, DAY],
];
let n = 0;
for (const [userId, subject, state, due, doneAgo] of tasks)
	await db.activity.create({
		data: {
			id: `demo-team-task-${n++}`,
			type: "TASK",
			subject,
			createdById: userId,
			contactId: contact?.id,
			dueAt: due === null ? null : state === "done" ? ago(-due) : due < 0 ? ago(-due) : ahead(due),
			completedAt: doneAgo === null ? null : ago(doneAgo),
			createdAt: ago((n + 1) * 7 * HOUR),
		},
	});

const calls: [string, string, number][] = [
	["demo-user", "Appel de suivi avec un nouveau prospect Meta", 5 * HOUR],
	["demo-samuel", "Appel de qualification, budget confirmé", 9 * HOUR],
	["demo-samuel", "Rencontre de démarrage avec Marie", 3 * DAY],
	["demo-marie", "Visite d'un condo à Laval", 26 * HOUR],
];
for (const [userId, subject, age] of calls)
	await db.activity.create({
		data: {
			id: `demo-team-call-${n++}`,
			type: subject.startsWith("Rencontre") || subject.startsWith("Visite") ? "MEETING" : "CALL",
			subject,
			createdById: userId,
			contactId: contact?.id,
			occurredAt: ago(age),
			createdAt: ago(age),
		},
	});

const notes: [string, number, string, number][] = [
	["demo-user", 0, "Le prospect veut visiter ce week-end, éviter dimanche matin.", 4 * HOUR],
	["demo-samuel", 1, "Financement préapprouvé, mise de fonds de 60 000 $.", 11 * HOUR],
	["demo-samuel", 2, "À rappeler jeudi après 17 h, préfère les SMS.", 2 * DAY],
	["demo-marie", 0, "A visité deux condos, hésite entre Rosemont et Villeray.", 28 * HOUR],
	["demo-marie", 3, "Offre déposée, réponse attendue demain midi.", 5 * HOUR],
];
let i = 0;
for (const [userId, leadIndex, body, age] of notes) {
	const lead = leads[leadIndex % Math.max(1, leads.length)];
	if (!lead) continue;
	await db.leadNote.create({
		data: {
			id: `demo-team-note-${i++}`,
			agencyId: agency.id,
			leadId: lead.id,
			authorId: userId,
			body,
			createdAt: ago(age),
		},
	});
}

const humanSms: [string, number, string, number][] = [
	["demo-marie", 0, "Bonjour! Je confirme la visite de samedi à 10 h.", 6 * HOUR],
	["demo-samuel", 1, "Bonjour, je vous envoie la comparaison d'offres ce soir.", 14 * HOUR],
];
i = 0;
for (const [userId, leadIndex, content, age] of humanSms) {
	const lead = leads[leadIndex % Math.max(1, leads.length)];
	if (!lead) continue;
	const conversation =
		(await db.conversation.findFirst({ where: { agencyId: agency.id, leadId: lead.id } })) ??
		(await db.conversation.create({ data: { agencyId: agency.id, leadId: lead.id } }));
	await db.message.create({
		data: {
			id: `demo-team-sms-${i++}`,
			agencyId: agency.id,
			conversationId: conversation.id,
			sender: "HUMAN_AGENT",
			content,
			status: "DELIVERED",
			sentAt: ago(age),
			metadata: { authorId: userId },
		},
	});
}

await db.supportRequest.create({
	data: {
		id: "demo-team-support-0",
		userId: "demo-marie",
		kind: "QUESTION",
		subject: "Comment ajouter mon deuxième secteur?",
		message: "Comment ajouter mon deuxième secteur?",
		pagePath: "/real-estate/portal",
		createdAt: ago(20 * HOUR),
	},
});

const generated: [number, "LISTING_SUGGESTION" | "NOTE", "DRAFT" | "APPROVED" | "SENT", string, number][] = [
	[0, "LISTING_SUGGESTION", "DRAFT", "Condo de 2 chambres, 345 rue Sainte-Rose, Laval — 489 000 $", 3 * HOUR],
	[1, "LISTING_SUGGESTION", "DRAFT", "Maison de ville, 78 avenue des Érables, Laval — 524 900 $", 9 * HOUR],
	[2, "LISTING_SUGGESTION", "APPROVED", "Condo avec stationnement, 1200 boulevard Chomedey, Laval — 459 000 $", 2 * DAY],
	[3, "NOTE", "SENT", "Le prospect demande à parler directement à la courtière au sujet d'une offre.", 5 * HOUR],
	[4, "NOTE", "SENT", "Prospect qualifié (score 80 sur 100). Critères confirmés par le prospect : Projet : achat. Secteur : Laval. Échéance : 3 mois. Rien n'est estimé : chaque valeur vient des réponses du prospect.", 80 * 60 * 1000],
];
for (const [leadIndex, kind, status, body, age] of generated) {
	const lead = leads[leadIndex % Math.max(1, leads.length)];
	if (!lead) continue;
	await db.generatedContent.create({
		data: {
			agencyId: agency.id,
			leadId: lead.id,
			clientId: lead.clientId,
			kind,
			status,
			agent: body.startsWith("Prospect qualifié") ? "visit_prep" : "sdr",
			body,
			idempotencyKey: `demo-team-gen-${leadIndex}`,
			approvedAt: status === "APPROVED" ? ago(age - HOUR) : null,
			approvedById: status === "APPROVED" ? "demo-user" : null,
			createdAt: ago(age),
		},
	});
}

console.log("équipe: tâches, notes, SMS, demande de support et contenu généré ajoutés");
