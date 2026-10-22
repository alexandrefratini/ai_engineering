type Part = { type?: string; text?: string };
type Message = {
	role: string;
	content?: string | Part[] | null;
	tool_calls?: unknown[];
	name?: string;
};
type Tool = { function?: { name?: string } };

const PORT = Number(process.env.MOCK_LLM_PORT ?? 4010);

const RULES: { match: RegExp; tool: string; args: Record<string, unknown> }[] = [
	{ match: /attend|répons|traiter|urgent/i, tool: "list_prospects_needing_attention", args: {} },
	{ match: /rendez-vous|semaine|agenda/i, tool: "list_appointments", args: { range: "upcoming" } },
	{ match: /mois|performance|résultat|rapidité/i, tool: "realtor_performance", args: { period: "30D" } },
	{ match: /karim|émilie|nadia|sophie|cherche|trouve/i, tool: "search_prospects", args: { query: "Karim" } },
];

function textOf(content: Message["content"]): string {
	if (typeof content === "string") return content;
	if (Array.isArray(content)) return content.map((part) => part.text ?? "").join(" ");
	return "";
}

function sdrStep(messages: Message[], available: Set<string | undefined>) {
	if (!available.has("read_lead") || !available.has("send_lead_sms")) return null;
	const brief = textOf(messages.find((message) => message.role === "user")?.content);
	const leadId = /lead (\w+) in agency/.exec(brief)?.[1];
	if (!leadId) return null;
	const toolRuns = messages.filter((message) => message.role === "tool").length;
	if (toolRuns === 0) return { tool: "read_lead", args: { leadId } };
	if (toolRuns === 1)
		return {
			tool: "send_lead_sms",
			args: {
				leadId,
				message: "Bonjour, ici l'assistante de votre courtière. Quel type de propriété recherchez-vous?",
			},
		};
	return { text: "Premier SMS de qualification mis en file." };
}

function decide(messages: Message[], tools: Tool[]) {
	const sdr = sdrStep(messages, new Set(tools.map((tool) => tool.function?.name)));
	if (sdr) return sdr;
	const last = messages.at(-1);
	if (last?.role === "tool") {
		const summary = textOf(last.content).replace(/\s+/g, " ").slice(0, 240);
		return { text: `Voici ce que j'ai trouvé : ${summary}` };
	}
	const asked = [...messages].reverse().find((message) => message.role === "user");
	const available = new Set(tools.map((tool) => tool.function?.name));
	const rule = RULES.find(
		(candidate) => candidate.match.test(textOf(asked?.content)) && available.has(candidate.tool),
	);
	if (rule) return { tool: rule.tool, args: rule.args };
	return { text: "Je suis un modèle simulé : posez une question sur vos prospects, vos rendez-vous ou votre mois." };
}

function completion(model: string, decision: ReturnType<typeof decide>) {
	const message = decision.tool
		? {
				role: "assistant",
				content: null,
				tool_calls: [
					{
						id: `call_${crypto.randomUUID().slice(0, 8)}`,
						type: "function",
						function: { name: decision.tool, arguments: JSON.stringify(decision.args) },
					},
				],
			}
		: { role: "assistant", content: decision.text };
	return {
		id: `chatcmpl-${crypto.randomUUID()}`,
		object: "chat.completion",
		created: Math.floor(Date.now() / 1000),
		model,
		choices: [{ index: 0, message, finish_reason: decision.tool ? "tool_calls" : "stop" }],
		usage: { prompt_tokens: 100, completion_tokens: 20, total_tokens: 120 },
	};
}

function stream(model: string, decision: ReturnType<typeof decide>) {
	const id = `chatcmpl-${crypto.randomUUID()}`;
	const created = Math.floor(Date.now() / 1000);
	const chunk = (delta: Record<string, unknown>, finish: string | null = null) =>
		`data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model, choices: [{ index: 0, delta, finish_reason: finish }] })}\n\n`;
	const parts = [chunk({ role: "assistant" })];
	if (decision.tool) {
		parts.push(
			chunk({
				tool_calls: [
					{
						index: 0,
						id: `call_${crypto.randomUUID().slice(0, 8)}`,
						type: "function",
						function: { name: decision.tool, arguments: JSON.stringify(decision.args) },
					},
				],
			}),
			chunk({}, "tool_calls"),
		);
	} else {
		for (const word of (decision.text ?? "").split(/(?<= )/)) parts.push(chunk({ content: word }));
		parts.push(chunk({}, "stop"));
	}
	parts.push(
		`data: ${JSON.stringify({ id, object: "chat.completion.chunk", created, model, choices: [], usage: { prompt_tokens: 100, completion_tokens: 20, total_tokens: 120 } })}\n\n`,
		"data: [DONE]\n\n",
	);
	return new Response(parts.join(""), {
		headers: { "content-type": "text/event-stream", "cache-control": "no-cache" },
	});
}

Bun.serve({
	port: PORT,
	async fetch(request) {
		const url = new URL(request.url);
		if (url.pathname.endsWith("/models"))
			return Response.json({ object: "list", data: [{ id: "mock", object: "model" }] });
		if (request.method !== "POST" || !url.pathname.endsWith("/chat/completions"))
			return new Response("not found", { status: 404 });
		const body = (await request.json()) as {
			model?: string;
			messages?: Message[];
			tools?: Tool[];
			stream?: boolean;
		};
		const decision = decide(body.messages ?? [], body.tools ?? []);
		console.log(
			`[mock-llm] ${body.stream ? "stream" : "json"} messages=${body.messages?.length ?? 0} tools=${body.tools?.length ?? 0} -> ${decision.tool ?? "texte"}`,
		);
		const model = body.model ?? "mock";
		return body.stream ? stream(model, decision) : Response.json(completion(model, decision));
	},
});

console.log(`[mock-llm] à l'écoute sur http://127.0.0.1:${PORT}/v1`);
