export const meta = {
  name: 'fratex-ai-assistant-real-estate',
  description: 'Give the Fratex AI assistant read-only real-estate tools with agency/realtor isolation, AI Elements UI, review, journal, push',
  phases: [
    { title: 'Understand', detail: 'map tool registration, chat context, transcript UI' },
    { title: 'Build', detail: 'agent tools + tests, then chat UI' },
    { title: 'Review', detail: 'security and UX review with fixes' },
    { title: 'Journal', detail: 'journal section, patch, commit, push' },
  ],
}

const SPEC = '/home/user/ai_engineering/fratex-agent-journal/REBUILD-SPEC.md'
const SCR = '/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad'
const SHOTS = '/home/user/ai_engineering/fratex-agent-journal/screenshots/apres'
const COMMON = `Repo: /home/user/endsi3g/fratex-agent ("Fratex Agent", AI SDR for Quebec real-estate brokers). Read ${SPEC} section 0 for rules and environment. Follow AGENTS.md strictly (NO code comments; intelligence lives in apps/agent; agency isolation; no PII in logs; JSON validated with Zod; optional keys never throw). Dev servers run on :3000/:3001: NEVER start/stop/restart them, NEVER pkill. Do not commit in the product repo. All user-facing text in Quebec French.`

const MAP = {
  type: 'object',
  properties: {
    toolRegistration: { type: 'string' },
    chatContext: { type: 'string', description: 'which session attributes identify the user, workspace, purpose in a private chat; how to get the user agencies/role/clientId safely' },
    existingRealEstateCode: { type: 'string', description: 'reusable helpers (agencyAccess, real-estate libs, portal stats logic) and where they live' },
    instructions: { type: 'string', description: 'where the assistant instructions/skills live and how tools are described to the model' },
    transcriptUi: { type: 'string', description: 'how tool calls render in the chat UI (labels, result cards), which AI Elements components exist in packages/ui' },
    tests: { type: 'string', description: 'how agent tools are tested (spec files to mimic, how to run)' },
    llmAvailableLocally: { type: 'boolean' },
  },
  required: ['toolRegistration', 'chatContext', 'existingRealEstateCode', 'instructions', 'transcriptUi', 'tests', 'llmAvailableLocally'],
}
const RESULT = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    filesChanged: { type: 'array', items: { type: 'string' } },
    toolContracts: { type: 'string', description: 'name, input, output shape of each tool' },
    verification: { type: 'string' },
    screenshots: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['summary', 'filesChanged', 'toolContracts', 'verification', 'screenshots', 'issues'],
}

phase('Understand')
const map = await agent(`${COMMON}

Map, precisely and with file paths, how to add new read-only tools to the AI assistant used in the private chat (/chat) of this app: how tools are registered (apps/agent/agent/tools/*.ts with eve defineTool), how a tool knows the current user and purpose (apps/agent/agent/lib/session-purpose.ts: attribute(ctx, "userId"), purposeOf(ctx)), how SDR-only tools are restricted (apps/agent/agent/lib/sdr-scope.ts), which helpers can scope data to the user's agencies and realtor clientId (packages/db/src/agency-access.ts agencyAccess), where real-estate metrics are computed today (apps/api/src/real-estate/real-estate.service.ts — note the agent must not import apps/api; shared logic may need to live in packages/db or be re-implemented in apps/agent/agent/lib), where the assistant's instructions and skills live, how tool calls are shown in the chat UI (apps/app/lib/agent-transcript.ts VERBS, apps/app/components/agent-builder/*, packages/ui AI components such as reasoning, thinking-indicator, suggestion, message, thread-message), how agent tools are tested (apps/agent/test/*.spec.ts), and whether an LLM provider is configured locally (.env AI_GATEWAY_API_KEY or LLM_BASE_URL).`, { label: 'understand', phase: 'Understand', schema: MAP })

phase('Build')
const tools = await agent(`${COMMON}

Codebase map from a previous agent: ${JSON.stringify(map)}

YOUR SCOPE: apps/agent/** (tools, lib, instructions/skills, tests) and, only if needed for shared queries, a new file under packages/db/src/ (do not edit existing packages/db files except adding an export to package.json exports if the repo requires it).
TASK: add read-only real-estate tools usable by a signed-in user in their private chat (purpose "builder") and by team agents if the codebase supports a user attribute there; refuse anything else with a clear French error. Every query is scoped by agencyAccess(db, userId, agencyId?) (agency isolation; a REALTOR only sees their own clientId). Tools (snake_case names, French descriptions telling the model when to use them, compact JSON outputs with fiche links "/{slug}/real-estate/leads/{id}?agencyId=…" when a workspace slug is available):
1. list_prospects_needing_attention — unread replies, human takeover in progress, never contacted; newest first; limit 20.
2. search_prospects — by name/phone/email/area, optional status filter; limit 20.
3. read_prospect — the lead's confirmed criteria with the prospect's own quotes as evidence, status, last 5 messages, appointments, notes, consent state. Unconfirmed values must be labeled as suggestions.
4. list_appointments — upcoming or past N days, with status and lead name.
5. realtor_performance — leads received, median first response, appointments, conversion, for 30 days / 90 days / this month, optionally per realtor (staff only).
Update the assistant instructions/skills so it answers broker questions in French using these tools, never invents numbers, and points to the fiche link. Write integration tests (mimic existing apps/agent/test patterns) proving: isolation between two agencies, a realtor only sees their leads, the builder-purpose guard, and correct counts on a small seeded dataset. Run them and apps/agent tsc.`, { label: 'build:agent-tools', phase: 'Build', schema: RESULT })

const ui = await agent(`${COMMON}

Codebase map: ${JSON.stringify(map).slice(0, 6000)}
New tools built by the previous agent: ${JSON.stringify(tools).slice(0, 6000)}

YOUR SCOPE: apps/app/lib/agent-transcript.ts, apps/app/components/agent-builder/**, apps/app/app/(app)/[slug]/(agent-builder)/** and packages/ui AI components (reasoning, thinking-indicator, suggestion, message, thread-message, and new AI Elements style components if missing, e.g. a Tool step component and a result card) plus their tests.
TASK (AI-native UX, shadcn AI Elements style): (1) French step labels for the new tools in VERBS ("A cherché les prospects à traiter", "A lu la fiche du prospect", …); (2) render the tools' results as compact cards in the chat (prospect rows with status dot + label and a link that opens the FICHE; appointments with date and status; performance as a small metric row) instead of raw JSON; (3) collapsible tool steps (AI Elements "Tool" pattern: header with label + state, body with result card); (4) on the chat home, add a "Questions rapides" row of French suggestion chips that prefill the composer for brokers ("Quels prospects attendent une réponse ?", "Résume la fiche de mon prospect le plus avancé", "Quels sont mes rendez-vous cette semaine ?", "Comment se passe mon mois ?"), keeping the existing suggested agents. Unit-test the result mapping with bun:test. Take screenshots of the chat home (owner and Marie cookies in ${SCR}) to ${SHOTS}/r4-*.png. If no LLM is configured locally, do not send messages; test rendering with the pure mapping functions.`, { label: 'build:chat-ui', phase: 'Build', schema: RESULT })

phase('Review')
const review = await agent(`${COMMON}

YOUR TASK: independent adversarial review of the new AI assistant real-estate capabilities and FIX real problems directly. Changes: agent tools ${JSON.stringify(tools).slice(0, 5000)} ; chat UI ${JSON.stringify(ui).slice(0, 5000)}.
Lenses: (1) security — can any tool return data from another agency, or a realtor see another realtor's leads? Is the purpose/user guard bypassable (e.g. team agent without user)? Any PII in logs? (2) truthfulness — do tool outputs separate confirmed criteria from suggestions; any invented numbers? (3) French quality of descriptions, instructions and UI; (4) UX — cards link to the fiche, dense and aligned, accessible. Run apps/agent tests you touched, apps/agent and apps/app tsc, apps/app bun test.`, { label: 'review:assistant', phase: 'Review', schema: RESULT })

phase('Journal')
const journal = await agent(`Append to /home/user/ai_engineering/fratex-agent-journal/JOURNAL.md under "Partie B — Phases" a section "B.R4 — L'assistant IA connaît vos prospects" (French, beginner-friendly: quoi, où, comment, pourquoi, sécurité/isolation, exemples de questions, comment tester, limites ; embed screenshots screenshots/apres/r4-*.png that exist). Reports: ${JSON.stringify({ map, tools, ui, review }).slice(0, 25000)}
Then: cd /home/user/endsi3g/fratex-agent && git add -N . && git diff > /home/user/ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch (grep: no secret values), cd /home/user/ai_engineering && git add fratex-agent-journal && git commit -q -m "Reconstruction : assistant IA immobilier + journal" End the commit message with a blank line then these two trailer lines exactly: 'Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>' and 'Claude-Session: https://claude.ai/code/session_01U8L1nhy5ySxz3sKr5iBNFU' (write the message to a temp file and use git commit -F). && git push (branch claude/fratex-agent-rebuild; retry 4x with 2/4/8/16 s). Return commit hash and push result.`, { label: 'journal', phase: 'Journal' })

return { map, tools, ui, review, journal }
