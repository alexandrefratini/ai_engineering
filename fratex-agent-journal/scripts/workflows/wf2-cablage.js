export const meta = {
  name: 'fratex-rebuild-wiring',
  description: 'Wire Fratex Agent pages (shell, leads/inbox, home/portal/estimator/realtors, connections), review in the browser, journal, commit and push',
  phases: [
    { title: 'Wire', detail: '4 app tracks in parallel on disjoint folders' },
    { title: 'Review', detail: 'independent reviewer per track: code + browser screenshots, fixes' },
    { title: 'Journal', detail: 'journal sections with screenshots, patch, commit, push' },
  ],
}

const SPEC = '/home/user/ai_engineering/fratex-agent-journal/REBUILD-SPEC.md'
const REC = '/home/user/ai_engineering/fratex-agent-journal/recovery'
const SCR = '/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad'
const SHOTS = '/home/user/ai_engineering/fratex-agent-journal/screenshots/apres'
const COMMON = `You are rebuilding part of the "Fratex Agent" app after a container reset destroyed all uncommitted work.
Read the rebuild spec first: ${SPEC} (section 0 = rules and environment; follow AGENTS.md rules: NO code comments, UI components live in packages/ui, match surrounding style).
Recovered material: ${REC} (bash/NNNN.sh = exact commands that created/edited files, bash/NNNN.out = outputs, files/ = full components, SUMMARY.txt). When told R:NNNN, read ${REC}/bash/NNNN.sh and reproduce its intent (adapt anchors to the current code).
Foundations, API and packages/ui components were rebuilt by a previous wave; read their actual code before wiring (packages/ui/src/components/*, packages/ui/src/lib/*, apps/api/src/real-estate/*.contracts.ts, apps/api/src/presence/*). If a component is missing something you need, add it in packages/ui ONLY if that file is in your scope; otherwise list it.
Repo: /home/user/endsi3g/fratex-agent. Dev servers already run on :3000 (app) and :3001 (api), Postgres on :5432. NEVER start, stop or restart servers, NEVER run pkill/killall. Do not commit or push in the product repo.
Test sessions: owner cookie ${SCR}/cookie.txt, realtor (Marie) cookie ${SCR}/cookie-marie.txt. Screenshot helper: node ${SCR}/tall.cjs "$(cat ${SCR}/cookie.txt)" <outdir> 1440 900 "name=/crm/path" ... (workspace slug crm). Write your own Playwright flow scripts under ${SCR}/ when you need clicks (require("/opt/node-tools/node_modules/playwright"), executablePath "/opt/pw-browsers/chromium", cookie name crm.session_token on domain localhost).
Other agents edit other folders in parallel: edit ONLY files in your scope; list other needs in your result.
All user-facing text in Quebec French; fr-CA, America/Toronto, CAD. Biome: bunx biome check --write <files> (run it from inside folders whose path contains [slug]).`

const RESULT = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    filesChanged: { type: 'array', items: { type: 'string' } },
    verification: { type: 'string' },
    screenshots: { type: 'array', items: { type: 'string' }, description: 'absolute paths of screenshots taken, with what each shows' },
    outOfScopeNeeds: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['summary', 'filesChanged', 'verification', 'screenshots', 'outOfScopeNeeds', 'issues'],
}

const TRACKS = [
  {
    key: 'shell',
    scope: `YOUR SCOPE: apps/app/components/app-header.tsx, app-breadcrumb.tsx (create), header-search.tsx (create), team-presence-control.tsx (create, R:0250), page-shell.tsx, local-date-time.tsx, app-icon-rail.tsx (final = R:0007 then R:0150, original file content in ${REC}/reads/0003_app-icon-rail.tsx.txt), auth-shell.tsx (R:0171, R:0172), components/crm/quick-switcher.tsx; apps/app/lib/navigation.ts (create), presence-config.ts (create), use-audience.ts (create, R:0150), workspace-label.ts; apps/app/app/layout.tsx (R:0171); apps/app/public/* (favicons + manifest, R:0167, R:0169); tests apps/app/test/navigation.spec.ts, workspace-label.spec.ts, audience.spec.ts.`,
    task: `Build the app shell: TopBar with breadcrumb (AppBreadcrumb: lead id segment shows the lead name, unknown ids "Détail"), central search (HeaderSearch opens the quick switcher; Ctrl/Cmd K), team presence (TeamPresenceControl: heartbeat every minute with { path, label } from presenceLabel; overlapping stack), separator and margin before the user avatar menu. lib/navigation.ts: NAV_PAGES (Accueil, Pipeline, Prospects, Boîte de réception, Portail courtier, Courtiers, Ajouter un courtier, Estimateur et offres, Assistant IA, Contacts, Entreprises, Affaires, Paramètres généraux, Connexions, Membres, Suivi et analyses, Devises, Clés API, SSO — groups Immobilier / CRM / Paramètres, keywords incl. "réglages"), SEGMENT_LABELS (incl. realtors Courtiers, new Nouveau, settings Paramètres, tracking Suivi et analyses, realtor-calendar Google Agenda, meta-ads Meta Lead Ads, twilio SMS Twilio, gemini Assistant IA), HIDDEN_SEGMENTS, normalizeSearch, matchPages, presenceLabel (R:0250). Quick switcher (task 14): a WIDER dialog (max-w-2xl+), richer rows per category (prospects: name, status dot + label, phone, broker, last activity; pages: group + description; records: type + secondary info), keyboard navigation, pages filtered for realtors via useAudience (no staff-only pages), selecting a prospect opens its FICHE (/real-estate/leads/{id}?agencyId=), never the conversation; do not clear the URL state right before router.push. Rail: French labels, distinct icons, group separators, staff-only items hidden for realtors. local-date-time: relative times in French via APP_LOCALE. page-shell: compact paddings. Layout: metadata "%s · Fratex Agent", lang fr-CA, Fratex favicons/manifest. Auth shell: Fratex copy.`,
    check: `Screenshot (owner and Marie): /crm (top bar), open the switcher with Ctrl+K and type "kar" (prospect row), the presence popover, the rail for Marie (no CRM items). Check no console errors.`,
  },
  {
    key: 'leads-inbox',
    scope: `YOUR SCOPE: apps/app/app/(app)/[slug]/real-estate/leads/** (list, [leadId]/page.tsx + lead-detail-view.tsx, new-lead-control.tsx R:0215), real-estate/inbox/**, real-estate/pipeline/**, real-estate/use-leads.ts, real-estate/workspace-config.ts.`,
    task: `Prospects list: clicking a row (or the name) opens the FICHE /real-estate/leads/{id}?agencyId=…, never the conversation; status + intent combined into one indicator (dot + text), compact; "Nouveau prospect" button (R:0215). Fiche page: lead-detail-view composes the lead-profile components in ONE column (header actions: Courtier reassign select when canReassign, Statut select, Appeler tel:, Ouvrir la conversation), key facts, qualification, appointments with create + outcomes, notes, last messages with link to the conversation, suggested listings, follow-up/consent, history, CRM export disclosure for OWNER/ADMIN (R:0206 shows the earlier view, R:0216 the 7b additions). Inbox: unified multichannel view using packages/ui inbox components and the inbox/markRead/byId/sendMessage/setAutomation procedures; ?leadId= opens the thread and marks it read (invalidate with pathFilter so unread counts refresh); "Voir la fiche" goes to the fiche; human takeover / hand back; SMS send with optimistic state and French errors; emails shown in the thread, reply via mailto:. Pipeline: French, card click opens the fiche.`,
    check: `Browser flows (owner): leads list -> click Karim -> fiche (all panels), add an appointment and a note, back; inbox -> open Sophie (unread clears), send a short SMS (it stays "En file" locally: fine), "Voir la fiche"; pipeline card -> fiche; mobile 390px for list, fiche and inbox. Realtor Marie: leads list shows only her leads. No console errors.`,
  },
  {
    key: 'home-portal-tools',
    scope: `YOUR SCOPE: apps/app/app/(app)/[slug]/page.tsx, real-estate-home-view.tsx (create), overview-greeting.tsx, overview-scope.tsx (R:0160), overview-search-params.ts, sales-dashboard.tsx, dashboard-summary.tsx, apps/app/lib/search-param-keys.ts, real-estate/portal/**, real-estate/valuation/**, real-estate/realtors/** (R:0000, R:0037), apps/app/app/(landing)/onboarding/realtor/** (R:0000), apps/app/app/(app)/[slug]/companies/page.tsx (wrap EnrichmentQueue in Suspense), real-estate/page.tsx.`,
    task: `Home: "Bon retour, {prénom}" (server component, no hydration mismatch), toggle Immobilier / Ventes CRM (vue=ventes; hidden for realtors), scope Moi / Toute l'équipe, RealEstateHome fed by the home procedure (click a to-do or appointment -> fiche; click a stage -> leads list filtered), CAD everywhere, sales dashboard translated, no bloom, wider value columns (no clipped amounts). Portal: realtor-portal-dashboard fed by portalStats with period in the URL (30D default), client select for staff, recent lead click -> fiche. Estimator: property-valuation-calculator with a real "Lier à un prospect" (lead select defaulting to the first lead once loaded, suggestListing mutation, success link to the fiche). Realtors list + new realtor pages and the public onboarding page at max-w-3xl (R:0000, R:0035-0037 behavior: done flags from real setup, success actions).`,
    check: `Screenshots (owner): /crm home (check no hydration warning in console), ?vue=ventes, portal 30/90 days + tooltip hover, estimator with a 649 000 $ listing at 10 % down 4,79 % and the lead link to Karim, realtors list, new realtor form + success, /onboarding/realtor; Marie: home without the sales toggle, her portal. Mobile 390px for home and portal.`,
  },
  {
    key: 'connections',
    scope: `YOUR SCOPE: apps/app/app/(app)/[slug]/settings/connections/** (R:0093, R:0094, R:0095, R:0100, R:0102, R:0103, R:0104, R:0111, R:0130; original files in ${REC}/bash/0063.out, 0064.out, 0069.out), apps/app/app/(app)/[slug]/settings/settings-sidebar.tsx (R:0107), apps/app/app/(landing)/agenda-connecte/** (R:0108), apps/app/proxy.ts (remove the research gate: UNGATED = ["/grant-access","/eve","/onboarding/realtor","/onboarding/research"]; ANONYMOUS add "/agenda-connecte"), apps/app/lib/onboarding.ts (remove readResearchGate/RESEARCH_PATH and their use), apps/app/test/onboarding-gate.spec.ts.`,
    task: `Connections page in French with two ConnectionList cards (Chaîne de prospection with real per-agency status and a x/4 meter; Outils de l'équipe), real logos, Google Agenda one-click page with CalendarConnectPanel (copy link for the broker, advanced token entry collapsed), Meta/Twilio/AI pages with ConnectionHeader and field guidance, broker preselected from ?client=, public /agenda-connecte result page, settings sidebar in French. Remove the research gate so /crm opens the home.`,
    check: `Screenshots (owner): /crm (must NOT redirect to /onboarding/research), /crm/settings/connections, realtor-calendar, meta-ads?client=…, twilio, gemini, ?add=1 dialog, /agenda-connecte?statut=ok and ?statut=expired without cookie. No console errors.`,
  },
]

phase('Wire')
const results = await pipeline(
  TRACKS,
  (track) => agent(`${COMMON}\n\n${track.scope}\n\nTASK: ${track.task}\n\nVerify: bunx tsc --noEmit in apps/app (and packages/ui if touched), cd apps/app && bun test, then: ${track.check} Save screenshots to ${SHOTS}/ with descriptive French file names prefixed by "r2-${track.key}-".`, { label: `wire:${track.key}`, phase: 'Wire', schema: RESULT }),
  (built, track) => agent(`${COMMON}\n\n${track.scope}\n\nYOUR TASK: independent review of the "${track.key}" track another agent just wired. Act like a demanding realtor, a Fratex team member and the CEO: open every page of this track in the browser (owner AND Marie, desktop 1440 and mobile 390), click every important control, look at every screenshot you take (Read tool) and FIX in the files of this scope every problem: broken flows, English text, wrong formats, clipped values, misalignment, too much whitespace, too many pills, missing tooltips on important numbers, console errors, hydration warnings, lists that open the conversation instead of the fiche, realtor seeing staff-only things. Re-run tsc and bun test after fixing. Save final screenshots to ${SHOTS}/ prefixed "r2-${track.key}-".\nWirer report: ${JSON.stringify(built).slice(0, 6000)}`, { label: `review:${track.key}`, phase: 'Review', schema: RESULT }).then((review) => ({ track: track.key, built, review })),
)

phase('Journal')
const journal = await agent(`You write the journal section for the wave that just finished and save everything to GitHub.
Journal: /home/user/ai_engineering/fratex-agent-journal/JOURNAL.md (French, for a beginner: quoi, où, comment, pourquoi, logique, comment refaire; tables welcome; reference screenshots with relative paths screenshots/apres/<file>.png and embed 1-2 per section with ![alt](path)). Append under "Partie B — Phases" one section per track: "B.R2.x — <titre>". Base them on these reports (and look at the screenshots they list): ${JSON.stringify(results).slice(0, 30000)}
Also add a short "Problèmes restants" list at the end of the wave section with every unresolved issue/outOfScopeNeed from the reports.
Then save: cd /home/user/endsi3g/fratex-agent && git add -N . && git diff > /home/user/ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch (check with grep that no secret value like BETTER_AUTH_SECRET="..." is in it), then cd /home/user/ai_engineering && git add fratex-agent-journal && git commit -q -m "Reconstruction : câblage des pages + journal" && git push (current branch must be claude/fratex-agent-rebuild; retry 4 times with 2/4/8/16 s on network errors). Return the commit hash and push result.`, { label: 'journal', phase: 'Journal' })

return { results, journal }
