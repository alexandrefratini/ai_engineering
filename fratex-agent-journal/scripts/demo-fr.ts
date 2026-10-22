import { db } from "./src/client";

const INDUSTRIES: Record<string, string> = {
	"Financial Services": "Services financiers",
	Software: "Logiciels",
	Banking: "Services bancaires",
	"Human Resources": "Ressources humaines",
	Accounting: "Comptabilité",
};

const COUNTRIES: Record<string, string> = {
	"United States": "États-Unis",
	"United Kingdom": "Royaume-Uni",
	Germany: "Allemagne",
	Singapore: "Singapour",
};

const CITIES: Record<string, string> = {
	London: "Londres",
	Singapore: "Singapour",
	Munich: "Munich",
};

const TITLES: Record<string, string> = {
	"Compliance Manager": "Gestionnaire de la conformité",
	"Security Engineer": "Ingénieur en sécurité",
	COO: "Chef de l'exploitation",
	"IT Director": "Directeur des TI",
	CTO: "Chef de la technologie",
	"Head of Legal": "Responsable des affaires juridiques",
	"VP Engineering": "Vice-président, ingénierie",
	"Head of Security": "Responsable de la sécurité",
	"Head of Platform": "Responsable de la plateforme",
	"Chief of Staff": "Chef de cabinet",
};

const SUBJECTS: Record<string, string> = {
	"Re: next steps": "Re : prochaines étapes",
	"Product demo": "Démonstration du produit",
	"Onboarding walkthrough": "Présentation de la mise en route",
	"Pricing discussion": "Discussion sur les prix",
	"Stage changed": "Étape modifiée",
	"Quarterly check-in": "Suivi trimestriel",
	"Stakeholder alignment": "Alignement des parties prenantes",
	"Follow-up call": "Appel de suivi",
	"Discovery call": "Appel de découverte",
	"Security review": "Revue de sécurité",
	"Pricing and terms": "Prix et conditions",
	"Intro to your implementation lead": "Présentation de votre responsable de la mise en œuvre",
	"Following up after the demo": "Suivi après la démonstration",
	"Technical deep dive": "Séance technique approfondie",
	"Send SOC 2 report": "Envoyer le rapport SOC 2",
	"Introduce the implementation team": "Présenter l'équipe de mise en œuvre",
	"Send the security questionnaire": "Envoyer le questionnaire de sécurité",
	"Book the technical deep dive": "Réserver la séance technique approfondie",
	"Chase procurement": "Relancer les achats",
	"Share pricing proposal": "Transmettre la proposition de prix",
};

const BODIES: Record<string, string> = {
	"Pushed the decision to after their board meeting.":
		"Décision reportée après leur conseil d'administration.",
	"Champion is keen, but the budget owner has not been in a call yet.":
		"Le champion est motivé, mais le responsable du budget n'a pas encore participé à un appel.",
	"Asked for a reference in the same vertical. Following up with marketing.":
		"A demandé une référence dans le même secteur. Suivi en cours avec le marketing.",
	"Ran through the SOC 2 timeline. They want evidence collection automated before the audit window opens.":
		"Calendrier SOC 2 passé en revue. Ils veulent automatiser la collecte de preuves avant l'ouverture de la fenêtre d'audit.",
	"They are evaluating us against two others. Differentiator is the agent, not the checklist.":
		"Ils nous comparent à deux autres fournisseurs. Notre différence, c'est l'agent, pas la liste de vérification.",
	"Procurement wants a security questionnaire back before they will look at pricing.":
		"Les achats veulent recevoir un questionnaire de sécurité avant d'examiner les prix.",
};

const FIELD_LABELS: Record<string, string> = {
	Territory: "Territoire",
	"Account type": "Type de compte",
	Segment: "Segment",
	"ICP fit score": "Adéquation au profil cible",
	"Lifecycle stage": "Étape du cycle de vie",
	"Lead source": "Source du prospect",
	"BDR owner": "Responsable du développement",
};

const OPTION_LABELS: Record<string, string> = {
	AMER: "Amériques",
	APAC: "Asie-Pacifique",
	Enterprise: "Grande entreprise",
	"Mid-Market": "Moyenne entreprise",
	SMB: "PME",
	Customer: "Client",
	Partner: "Partenaire",
	Churned: "Perdu",
	Lead: "Prospect",
	MQL: "Qualifié par le marketing",
	SQL: "Qualifié par les ventes",
	Opportunity: "Occasion",
	Inbound: "Entrant",
	Outbound: "Sortant",
	Event: "Événement",
};

async function translate(
	table: { updateMany: (args: { where: never; data: never }) => Promise<unknown> },
	column: string,
	map: Record<string, string>,
) {
	for (const [from, to] of Object.entries(map))
		await table.updateMany({
			where: { [column]: from } as never,
			data: { [column]: to } as never,
		});
}

await translate(db.company, "industry", INDUSTRIES);
await translate(db.company, "country", COUNTRIES);
await translate(db.company, "city", CITIES);
await translate(db.contact, "title", TITLES);
await translate(db.activity, "subject", SUBJECTS);
await translate(db.activity, "body", BODIES);
await translate(db.fieldDefinition, "label", FIELD_LABELS);
await translate(db.fieldOption, "label", OPTION_LABELS);

const deals = await db.deal.findMany({ select: { id: true, name: true } });
for (const deal of deals) {
	const name = deal.name.replace("— Comp AI", "— Fratex Agent");
	if (name !== deal.name)
		await db.deal.update({ where: { id: deal.id }, data: { name } });
}

const TEAM: Record<string, { name: string; email: string }> = {
	"ada@trycomp.ai": { name: "Camille Bouchard", email: "demo-camille@fratex.ca" },
	"marcus@trycomp.ai": { name: "Mathieu Lavoie", email: "demo-mathieu@fratex.ca" },
	"priya@trycomp.ai": { name: "Éloïse Pelletier", email: "demo-eloise@fratex.ca" },
};

const SEEN_HOURS_AGO = [2, 5, 26];

for (const [index, [email, next]] of Object.entries(TEAM).entries())
	await db.user.updateMany({
		where: { email },
		data: {
			...next,
			lastSeenAt: new Date(
				Date.now() - (SEEN_HOURS_AGO[index] ?? 24) * 60 * 60 * 1000,
			),
		},
	});

const USD_PER_UNIT: Record<string, number> = {
	USD: 1,
	EUR: 1.09,
	GBP: 1.27,
	CAD: 0.73,
	AUD: 0.66,
	JPY: 0.0067,
};

const cadPerUnit = (currency: string) => {
	const usd = USD_PER_UNIT[currency];
	return usd === undefined ? null : usd / (USD_PER_UNIT.CAD ?? 1);
};

await db.appSetting.updateMany({ data: { reportingCurrency: "CAD" } });

for (const currency of Object.keys(USD_PER_UNIT)) {
	if (currency === "CAD") continue;
	const exact = cadPerUnit(currency);
	if (exact === null) continue;
	const rate = Number(exact.toFixed(5));
	await db.exchangeRate.upsert({
		where: {
			baseCurrency_quoteCurrency_source: {
				baseCurrency: "CAD",
				quoteCurrency: currency,
				source: "FETCHED",
			},
		},
		create: {
			baseCurrency: "CAD",
			quoteCurrency: currency,
			rate,
			asOf: new Date(Date.now() - 24 * 60 * 60 * 1000),
			source: "FETCHED",
			provider: "seed",
		},
		update: { rate },
	});
}

for (const deal of await db.deal.findMany({
	select: { id: true, amount: true, currency: true },
})) {
	const exact = cadPerUnit(deal.currency ?? "CAD");
	if (exact === null || deal.amount === null) continue;
	const rate = Number(exact.toFixed(5));
	await db.deal.update({
		where: { id: deal.id },
		data: {
			baseAmount: Number((Number(deal.amount) * rate).toFixed(2)),
			baseCurrency: "CAD",
			fxRate: rate,
		},
	});
}

console.log("Données de démonstration du CRM traduites.");
