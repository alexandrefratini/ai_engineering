export const meta = {
  name: 'fratex-final-verification',
  description: 'Full verification of the rebuilt Fratex Agent: static checks, multi-lens review with adversarial verification, browser walkthrough, fixes, final journal and push',
  phases: [
    { title: 'Static', detail: 'check-types, lint, tests, build — fix until green' },
    { title: 'Review', detail: '5 lenses over the whole diff' },
    { title: 'Verify', detail: '2 skeptics per finding' },
    { title: 'Fix', detail: 'one fixer per area for confirmed findings' },
    { title: 'Walkthrough', detail: 'every page, owner and realtor, desktop and mobile' },
    { title: 'Journal', detail: 'final journal, issues list, patch, commit, push' },
  ],
}

const SPEC = '/home/user/ai_engineering/fratex-agent-journal/REBUILD-SPEC.md'
const SCR = '/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad'
const SHOTS = '/home/user/ai_engineering/fratex-agent-journal/screenshots/apres'
const COMMON = `Repo: /home/user/endsi3g/fratex-agent ("Fratex Agent", AI SDR for Quebec real-estate brokers; base commit 7fc4914, all work is uncommitted on top). Read ${SPEC} (rules, environment, intended features). Follow AGENTS.md (NO code comments, UI in packages/ui, config constants per area, Zod at boundaries, agency isolation, no PII in logs, optional keys never throw). Dev servers run on :3000/:3001: NEVER start/stop/restart them and NEVER pkill (if a check truly needs a production build, run it in a way that does not touch the dev servers, e.g. a separate output dir or after stopping nothing). Do not commit in the product repo. Owner cookie ${SCR}/cookie.txt, realtor Marie cookie ${SCR}/cookie-marie.txt, screenshot helper ${SCR}/tall.cjs (args: cookie, outdir, width, height, name=/crm/path...). UI text must be Quebec French; fr-CA; CAD; America/Toronto.`

const FINDINGS = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          area: { type: 'string', enum: ['api', 'agent', 'ui-components', 'app-real-estate', 'app-settings-auth', 'app-shell-crm', 'db-validation'] },
          file: { type: 'string' },
          line: { type: 'number' },
          severity: { type: 'string', enum: ['critical', 'major', 'minor'] },
          title: { type: 'string' },
          detail: { type: 'string', description: 'concrete failure scenario' },
        },
        required: ['id', 'area', 'file', 'severity', 'title', 'detail'],
      },
    },
  },
  required: ['findings'],
}
const VERDICT = { type: 'object', properties: { real: { type: 'boolean' }, reason: { type: 'string' } }, required: ['real', 'reason'] }
const RESULT = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    filesChanged: { type: 'array', items: { type: 'string' } },
    verification: { type: 'string' },
    screenshots: { type: 'array', items: { type: 'string' } },
    remaining: { type: 'array', items: { type: 'string' } },
  },
  required: ['summary', 'filesChanged', 'verification', 'screenshots', 'remaining'],
}

phase('Static')
const staticResult = await agent(`${COMMON}

Run the repository's full static checks and tests, and FIX every failure caused by the rebuild (not pre-existing upstream failures — check with git stash only if truly needed; prefer reading the error). Use the scripts in the root package.json/turbo.json (check-types, lint, test) and per-package: apps/app (bunx tsc --noEmit, bun test), packages/ui (bunx tsc --noEmit), apps/api (bunx tsc --noEmit -p tsconfig.json; integration specs with CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts), apps/agent (tsc + specs), packages/validation, packages/auth, packages/db tests. Run bunx biome check on changed files (git status). Report exact final results per package.`, { label: 'static', phase: 'Static', schema: RESULT })

const LENSES = [
  { key: 'correctness', prompt: 'functional bugs: wrong logic, broken flows (a lead list must open the FICHE, not the conversation), wrong data mapping between API and UI, timezone/date bugs, hydration mismatches, race conditions, cache invalidation (pathFilter for infinite queries), nuqs navigation cancellation.' },
  { key: 'security', prompt: 'agency isolation and realtor clientId scoping in every query and mutation (API and agent tools), auth guards, signed OAuth state (calendar), input validation with Zod, secrets or PII in logs, client components importing @crm/auth or @crm/db, open redirects.' },
  { key: 'french', prompt: 'any English left in user-facing UI strings, wrong French (typos, anglicisms, wrong glossary term), en-US or undefined locales, non-CAD currency defaults, inconsistent labels for the same concept across pages (e.g. Paramètres vs Réglages).' },
  { key: 'design', prompt: 'design rules: no neon/bloom, few pills (prefer dot + text), tooltips on important numbers, tabular-nums, aligned columns or one column, compact spacing, REVEAL animations only after mount and reduced-motion safe, accessible names on icon buttons, mobile layout at 390px.' },
  { key: 'rules', prompt: 'AGENTS.md compliance: code comments present, ad hoc complex styles in apps/app instead of packages/ui components, magic constants instead of config files, JSON parsed without Zod, optional env keys that throw, dead code or duplicate components, non-additive migrations.' },
]

phase('Review')
const reviewed = await pipeline(
  LENSES,
  (lens) => agent(`${COMMON}\n\nReview the WHOLE rebuild diff (cd /home/user/endsi3g/fratex-agent && git add -N . && git diff --stat, then read the changed files) through ONE lens: ${lens.prompt}\nReport only concrete, verifiable findings with file and line and a failure scenario. Do not fix anything.`, { label: `review:${lens.key}`, phase: 'Review', schema: FINDINGS }),
  (found, lens) => parallel((found?.findings ?? []).map((f) => () =>
    parallel([0, 1].map((n) => () => agent(`${COMMON}\n\nAdversarially verify this finding from the ${lens.key} review. Read the code; try to REFUTE it. Default to real=false if you cannot confirm a concrete failure. Finding: ${JSON.stringify(f)}`, { label: `verify:${lens.key}:${f.id}:${n}`, phase: 'Verify', schema: VERDICT })))
      .then((votes) => ({ ...f, lens: lens.key, real: votes.filter(Boolean).filter((v) => v.real).length >= 1 && votes.filter(Boolean).filter((v) => v.real).length >= votes.filter(Boolean).length / 2, votes })))),
)
const confirmed = reviewed.flat().filter(Boolean).filter((f) => f.real)
log(`${confirmed.length} confirmed findings out of ${reviewed.flat().filter(Boolean).length}`)

phase('Fix')
const areas = [...new Set(confirmed.map((f) => f.area))]
const fixes = await parallel(areas.map((area) => () => agent(`${COMMON}\n\nFix these CONFIRMED findings in area "${area}" (edit only files of this area; other fixers handle other areas in parallel): ${JSON.stringify(confirmed.filter((f) => f.area === area))}\nAfter fixing, re-run the relevant tsc and tests and report.`, { label: `fix:${area}`, phase: 'Fix', schema: RESULT })))

phase('Walkthrough')
const PAGES = [
  { key: 'immobilier', pages: '/crm (home, both views), /crm/real-estate/leads, a lead fiche, /crm/real-estate/pipeline, /crm/real-estate/inbox (+ ?leadId=), /crm/real-estate/portal, /crm/real-estate/valuation, /crm/real-estate/realtors, /crm/real-estate/realtors/new, /onboarding/realtor' },
  { key: 'parametres', pages: '/crm/settings and every settings sub-page, /crm/settings/connections and each connection page, the add-connection dialog, /agenda-connecte?statut=ok (no cookie), /sign-in (no cookie)' },
  { key: 'crm-assistant', pages: '/crm/contacts, /crm/companies, /crm/deals (open one record sheet each), /crm/chat, /crm/agents, the Ctrl+K switcher, the team presence popover' },
]
const walk = await parallel(PAGES.map((p) => () => agent(`${COMMON}\n\nWalk through these pages as a demanding realtor, a Fratex team member and the CEO: ${p.pages}. For each: owner desktop 1440, owner mobile 390, and realtor Marie desktop where applicable. Read every screenshot. Fix (in the files of these pages only) every visible problem: errors, English, clipped or misaligned content, excessive whitespace, too many pills, missing tooltips on key numbers, broken links (lists must open the fiche), console errors. Save the final screenshots to ${SHOTS}/final-${p.key}-*.png. Re-run apps/app tsc and bun test.`, { label: `walk:${p.key}`, phase: 'Walkthrough', schema: RESULT })))

phase('Journal')
const journal = await agent(`Finalize the journal and save to GitHub.
1. Append to /home/user/ai_engineering/fratex-agent-journal/JOURNAL.md: "B.R5 — Vérification complète" (static results, review lenses, confirmed findings and their fixes, walkthrough with a gallery of final screenshots screenshots/apres/final-*.png) and "Partie C — Comment tout refaire depuis zéro" (step by step: clone, scripts/setup-local.sh, apply patches/TOUT-cumulatif.patch with git apply, start the dev servers, sign in with the demo cookie, where each feature lives, how to run tests) and "Problèmes restants" written in ASD-STE100 simplified technical English style rules but in French (short sentences, one instruction per sentence): each item = problem, impact, fix proposal, owner (Alexandre or technique).
Data: static ${JSON.stringify(staticResult).slice(0, 5000)} confirmed ${JSON.stringify(confirmed).slice(0, 10000)} fixes ${JSON.stringify(fixes).slice(0, 6000)} walkthrough ${JSON.stringify(walk).slice(0, 8000)}
2. Generate patches: cd /home/user/endsi3g/fratex-agent && git add -N . && git diff > /home/user/ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch && git diff --stat > /home/user/ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.stat.txt (grep: no secret values).
3. cd /home/user/ai_engineering && git add fratex-agent-journal && git commit -q -m "Reconstruction : vérification complète, journal final" && git push (branch claude/fratex-agent-rebuild; retry 4x with 2/4/8/16 s). Return commit hash and push result.`, { label: 'journal', phase: 'Journal' })

return { staticResult, confirmedCount: confirmed.length, confirmed, fixes, walk, journal }
