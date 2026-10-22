import { createHmac } from "node:crypto";
import { db } from "./src/client";

const SECRET = process.env.BETTER_AUTH_SECRET ?? "";
const now = Date.now();
const ago = (minutes: number) => new Date(now - minutes * 60_000);
const ahead = (minutes: number) => new Date(now + minutes * 60_000);
const HOUR = 60;
const DAY = 24 * HOUR;

const people = [
	{ id: "demo-user", name: "Alexandre Fratini", email: "demo@fratex.ca", seen: 1 },
	{ id: "demo-marie", name: "Marie Tremblay", email: "demo-marie@fratex.ca", seen: 30 * HOUR },
	{ id: "demo-samuel", name: "Samuel Lapointe", email: "demo-samuel@fratex.ca", seen: 7 * HOUR },
];
for (const person of people)
	await db.user.upsert({
		where: { email: person.email },
		update: { name: person.name },
		create: {
			id: person.id,
			name: person.name,
			email: person.email,
			emailVerified: true,
			lastSeenAt: ago(person.seen),
		},
	});

await db.organization.upsert({
	where: { id: "workspace" },
	update: { metadata: JSON.stringify({ onboardedAt: new Date(now).toISOString() }) },
	create: {
		id: "workspace",
		name: "CRM",
		slug: "crm",
		createdAt: new Date(now),
		metadata: JSON.stringify({ onboardedAt: new Date(now).toISOString() }),
	},
});
const users = await db.user.findMany({ orderBy: [{ createdAt: "asc" }, { id: "asc" }] });
for (const user of users)
	await db.member.upsert({
		where: { organizationId_userId: { organizationId: "workspace", userId: user.id } },
		update: {},
		create: {
			id: `member-${user.id}`,
			organizationId: "workspace",
			userId: user.id,
			role: user.id === "demo-user" ? "owner" : "member",
			createdAt: new Date(now),
		},
	});

const sessions: Record<string, string> = {};
for (const [userId, token] of [
	["demo-user", "demo-session-token-0123456789abcdef"],
	["demo-marie", "demo-marie-session-token-0123456789"],
] as const) {
	await db.session.upsert({
		where: { token },
		update: { expiresAt: ahead(7 * DAY) },
		create: { id: `session-${userId}`, token, userId, expiresAt: ahead(7 * DAY) },
	});
	const sig = createHmac("sha256", SECRET).update(token).digest("base64");
	sessions[userId] = encodeURIComponent(`${token}.${sig}`);
}

const agency = await db.agency.upsert({
	where: { slug: "fratex-demo" },
	update: {},
	create: { name: "Agence Fratex", slug: "fratex-demo" },
});
const marie =
	(await db.client.findFirst({ where: { agencyId: agency.id, email: "marie@courtage.ca" } })) ??
	(await db.client.create({
		data: {
			agencyId: agency.id,
			name: "Marie Tremblay, courtière",
			email: "marie@courtage.ca",
			phone: "+15145550100",
			targetZones: ["Montréal", "Laval"],
			brokerage: "Courtage Plateau",
			licenseNumber: "J4821",
			propertyTypes: ["Condo", "Maison unifamiliale"],
			timezone: "America/Toronto",
		},
	}));
for (const [userId, role, clientId] of [
	["demo-user", "OWNER", null],
	["demo-samuel", "ADMIN", null],
	["demo-marie", "REALTOR", marie.id],
] as const)
	await db.agencyUser.upsert({
		where: { agencyId_userId: { agencyId: agency.id, userId } },
		update: { role, clientId },
		create: { agencyId: agency.id, userId, role, clientId },
	});

await db.smsConnection.upsert({
	where: { accountSid_phoneNumber: { accountSid: "ACdemo0000000000", phoneNumber: "+15145550000" } },
	update: {},
	create: {
		agencyId: agency.id,
		accountSid: "ACdemo0000000000",
		authToken: "demo-auth-token",
		phoneNumber: "+15145550000",
		verifiedAt: ago(5 * DAY),
	},
});
const account = await db.metaAdAccount.upsert({
	where: { agencyId_metaAccountId: { agencyId: agency.id, metaAccountId: "act_100200300" } },
	update: {},
	create: {
		agencyId: agency.id,
		clientId: marie.id,
		metaAccountId: "act_100200300",
		name: "Courtage Plateau — Meta",
		accessToken: "demo-meta-token",
	},
});
const campaign = await db.campaign.upsert({
	where: { metaCampaignId: "cmp_demo_automne" },
	update: {},
	create: {
		agencyId: agency.id,
		clientId: marie.id,
		adAccountId: account.id,
		metaCampaignId: "cmp_demo_automne",
		name: "Acheteurs Montréal — automne",
		dailyBudget: 4000,
	},
});
const form = await db.metaLeadForm.upsert({
	where: { metaFormId: "form_demo_acheteurs" },
	update: {},
	create: {
		agencyId: agency.id,
		clientId: marie.id,
		campaignId: campaign.id,
		metaFormId: "form_demo_acheteurs",
		name: "Formulaire acheteurs",
		fieldMapping: {},
	},
});

type Seed = {
	key: string;
	firstName: string;
	lastName: string;
	email?: string;
	status:
		| "NEW"
		| "CONTACTED"
		| "QUALIFYING"
		| "QUALIFIED"
		| "APPOINTMENT_BOOKED"
		| "APPOINTMENT_HELD"
		| "NURTURE"
		| "LOST";
	intent: "BUY" | "SELL" | "BUY_AND_SELL" | "RENT" | "INVEST";
	createdMinutesAgo: number;
	responseMinutes: number | null;
	score: number;
	qualification?: {
		propertyType: string;
		budgetMin: number;
		budgetMax: number;
		targetArea: string;
		timeline: string;
		financing: string;
	};
	escalation?: string;
	unread?: number;
	thread: { sender: "LEAD" | "AI_SDR" | "HUMAN_AGENT"; text: string; minutes: number }[];
	appointment?: { title: string; at: number; status: "CONFIRMED" | "COMPLETED"; place: string };
	events: ("FIRST_SMS_SENT" | "LEAD_REPLIED" | "LEAD_QUALIFIED" | "APPOINTMENT_SCHEDULED" | "APPOINTMENT_HELD")[];
};

const leads: Seed[] = [
	{
		key: "karim",
		firstName: "Karim",
		lastName: "Benali",
		email: "karim.benali@example.ca",
		status: "QUALIFIED",
		intent: "BUY",
		createdMinutesAgo: 3 * DAY,
		responseMinutes: 2,
		score: 82,
		qualification: {
			propertyType: "Condo",
			budgetMin: 600000,
			budgetMax: 700000,
			targetArea: "Rosemont",
			timeline: "D'ici 3 mois",
			financing: "Préautorisé",
		},
		thread: [
			{ sender: "AI_SDR", text: "Bonjour Karim, ici l'assistante de Marie Tremblay, courtière. Merci pour votre demande ! Vous cherchez à acheter dans quel secteur ?", minutes: 3 * DAY - 2 },
			{ sender: "LEAD", text: "Bonjour, un condo à Rosemont, 2 chambres.", minutes: 3 * DAY - 10 },
			{ sender: "AI_SDR", text: "Parfait. Quel budget visez-vous, et êtes-vous préautorisé ?", minutes: 3 * DAY - 11 },
			{ sender: "LEAD", text: "Entre 600 000 et 700 000 $, oui je suis préautorisé. J'aimerais acheter d'ici 3 mois.", minutes: 3 * DAY - 25 },
			{ sender: "AI_SDR", text: "Merci ! Marie peut vous rappeler cette semaine pour planifier des visites.", minutes: 3 * DAY - 26 },
		],
		events: ["FIRST_SMS_SENT", "LEAD_REPLIED", "LEAD_QUALIFIED"],
	},
	{
		key: "emilie",
		firstName: "Émilie",
		lastName: "Côté",
		status: "APPOINTMENT_BOOKED",
		intent: "BUY",
		createdMinutesAgo: 2 * DAY,
		responseMinutes: 3,
		score: 88,
		qualification: {
			propertyType: "Condo",
			budgetMin: 750000,
			budgetMax: 850000,
			targetArea: "Plateau-Mont-Royal",
			timeline: "Ce printemps",
			financing: "Préautorisé",
		},
		thread: [
			{ sender: "AI_SDR", text: "Bonjour Émilie, ici l'assistante de Marie Tremblay. Vous cherchez un condo sur le Plateau ?", minutes: 2 * DAY - 3 },
			{ sender: "LEAD", text: "Oui, autour de 800 000 $.", minutes: 2 * DAY - 20 },
			{ sender: "AI_SDR", text: "Marie a une disponibilité demain matin pour une visite. Est-ce que 7 h convient ?", minutes: 2 * DAY - 21 },
			{ sender: "LEAD", text: "Parfait, merci !", minutes: 2 * DAY - 30 },
		],
		appointment: { title: "Visite — condo Plateau", at: -20 * HOUR, status: "CONFIRMED", place: "4210, rue de Brébeuf" },
		events: ["FIRST_SMS_SENT", "LEAD_REPLIED", "LEAD_QUALIFIED", "APPOINTMENT_SCHEDULED"],
	},
	{
		key: "nadia",
		firstName: "Nadia",
		lastName: "Fortin",
		status: "APPOINTMENT_HELD",
		intent: "BUY_AND_SELL",
		createdMinutesAgo: 6 * DAY,
		responseMinutes: 4,
		score: 90,
		qualification: {
			propertyType: "Maison unifamiliale",
			budgetMin: 700000,
			budgetMax: 850000,
			targetArea: "Laval",
			timeline: "D'ici 6 mois",
			financing: "Vente de la propriété actuelle",
		},
		thread: [
			{ sender: "AI_SDR", text: "Bonjour Nadia, ici l'assistante de Marie Tremblay. Vous souhaitez vendre et acheter, c'est bien ça ?", minutes: 6 * DAY - 4 },
			{ sender: "LEAD", text: "Oui, vendre notre maison à Laval et en acheter une plus grande.", minutes: 6 * DAY - 40 },
		],
		appointment: { title: "Évaluation de la maison", at: 1 * DAY, status: "COMPLETED", place: "Laval" },
		events: ["FIRST_SMS_SENT", "LEAD_REPLIED", "LEAD_QUALIFIED", "APPOINTMENT_SCHEDULED", "APPOINTMENT_HELD"],
	},
	{
		key: "sophie",
		firstName: "Sophie",
		lastName: "Roy",
		status: "QUALIFYING",
		intent: "BUY",
		createdMinutesAgo: 20 * HOUR,
		responseMinutes: 6,
		score: 45,
		escalation: "HUMAN_TAKEOVER",
		unread: 1,
		thread: [
			{ sender: "AI_SDR", text: "Bonjour Sophie, ici l'assistante de Marie Tremblay. Quel type de propriété recherchez-vous ?", minutes: 20 * HOUR - 6 },
			{ sender: "LEAD", text: "Une maison avec un grand terrain, mais j'ai des questions sur le financement.", minutes: 20 * HOUR - 30 },
			{ sender: "HUMAN_AGENT", text: "Bonjour Sophie, c'est Marie. Je vous appelle demain pour en parler.", minutes: 19 * HOUR },
			{ sender: "LEAD", text: "Merci, je suis disponible après 17 h.", minutes: 6 * HOUR },
		],
		events: ["FIRST_SMS_SENT", "LEAD_REPLIED"],
	},
	{
		key: "patrick",
		firstName: "Patrick",
		lastName: "Morin",
		status: "CONTACTED",
		intent: "SELL",
		createdMinutesAgo: 1 * DAY + 2 * HOUR,
		responseMinutes: 9,
		score: 30,
		escalation: "Demande de parler directement à la courtière.",
		unread: 1,
		thread: [
			{ sender: "AI_SDR", text: "Bonjour Patrick, ici l'assistante de Marie Tremblay. Vous pensez vendre votre propriété ?", minutes: 1 * DAY + 2 * HOUR - 9 },
			{ sender: "LEAD", text: "Oui, mais je préfère parler directement à la courtière.", minutes: 1 * DAY },
			{ sender: "HUMAN_AGENT", text: "Bien noté, Marie vous rappelle aujourd'hui.", minutes: 23 * HOUR },
		],
		events: ["FIRST_SMS_SENT", "LEAD_REPLIED"],
	},
	{
		key: "julie",
		firstName: "Julie",
		lastName: "Gagnon",
		status: "NEW",
		intent: "BUY",
		createdMinutesAgo: 2 * DAY + 3 * HOUR,
		responseMinutes: null,
		score: 10,
		thread: [],
		events: [],
	},
	{
		key: "marc",
		firstName: "Marc",
		lastName: "Lavoie",
		status: "NURTURE",
		intent: "INVEST",
		createdMinutesAgo: 9 * DAY,
		responseMinutes: 12,
		score: 35,
		thread: [
			{ sender: "AI_SDR", text: "Bonjour Marc, ici l'assistante de Marie Tremblay. Vous cherchez un plex pour investir ?", minutes: 9 * DAY - 12 },
			{ sender: "LEAD", text: "Oui, mais pas avant l'an prochain.", minutes: 9 * DAY - 60 },
			{ sender: "AI_SDR", text: "Parfait, je vous relance au printemps.", minutes: 9 * DAY - 61 },
		],
		events: ["FIRST_SMS_SENT", "LEAD_REPLIED"],
	},
	{
		key: "lucie",
		firstName: "Lucie",
		lastName: "Bergeron",
		status: "LOST",
		intent: "RENT",
		createdMinutesAgo: 12 * DAY,
		responseMinutes: 15,
		score: 5,
		thread: [
			{ sender: "AI_SDR", text: "Bonjour Lucie, ici l'assistante de Marie Tremblay. Vous cherchez à acheter ?", minutes: 12 * DAY - 15 },
			{ sender: "AI_SDR", text: "Je vous relance : êtes-vous toujours à la recherche d'une propriété ?", minutes: 11 * DAY },
		],
		events: ["FIRST_SMS_SENT"],
	},
];

let phone = 5145550301;
for (const seed of leads) {
	const createdAt = ago(seed.createdMinutesAgo);
	const firstContactedAt =
		seed.responseMinutes === null ? null : new Date(createdAt.getTime() + seed.responseMinutes * 60_000);
	const number = `+1${phone++}`;
	const existing = await db.lead.findFirst({ where: { agencyId: agency.id, phone: number } });
	if (existing) continue;
	const lastMessage = seed.thread.at(-1);
	const lead = await db.lead.create({
		data: {
			agencyId: agency.id,
			clientId: marie.id,
			campaignId: campaign.id,
			metaFormId: form.id,
			firstName: seed.firstName,
			lastName: seed.lastName,
			email: seed.email ?? null,
			phone: number,
			status: seed.status,
			intent: seed.intent,
			score: seed.score,
			consentedAt: createdAt,
			consentSource: `meta:${form.metaFormId}:sms_consent`,
			escalationReason: seed.escalation ?? null,
			automationPausedAt: seed.escalation ? ago(19 * HOUR) : null,
			firstContactedAt,
			lastInteractedAt: lastMessage ? ago(lastMessage.minutes) : null,
			createdAt,
			...(seed.qualification
				? {
						...seed.qualification,
						qualificationSummary: `${seed.firstName} cherche : ${seed.qualification.propertyType.toLowerCase()} à ${seed.qualification.targetArea}, ${seed.qualification.timeline.toLowerCase()}.`,
					}
				: {}),
		},
	});
	if (seed.thread.length) {
		const conversation = await db.conversation.create({
			data: {
				agencyId: agency.id,
				leadId: lead.id,
				unreadCount: seed.unread ?? 0,
				lastMessageAt: lastMessage ? ago(lastMessage.minutes) : createdAt,
				createdAt,
			},
		});
		const messages = [...seed.thread].sort((a, b) => b.minutes - a.minutes);
		for (const message of messages) {
			const sentAt = ago(message.minutes);
			await db.message.create({
				data: {
					agencyId: agency.id,
					conversationId: conversation.id,
					sender: message.sender,
					content: message.text,
					status: message.sender === "LEAD" ? "RECEIVED" : "DELIVERED",
					sentAt,
				},
			});
		}
	}
	await db.attributionEvent.create({
		data: { id: `created:${lead.id}`, agencyId: agency.id, leadId: lead.id, eventType: "LEAD_CREATED", occurredAt: createdAt },
	});
	for (const [index, eventType] of seed.events.entries())
		await db.attributionEvent.create({
			data: {
				id: `${eventType.toLowerCase()}:${lead.id}`,
				agencyId: agency.id,
				leadId: lead.id,
				eventType,
				occurredAt: new Date(createdAt.getTime() + (seed.responseMinutes ?? 0) * 60_000 + index * 30 * 60_000),
			},
		});
	if (seed.appointment) {
		const start = ago(seed.appointment.at);
		await db.appointment.create({
			data: {
				agencyId: agency.id,
				leadId: lead.id,
				clientId: marie.id,
				title: seed.appointment.title,
				description: seed.appointment.place,
				startTime: start,
				endTime: new Date(start.getTime() + 60 * 60_000),
				status: seed.appointment.status,
			},
		});
	}
	if (seed.email) {
		const thread = await db.emailThread.create({
			data: {
				rootMessageId: `<demo-${lead.id}@example.ca>`,
				subject: "Visite du condo à Rosemont",
				firstMessageAt: ago(2 * DAY),
				lastMessageAt: ago(2 * DAY),
				messageCount: 1,
			},
		});
		await db.emailMessage.create({
			data: {
				threadId: thread.id,
				rfcMessageId: `<demo-${lead.id}@example.ca>`,
				syncedByUserId: "demo-user",
				direction: "INBOUND",
				fromEmail: seed.email,
				fromName: `${seed.firstName} ${seed.lastName}`,
				recipients: [{ email: "demo@fratex.ca", name: "Alexandre Fratini" }],
				subject: "Visite du condo à Rosemont",
				snippet: "Bonjour, je serais disponible samedi pour visiter le condo de la rue Masson.",
				sentAt: ago(2 * DAY),
			},
		});
	}
}

console.log(`COOKIE=${sessions["demo-user"]}`);
console.log(`COOKIE_MARIE=${sessions["demo-marie"]}`);
