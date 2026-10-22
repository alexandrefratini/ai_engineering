export const meta = {
  name: 'fratex-rebuild-translations',
  description: 'Translate the remaining English UI of Fratex Agent to Quebec French in 3 disjoint scopes, review, journal, commit and push',
  phases: [
    { title: 'Translate', detail: 'settings+auth, AI assistant, CRM+shared UI' },
    { title: 'Review', detail: 'screenshot sweep for leftover English and fixes' },
    { title: 'Journal', detail: 'journal section, patch, commit, push' },
  ],
}

const SCR = '/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad'
const SHOTS = '/home/user/ai_engineering/fratex-agent-journal/screenshots/apres'
const REC = '/home/user/ai_engineering/fratex-agent-journal/recovery'
const COMMON = `You translate the user-facing UI of a Next.js app to Quebec French. Repo: /home/user/endsi3g/fratex-agent (product "Fratex Agent", AI SDR for Quebec real-estate brokers). Follow AGENTS.md (NO code comments, match style).
Translate every user-visible string (headings, descriptions, labels, placeholders, buttons, empty states, errors, toasts, aria-labels, metadata titles, column headers, options, dialogs). Never translate identifiers, enum values, API fields, URLs, env var names, prompts sent to the LLM, or logs not shown to users. Where copy says "the CRM"/"your CRM"/"Comp AI", say "Fratex" (or "Fratex Agent" for the product name).
Glossary: Settings Paramètres · General Général · Workspace Espace de travail · Member Membre · Owner Propriétaire · Admin Administrateur · Viewer Lecteur · Email Courriel · Save Enregistrer · Cancel Annuler · Delete Supprimer · Remove Retirer · Invite Inviter · Connected Connecté · Not connected Non connecté · Connect Connecter · Disconnect Déconnecter · Manage Gérer · API key Clé API · Sign in Se connecter · Sign out Se déconnecter · Search Rechercher · Name Nom · Website Site web · Role Rôle · Joined Membre depuis · You Vous · Currency Devise · Tracking Suivi · Chat Conversation · New chat Nouvelle conversation · Team agents Agents de l'équipe · Deploy Déployer · Draft Brouillon · Run Exécution · Trigger Déclencheur · Tool Outil · Record Fiche · Deal Affaire · Company Entreprise · Contact Contact · Lead Prospect · Realtor Courtier · Appointment Rendez-vous · Owner (of a record) Responsable · Title (job) Poste · Phone Téléphone · Amount Montant · Close date Date de clôture · Last activity Dernière activité · Stage Étape · Filters Filtres · Sort Trier · Columns Colonnes · Views Vues · Archived Archivés · Showing a–b of n → a–b sur n · Previous Précédent · Next Suivant · New contact Nouveau contact · No results Aucun résultat · Loading… Chargement… · Thinking… Réflexion…
Style: sentence case, Quebec French, a space before ":" ; no space before "?" or "!"; straight apostrophes. Replace user-visible en-US / undefined locales with APP_LOCALE from packages/ui/src/lib/format.ts.
Dev servers run on :3000/:3001: NEVER start/stop/restart them, NEVER pkill. Do not commit. Edit ONLY your scope. Other agents are rebuilding other parts of the app at the same time: tsc or test failures in files outside your scope are not yours; ignore them, but make sure the files you edit have no errors. Screenshots: node ${SCR}/tall.cjs "$(cat ${SCR}/cookie.txt)" <outdir> 1440 900 "name=/crm/path" (sign-in needs an empty cookie ""). Verify: bunx biome check --write <files> (run from inside [slug] folders), bunx tsc --noEmit in each touched package, cd apps/app && bun test (update assertions on strings you translated).`

const RESULT = {
  type: 'object',
  properties: {
    summary: { type: 'string' },
    filesChanged: { type: 'array', items: { type: 'string' } },
    verification: { type: 'string' },
    leftoversOutsideScope: { type: 'array', items: { type: 'string' } },
    issues: { type: 'array', items: { type: 'string' } },
  },
  required: ['summary', 'filesChanged', 'verification', 'leftoversOutsideScope', 'issues'],
}

const SCOPES = [
  { key: 'settings-auth', scope: `SCOPE: apps/app/app/(app)/[slug]/settings/** EXCEPT settings-sidebar.tsx and connections/{page.tsx,sdr-connections-overview.tsx,connection-header.tsx,meta-ads-connection.tsx,twilio-connection.tsx,gemini-connection.tsx,add-connection-dialog.tsx,realtor-calendar/**,meta-ads/page.tsx,twilio/page.tsx,gemini/page.tsx} (already French); apps/app/app/(landing)/** EXCEPT onboarding/realtor/** and agenda-connecte/**; packages/auth/src/slack-scopes.ts and slack-connect.ts with their test assertions (exact translations in ${REC}/bash/0228.sh); packages/db/src/tracking.ts cookie labels (13 mois, 6 mois, Session seulement); apps/app/components/slack/channel-picker.tsx (${REC}/bash/0231.sh, 0232.sh); onboarding company placeholder "Ex. : Équipe Tremblay immobilier" (keep DEFAULT_WORKSPACE_NAME unchanged).` },
  { key: 'assistant', scope: `SCOPE: the AI chat / agent builder UI: apps/app/components/agent-builder/**, the chat and agents routes under apps/app/app/(app)/[slug]/(agent-builder)/**, apps/app/components/agent-clarification-composer.tsx, apps/app/lib/agent-tool-display.ts, agent-run-failure.ts, agent-builder.ts (add "/Créer un agent" as an accepted slash label while the model still receives "/Create agent"), apps/app/lib/agent-transcript.ts (VERBS: exact French in ${REC}/bash/0237.sh), and the tests that assert those strings. Replace the 3 generic suggested agents with French real-estate examples the agent's CRM tools can actually do (e.g. "Préparer un résumé du client quand une affaire passe à Visite planifiée", "Signaler chaque lundi les affaires sans activité depuis 14 jours", "Créer une tâche de suivi quand une promesse d'achat est déposée"). Greeting: "Comment puis-je vous aider, {prénom}?".` },
  { key: 'crm-shared', scope: `SCOPE: apps/app/app/(app)/[slug]/{contacts,companies,deals}/**, apps/app/components/crm/** EXCEPT quick-switcher.tsx, apps/app/components/data-table/**, detail-sheet.tsx, enrichment-queue.tsx, apps/app/lib/{enrichment-status,activity-recency,social-links,agent-record,deal-stage,activity-presentation}.ts, and shared packages/ui components still in English (data-table, table-pagination, date-picker, calendar (French month/day names), combobox, attendee-list, questionnaire, dialog/sheet "Close", command, async-action, dot-matrix, message-scroller, reasoning, sortable-list, spinner, suggestion, thinking-indicator, thread-message, skeleton-swap, save-bar, empty states). DO NOT edit these packages/ui files: lead-profile, lead-tools, real-estate-*, realtor-*, inbox, property-valuation-calculator, connection-list, connection-setup, calendar-connect-panel, breadcrumb, search-trigger, team-presence, top-bar, lead-status-badge, pipeline-kanban, crm-export-form, brand-logos/**, logo, lib/real-estate*. Also wrap anything throwing "usePathname outside Suspense" on the companies page if still present.` },
]

phase('Translate')
const results = await pipeline(
  SCOPES,
  (s) => agent(`${COMMON}\n\n${s.scope}\n\nTake screenshots of every page in your scope (desktop) into ${SCR}/tr-${s.key}/ and Read them to confirm no English remains.`, { label: `translate:${s.key}`, phase: 'Translate', schema: RESULT }),
  (built, s) => agent(`${COMMON}\n\n${s.scope}\n\nYOUR TASK: independent sweep for leftover English in this scope after another agent's translation. Open every page/sheet/dialog/menu of the scope in the browser (owner cookie; also Marie ${SCR}/cookie-marie.txt where relevant), grep the scope for capitalized English sentences in JSX text and string props, fix every leftover, check French quality (typos, wrong terms vs glossary, truncation). Re-run tsc and tests. Save 2-3 representative final screenshots to ${SHOTS}/ prefixed "r3-${s.key}-".\nTranslator report: ${JSON.stringify(built).slice(0, 5000)}`, { label: `review:${s.key}`, phase: 'Review', schema: RESULT }).then((review) => ({ scope: s.key, built, review })),
)

phase('Journal')
const journal = await agent(`Write the journal section for the translation wave and save to GitHub.
Append to /home/user/ai_engineering/fratex-agent-journal/JOURNAL.md under "Partie B — Phases" a section "B.R3 — Français partout" (French, beginner-friendly: quoi, où, comment, pourquoi, glossaire utilisé, comment refaire; embed 1-2 screenshots from screenshots/apres/r3-*.png; list remaining English that lives in demo data or server messages as "Problèmes restants"). Reports: ${JSON.stringify(results).slice(0, 25000)}
Then: cd /home/user/endsi3g/fratex-agent && git add -N . && git diff > /home/user/ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch (grep it: no secret values), cd /home/user/ai_engineering && git add fratex-agent-journal && git commit -q -m "Reconstruction : français partout + journal" && git push (branch claude/fratex-agent-rebuild; retry 4x with 2/4/8/16 s). Return commit hash and push result.`, { label: 'journal', phase: 'Journal' })

return { results, journal }
