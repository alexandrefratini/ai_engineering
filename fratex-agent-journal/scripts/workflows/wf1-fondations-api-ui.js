export const meta = {
  name: 'fratex-rebuild-foundations-api-ui',
  description: 'Rebuild Fratex Agent foundations, API and UI components after container reset, with review and checkpoint',
  phases: [
    { title: 'Foundations', detail: 'shared libs and visuals, then independent check' },
    { title: 'Build', detail: 'API (2 passes) and 4 UI component tracks in parallel' },
    { title: 'Review', detail: 'independent reviewer fixes each track' },
    { title: 'Checkpoint', detail: 'patch, commit and push to ai_engineering branch' },
  ],
}

const SPEC = '/home/user/ai_engineering/fratex-agent-journal/REBUILD-SPEC.md'
const REC = '/home/user/ai_engineering/fratex-agent-journal/recovery'
const COMMON = `You are rebuilding part of the "Fratex Agent" app after a container reset destroyed all uncommitted work.
Read the rebuild spec first: ${SPEC} (section 0 = rules and environment; follow AGENTS.md rules: NO code comments, match surrounding style).
Recovered material: ${REC} (bash/NNNN.sh = exact commands that created/edited files after 05:45, bash/NNNN.out = outputs, files/ = 3 full components, SUMMARY.txt = summary of earlier work). When the spec cites R:NNNN, read ${REC}/bash/NNNN.sh and reproduce its intent (python replace scripts may assume earlier-phase code; adapt them, do not skip the feature).
Repo: /home/user/endsi3g/fratex-agent. Dev servers already run on :3000/:3001 and Postgres on :5432. NEVER start, stop or restart servers, NEVER run pkill/killall. Do not commit or push in the product repo.
Other agents edit other files in parallel: edit ONLY the files in your scope. If you need a change outside your scope, do not make it; list it in your result.
All user-facing text in Quebec French. Locale fr-CA, timezone America/Toronto, currency CAD.`

const RESULT = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    filesChanged: { type: 'array', items: { type: 'string' } },
    verification: { type: 'string', description: 'commands run and their results (tsc, tests, screenshots)' },
    outOfScopeNeeds: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['summary', 'filesChanged', 'verification', 'outOfScopeNeeds', 'issues'],
}

phase('Foundations')
const foundations = await agent(`${COMMON}

YOUR TASK: implement spec section 1 "Fondations" exactly: packages/ui/src/lib/format.ts (APP_LOCALE, CAD), packages/ui/src/lib/motion.ts, packages/ui/src/lib/real-estate.ts (every export listed, including TIMEZONE_OPTIONS, LEAD_SOURCE_OPTIONS, LEAD_SOURCE_LABELS, consentSourceLabel from R:0117 and R:0208), packages/ui/src/components/lead-status-badge.tsx (LEAD_STATUS_OPTIONS), packages/ui/src/components/real-estate-visuals.tsx (all exports; MetricTile/MetricGrid code is in ${REC}/bash/0029.out), packages/ui/src/components/real-estate-workspace.tsx, apps/app/app/(app)/[slug]/real-estate/use-agency.tsx.
Keep every export that already exists in these files (other code imports them). Make the visuals look refined: neutral greys plus the brand primary green, no neon, animate only after mount, respect prefers-reduced-motion, accessible labels.
Verify: cd packages/ui && bunx tsc --noEmit; cd apps/app && bunx tsc --noEmit && bun test. Fix anything you broke.`, { label: 'foundations', phase: 'Foundations', schema: RESULT })

const foundationsCheck = await agent(`${COMMON}

YOUR TASK: independently verify the foundations another agent just built (spec section 1) and FIX any gap directly. Files: packages/ui/src/lib/format.ts, motion.ts, real-estate.ts, components/lead-status-badge.tsx, real-estate-visuals.tsx, real-estate-workspace.tsx, apps/app/app/(app)/[slug]/real-estate/use-agency.tsx.
Check every export named in the spec exists with the specified signature and behavior. Write a quick throwaway bun script in /tmp (not in the repo) that calls the formatters and asserts the exact example outputs from the spec (e.g. formatPhone("+15145550100") === "(514) 555-0100", formatRate(4.5) === "4,5 %", formatDuration(6) === "6 min", formatCad(650000) uses a non-breaking or normal space consistently and ends with " $", formatDateTime uses the Toronto timezone). Check there is no Intl formatter with an undefined locale left in packages/ui/src/lib. Check visuals do not animate before mount and have aria labels.
Then run cd packages/ui && bunx tsc --noEmit and cd apps/app && bunx tsc --noEmit && bun test.
The previous agent reported: ${JSON.stringify(foundations).slice(0, 3000)}`, { label: 'foundations-check', phase: 'Foundations', schema: RESULT })

const TRACKS = [
  {
    key: 'api',
    label: 'api',
    prompt: `YOUR SCOPE: apps/api/src/real-estate/**, apps/api/src/presence/** (new), apps/api/src/app.module.ts (register PresenceModule), apps/api/test/** (real-estate and presence specs), packages/db/src/sdr-messages.ts, packages/db/src/currency.ts, packages/validation/src/real-estate.ts and packages/validation/test/**. Do not edit apps/app or packages/ui. The Prisma schema and migrations are already restored (User.lastSeenAt/lastSeenPath/lastSeenLabel, Lead.source, LeadNote): do not change them.
PASS 1 OF 2 — implement spec section 2 items 1 to 8 and their tests (item 10: real-estate-e2e, real-estate-inbox, presence). Design outputs that a UI can render directly (French-ready values, ISO dates via Date objects as tRPC does, nullable fields explicit). Keep existing procedures backward compatible. Enforce agency isolation and realtor (clientId) scoping in every new query; emails in the lead detail must only include messages synced by members of that agency. The presence team list must only include members of the requester's organizations (final version: R:0248; read ${REC}/bash/0243.out for the original service code and ${REC}/bash/0248.sh for the final change).
The nestjs-trpc watcher regenerates apps/api/src/generated/server.ts automatically when routers change; wait a few seconds and check it contains your procedures; never hand-edit it.
Verify: cd apps/api && bunx tsc --noEmit -p tsconfig.json; run the integration specs you wrote plus existing real-estate specs (CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts <spec>); cd packages/validation && bun test.`,
    second: `YOUR SCOPE: same as pass 1 (apps/api/src/real-estate/**, apps/api/test/**, packages/validation/**).
PASS 2 OF 2 — the first pass implemented spec section 2 items 1 to 8. Now implement items 6 (createClient phone normalization, R:0030 and its test R:0034; listClients fields if missing) and 9 exactly as recovered: Google Calendar one-click connection (R:0079, R:0080, R:0082 controller registered in the real-estate module, R:0085 tests, R:0087 role fix MARKETER) and realtor tools (R:0194 contracts, R:0195 service incl. REAL_ESTATE.lead.noteLimit, R:0197 router, R:0202 tests), and connectionsStatus.calendar { oauthAvailable, connected, total }. Read each recovered script and its .out to see the final state; adapt anchors to the current code. Make sure getLead returns notes, source, canReassign and appointment descriptions.
Verify: cd apps/api && bunx tsc --noEmit -p tsconfig.json; run ALL real-estate and presence integration specs (e2e, inbox, presence, calendar, tools) and packages/validation tests; all must pass.`,
  },
  {
    key: 'ui-fiche',
    label: 'ui-fiche',
    prompt: `YOUR SCOPE: packages/ui/src/components/lead-profile.tsx (create; the old lead-conversation-thread.tsx may be deleted only if nothing else imports it — otherwise leave it) and packages/ui/src/components/lead-tools.tsx (create, exact recovered code R:0210).
Build the lead "fiche" components from spec section 3: one column; exports LeadPanel, LeadProfileHeader, LeadKeyFacts, LeadQualification, LeadLastMessages, LeadAppointments (7b version with outcomes, R:0208), LeadSuggestedListings, LeadFollowUp, LeadHistory, LeadDisclosure, plus the exported types (LeadProfileLead incl. source, LeadProfileEvidence, LeadProfileListing, LeadProfileEvent, LeadProfileAppointment incl. description, LeadProfileMessage, AppointmentOutcome, NewAppointment). The recovered outputs ${REC}/bash/0205.out (lines 1-240), 0206.out (old appointments panel + the app view that consumes these components), 0207.out (follow-up panel) show the exact earlier code; reproduce it and design the missing panels in the same style (qualification: 7 criteria in a 4-column grid, value underlined when backed by a prospect quote shown on hover via SourcedValue, meter "1/7"; last messages: last 3 SMS with sender label and status, link slot to the conversation; suggested listings: unconfirmed suggestions with address, price, rooms, external link; history: attribution events timeline with EVENT_LABELS; disclosure: collapsible section).
Use the foundations (real-estate-visuals, lib/real-estate, motion, lead-status-badge). Fewer pills: status + intent can be badges in the header only; elsewhere use dot + text.
Verify: cd packages/ui && bunx tsc --noEmit.`,
  },
  {
    key: 'ui-inbox',
    label: 'ui-inbox',
    prompt: `YOUR SCOPE: packages/ui/src/components/inbox.tsx (create) and apps/app/test/inbox-thread.spec.tsx (create). You may delete packages/ui/src/components/lead-conversation-thread.tsx and apps/app/test/lead-conversation-thread.spec.tsx ONLY at the very end and ONLY if nothing in apps/ or packages/ imports lead-conversation-thread anymore (another agent is building lead-profile.tsx; the inbox and fiche views will be rewired later) — otherwise leave them.
Build the unified multichannel inbox components from spec section 3: list (tabs Tous / Non lus / Reprise humaine with counts, search, row = name, channel icon, last message preview, short stamp via formatShortStamp, unread dot, human-takeover marker), thread (SMS messages and emails merged chronologically with day headings via formatDayHeading, sender labels Prospect / Assistant IA / Courtier / Système, delivery status for outbound, emails rendered as a compact card with subject + snippet + "Ouvrir dans Gmail" link when webLink exists), composer (SMS, 160-character counter, disabled with a French reason when consent is missing or the lead unsubscribed, email via mailto: link), header (lead name, phone tel: link, "Voir la fiche" link slot, take over / hand back to the assistant button slot). Export pure helpers that the test can cover (e.g. mergeThread(messages, emails) and groupByDay) and props types. Keep it dense, aligned and accessible; mobile: list and thread stack.
Write apps/app/test/inbox-thread.spec.tsx with bun:test covering the pure helpers (ordering, day grouping in the Toronto timezone, email + SMS merge).
Verify: cd packages/ui && bunx tsc --noEmit; cd apps/app && bun test test/inbox-thread.spec.tsx.`,
  },
  {
    key: 'ui-portal-estimator',
    label: 'ui-portal-estimator',
    prompt: `YOUR SCOPE: packages/ui/src/components/realtor-portal-dashboard.tsx (rewrite), packages/ui/src/lib/real-estate-finance-config.ts (create), packages/ui/src/lib/real-estate-finance.ts (create), packages/ui/src/components/property-valuation-calculator.tsx (rewrite), apps/app/test/real-estate-finance.spec.ts (create, 11 tests with the control values in the spec).
Portal: build the dense broker portal described in spec section 3 (period tabs 30D/90D/MONTH, 4 metric tiles with InfoHint explanations, funnel via FunnelBars, AI/team/replies line, intents and sources side by side with aligned rows, recent leads list where a click calls onOpenLead(leadId), upcoming appointments). Avatar initials must ignore text after a comma ("Marie Tremblay, courtière" -> "MT"). Define the props type the component needs (stats object) so the app can map the API output to it.
Estimator: pure functions + config per the spec (Canadian semi-annual compounding: monthly rate = (1 + r/2)^(2/12) - 1; CMHC premium on the insured loan, added to the loan; Quebec 9% tax on the premium paid in cash; welcome tax 2026 brackets provincial and Montreal; GST 5% + QST 9.975% on commission). The calculator UI: sections Propriété, Financement, Comparer les offres (3 offers with editable discounts, aligned table, a "?" explanation per row, red warning when down payment is under the minimum), "Copier le résumé", and a "Lier à un prospect" slot (prop) where the app will pass a lead select + action. No invented market value. Show "Barème vérifié le 22 oct. 2026 — à confirmer auprès de la municipalité" for the welcome tax.
Verify: cd packages/ui && bunx tsc --noEmit; cd apps/app && bun test test/real-estate-finance.spec.ts (all 11 control values must match within 1 $).`,
  },
  {
    key: 'ui-shell',
    label: 'ui-shell',
    prompt: `YOUR SCOPE (packages/ui only): components/breadcrumb.tsx (create: BreadcrumbTrail({ root, crumbs, renderLink })), components/search-trigger.tsx (create), components/top-bar.tsx (create), components/team-presence.tsx (create, final version = R:0251 then the edits of R:0252, R:0259, R:0263), components/real-estate-home.tsx (write exactly ${REC}/files/real-estate-home.tsx), components/realtor-roster.tsx (exactly ${REC}/files/realtor-roster.tsx plus the RealtorRosterSummary and initials change of R:0037), components/realtor-onboarding-form.tsx (exactly ${REC}/files/realtor-onboarding-form.tsx plus the changes of R:0035, R:0036, R:0117), components/connection-list.tsx (R:0092 then R:0111), components/calendar-connect-panel.tsx (R:0099 then R:0117), components/connection-setup.tsx (edits of R:0103 and R:0130), components/brand-logos/* (real logos: run the R:0088 approach — npm pack simple-icons@13.21.0 into a temp dir outside the repo, generate meta.tsx, twilio.tsx, gemini.tsx with useId gradient, google-calendar.tsx with the 8 colored parts + white rect of R:0088 and the later edit adding the rect), components/logo.tsx (Fratex monogram, R:0167), and localization/cleanup of components/real-estate-lead-table.tsx, pipeline-kanban.tsx, crm-export-form.tsx (French, fr-CA, CAD), status-indicator.tsx and dashboard-chart.tsx (bloom off by default).
Top bar: left = logo (text-primary) + breadcrumb slot; center = search trigger ("Rechercher une page, un prospect…", Ctrl K kbd hint, wide); right = presence slot, a vertical separator, then margin, then the user menu slot. Compact height (h-12), aligned, responsive (search becomes an icon button on mobile).
Verify: cd packages/ui && bunx tsc --noEmit.`,
  },
]

phase('Build')
const tracks = await pipeline(
  TRACKS,
  async (track) => {
    const first = await agent(`${COMMON}\n\n${track.prompt}`, { label: `build:${track.label}`, phase: 'Build', schema: RESULT })
    if (!track.second) return { track: track.key, results: [first] }
    const second = await agent(`${COMMON}\n\n${track.second}\n\nPass 1 reported: ${JSON.stringify(first).slice(0, 4000)}`, { label: `build:${track.label}-2`, phase: 'Build', schema: RESULT })
    return { track: track.key, results: [first, second] }
  },
  async (built, track) => {
    const review = await agent(`${COMMON}

YOUR TASK: independent review of the "${track.key}" track another agent just built. Scope = the same files as that track:
${track.prompt.split('\n')[0]}
${track.second ? track.second.split('\n')[0] : ''}
Review against the spec (sections 0, and the section for this track) with four lenses: (1) correctness and completeness vs the spec and the recovered code; (2) security: agency/realtor isolation, no PII in logs, input validated with Zod at the boundary, optional keys never throw; (3) Quebec French copy, fr-CA formatting, no English left in UI strings; (4) design rules: no neon, few pills, dot+text indicators, tooltips on important numbers, tabular-nums, REVEAL animations after mount, alignment, mobile.
FIX every real problem you find directly in those files (do not just report). Then re-run the verification commands of the track (tsc and the relevant tests) and report.
Builder report(s): ${JSON.stringify(built).slice(0, 6000)}`, { label: `review:${track.label}`, phase: 'Review', schema: RESULT })
    return { ...built, review }
  },
)

phase('Checkpoint')
const checkpoint = await agent(`You save the current rebuild progress so a container reset cannot destroy it.
Run exactly (bash):
cd /home/user/endsi3g/fratex-agent && git add -N . && mkdir -p /home/user/ai_engineering/fratex-agent-journal/patches && git diff > /home/user/ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch && git diff --stat | tail -1
Then make sure the patch does not contain secrets: grep -nE 'BETTER_AUTH_SECRET="[^"]+"|^\\+.*(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,})' on it must print nothing (the .env file is gitignored, so it should not be in the diff; if it is, regenerate the patch excluding it).
Then: cd /home/user/ai_engineering && git add fratex-agent-journal && git commit -q -m "Reconstruction : fondations, API et composants UI" && git push (retry up to 4 times with 2s, 4s, 8s, 16s waits on network failure). Never push to main; the current branch must be claude/fratex-agent-rebuild.
Return the diff stat line and the push result.`, { label: 'checkpoint', phase: 'Checkpoint' })

return { foundations, foundationsCheck, tracks, checkpoint }
