import { db } from "./src/client";

const EVIDENCE = [
	{
		firstName: "Karim",
		lastName: "Benali",
		items: [
			{ field: "propertyType", quote: "un condo" },
			{ field: "targetArea", quote: "Rosemont" },
			{ field: "intent", quote: "acheter" },
			{ field: "timeline", quote: "d'ici 3 mois" },
			{ field: "budgetMin", quote: "Entre 600 000 et 700 000 $" },
			{ field: "budgetMax", quote: "Entre 600 000 et 700 000 $" },
			{ field: "financing", quote: "je suis préautorisé" },
		],
	},
	{
		firstName: "Émilie",
		lastName: "Côté",
		items: [
			{ field: "budgetMin", quote: "autour de 800 000 $" },
			{ field: "budgetMax", quote: "autour de 800 000 $" },
		],
	},
	{
		firstName: "Nadia",
		lastName: "Fortin",
		items: [
			{ field: "intent", quote: "vendre notre maison" },
			{ field: "propertyType", quote: "maison" },
			{ field: "targetArea", quote: "Laval" },
		],
	},
];

for (const entry of EVIDENCE) {
	const lead = await db.lead.findFirst({
		where: { firstName: entry.firstName, lastName: entry.lastName },
		select: { id: true },
	});
	if (!lead) continue;
	const messages = await db.message.findMany({
		where: { sender: "LEAD", conversation: { leadId: lead.id } },
		select: { id: true, content: true },
	});
	const evidence = entry.items.flatMap((item) => {
		const message = messages.find((candidate) =>
			candidate.content.toLowerCase().includes(item.quote.toLowerCase()),
		);
		return message
			? [{ messageId: message.id, field: item.field, quote: item.quote }]
			: [];
	});
	await db.lead.update({
		where: { id: lead.id },
		data: { qualificationEvidence: evidence },
	});
	console.log(`${entry.firstName}: ${evidence.length}/${entry.items.length}`);
}
