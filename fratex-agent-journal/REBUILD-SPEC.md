# Fratex Agent — spécification de reconstruction

> Document de travail pour reconstruire tout ce qui a été perdu lors de la réinitialisation du conteneur (22 oct. 2026, ~13 h 50).
> Il sert de brief à chaque agent. Langue des interfaces : français du Québec. Langue de ce document : français, code en anglais.

## 0. Contexte et règles communes

- Produit : **Fratex Agent**, assistant IA (SDR) pour courtiers immobiliers du Québec. Prospects Meta Lead Ads → SMS en moins de 2 minutes → qualification par l'IA → rendez-vous Google Agenda → conversions Meta.
- Dépôt : `/home/user/endsi3g/fratex-agent` (clone en lecture de `Endsi3g/fratex-agent`, commit de base `7fc4914`). Monorepo Bun + Turbo :
  - `apps/app` Next.js 16 (cacheComponents, nuqs, TanStack Query, client tRPC) ;
  - `apps/api` NestJS + nestjs-trpc (routeur généré dans `apps/api/src/generated/server.ts`, régénéré par le serveur de dev) ;
  - `apps/agent` (eve) ; `packages/ui` (shadcn, Tailwind v4, tw-animate-css, recharts, motion, cmdk) ; `packages/db` (Prisma 7, Postgres) ; `packages/auth` (Better Auth, cookie `crm.session_token`) ; `packages/validation` (Zod).
- **Règles du dépôt (AGENTS.md)** : aucun commentaire dans le code ; aucun `Co-Authored-By` ; l'UI vit dans `packages/ui` (les vues de `apps/app` composent, sans styles ad hoc complexes) ; constantes dans un fichier de config par domaine ; JSON validé à la frontière avec Zod ; un composant client n'importe jamais `@crm/auth` ni `@crm/db` ; isolation `agencyId` sur toutes les données métier (et `clientId` pour un courtier) ; une clé facultative absente ne lève jamais d'erreur ; l'« intelligence » vit seulement dans `apps/agent` ; aucune donnée personnelle dans les journaux ; migrations additives avec plan de retour arrière ; une donnée non confirmée par le prospect est une **suggestion**.
- Formats : locale `fr-CA`, fuseau `America/Toronto`, devise **CAD**. Jamais `Intl.*Format(undefined, …)` (bogue d'hydratation « US$0 » vs « 0 $ US »). Les animations ne démarrent qu'après le montage (`useMounted`).
- Design : vert de marque `#006B4F` (token `primary`), sobre, dense, minimaliste. **Pas de néon / bloom.** **Peu de pastilles** : préférer « point coloré + texte ». Une info importante = une infobulle (`InfoHint` « ? » ou `Tooltip`). Chiffres en `tabular-nums`. Animations d'entrée douces (`REVEAL` + `staggerStyle`). Une colonne, ou deux colonnes parfaitement alignées. L'information la plus importante en premier.
- Cache tRPC : invalider avec `trpc.x.pathFilter()` (pas `queryFilter()`) pour les requêtes infinies.
- nuqs : ne pas effacer un paramètre d'URL juste avant `router.push` (la navigation est annulée).
- **Environnement** : Postgres local et serveurs de dev déjà lancés (app `http://localhost:3000`, API `http://localhost:3001`). **Ne jamais** démarrer/arrêter/redémarrer les serveurs ni lancer `pkill`/`killall` (un seul orchestrateur s'en charge). Espace de travail : slug `crm`. Cookie de test (Alexandre, propriétaire) : `/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad/cookie.txt` ; courtière Marie (rôle REALTOR) : `cookie-marie.txt` dans le même dossier.
- Captures : `node <scratchpad>/tall.cjs "$(cat <scratchpad>/cookie.txt)" <dossier> 1440 900 "nom=/crm/chemin" …` (Playwright, Chromium `/opt/pw-browsers/chromium`).
- Vérifications : `bunx biome check --write <fichiers>` (attention : `packages/ui/src/components` est exclu par `biome.jsonc` ; les chemins contenant `[slug]` doivent être passés depuis leur dossier car `[ ]` est interprété comme un motif) ; `bunx tsc --noEmit` dans chaque paquet touché ; tests app : `cd apps/app && bun test` ; tests API : `cd apps/api && CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts <spec>` ; base de test : `bun run db:test` à la racine.
- **Code récupéré** : `/home/user/ai_engineering/fratex-agent-journal/recovery/` — `bash/NNNN.sh` = commande exacte exécutée (contenus de fichiers, scripts Python de modification), `bash/NNNN.out` = sortie, `files/` = 3 composants complets, `SUMMARY.txt` = résumé du travail perdu avant 05 h 45. Quand ce document cite `R:NNNN`, lire `recovery/bash/NNNN.sh`.

## 1. Fondations (déjà nécessaires à tout le reste)

### `packages/ui/src/lib/format.ts`
- `export const APP_LOCALE = "fr-CA";` Remplacer toutes les locales `"en-US"` et `undefined` par `APP_LOCALE`. Devise par défaut `"cad"` ; repli d'un code mal formé : `"CAD"`.

### `packages/ui/src/lib/motion.ts` (nouveau)
- `export const REVEAL = "animate-in fade-in slide-in-from-bottom-1 duration-300 fill-mode-both motion-reduce:animate-none";`
- `export function staggerStyle(index: number): CSSProperties` → `{ animationDelay: \`${Math.min(index, 12) * 40}ms\` }`.

### `packages/ui/src/lib/real-estate.ts` (nouveau)
- `REAL_ESTATE_FORMAT = { locale: "fr-CA", timeZone: "America/Toronto", currency: "CAD" } as const`.
- `formatCad(value: number): string` → « 650 000 $ » (sans décimales).
- `formatBudget(min: number | null, max: number | null): string | null` → « 600 000 $ – 700 000 $ », « Jusqu'à 700 000 $ », « À partir de 600 000 $ », ou `null`.
- `formatDateTime(value: Date | string)` → « 22 oct. 2026, 14 h 00 » (fuseau Toronto) ; `formatDate` → « 22 oct. 2026 » ; `formatTime` → « 14 h 00 ».
- `dayKey(value)` → « 2026-10-22 » dans le fuseau Toronto ; `formatDayHeading(value, now: Date)` → « Aujourd'hui », « Hier » ou « mercredi 21 octobre » ; `formatShortStamp(value, now: Date)` → heure si aujourd'hui, « Hier », sinon « 21 oct. ».
- `formatPhone("+15145550100")` → « (514) 555-0100 » (sinon la valeur brute) ; regex `/^\+1(\d{3})(\d{3})(\d{4})$/`.
- `formatDuration(minutes)` → `< 60` : « 6 min » (min 1) ; `< 48 h` : « 1,5 h » ; sinon « 3 j ».
- `formatPercentValue(ratio)` → « 43 % » ; `formatRate(percent)` → « 4,5 % » (jusqu'à 2 décimales, jamais « 5 % » pour 4,5 ; jamais le symbole ‱).
- Libellés : `INTENT_LABELS` (BUY Achat, SELL Vente, BUY_AND_SELL Achat et vente, RENT Location, INVEST Investissement, UNKNOWN À confirmer) ; `EVENT_LABELS` (LEAD_CREATED Prospect reçu, FIRST_SMS_SENT Premier SMS envoyé, LEAD_REPLIED Réponse du prospect, LEAD_QUALIFIED Prospect qualifié, APPOINTMENT_SCHEDULED Rendez-vous réservé, APPOINTMENT_HELD Rendez-vous réalisé, DEAL_SIGNED Transaction signée) ; `APPOINTMENT_STATUS_LABELS` (SCHEDULED Planifié, CONFIRMED Confirmé, COMPLETED Réalisé, NO_SHOW Absent, CANCELLED Annulé, RESCHEDULED Reporté) ; `MESSAGE_STATUS_LABELS` (RECEIVED Reçu, QUEUED En file, SENDING Envoi…, SENT Envoyé, DELIVERED Livré, FAILED Échec, UNKNOWN Incertain, CANCELLED Annulé, REFUSED Refusé) ; `DELIVERY_STATUS_LABELS` (QUEUED En file, SENT Envoyé, DELIVERED Livré, FAILED Échec, SKIPPED Ignoré) ; `CRM_LABELS` (NONE Aucun, FOLLOW_UP_BOSS Follow Up Boss, KVCORE kvCORE, HUBSPOT HubSpot, OTHER Autre) ; `ESCALATION_LABELS` (HUMAN_TAKEOVER « Le courtier a pris la main », SMS_OPT_OUT « Le prospect ne veut plus de SMS ») ; `LANGUAGE_LABELS` (fr Français, en Anglais).
- `QUALIFICATION_CRITERIA` : 7 critères `{ field, label }` : intent Projet, propertyType Type de propriété, budget Budget (min/max), targetArea Secteur, timeline Échéance, financing Financement, currentSituation Situation actuelle.
- `LEAD_JOURNEY` : NEW Reçu → CONTACTED Contacté → QUALIFYING Qualification → QUALIFIED Qualifié → APPOINTMENT_BOOKED RDV fixé → APPOINTMENT_HELD RDV réalisé. `OFF_JOURNEY_LABELS` : NURTURE À relancer, LOST Non intéressé, INVALID Coordonnées invalides.
- `labelOf(map, key)` → `map[key] ?? key`.
- Ajouts de la phase 7 (récupérés, R:0117 et R:0208) : `TIMEZONE_OPTIONS`, `LEAD_SOURCE_OPTIONS`, `LEAD_SOURCE_LABELS`, `consentSourceLabel`.

### `packages/ui/src/components/lead-status-badge.tsx`
- Garder `LeadStatus`, `LeadStatusBadge`. Ajouter `export const LEAD_STATUS_OPTIONS: { id: LeadStatus; name: string }[]` (Nouveau, Contacté, Qualification, Qualifié, RDV fixé, RDV réalisé, À relancer, Non intéressé, Invalide). LOST utilise la variante `secondary`. Libellés identiques à `LEAD_JOURNEY`/`OFF_JOURNEY_LABELS`.

### `packages/ui/src/components/real-estate-visuals.tsx` (nouveau)
Hook local `useMounted()`. Exports :
- `ScoreRing({ value, label })` : anneau 0–100 (SVG), chiffre au centre, animé après montage.
- `LeadJourney({ steps, current, aside? })` : barre segmentée horizontale (une case par étape, remplie jusqu'à l'étape courante, couleur `primary`), libellés dessous, étape courante en gras ; `aside` affiche un statut hors parcours (ex. « À relancer »).
- `SegmentMeter({ filled, total, label, size? })` : petits segments (`role="img"`, `aria-label`).
- `FunnelRow = { id, label, count, tone?: "neutral" | "won" }` ; `FunnelBars({ rows, total? })` : libellé à gauche, barre proportionnelle, nombre, pourcentage du premier rang ; rangs « won » en vert, autres en gris.
- `Sparkline({ values, label })` : petite courbe aire (SVG) sous une tuile.
- `InfoHint({ label, children })` : bouton « ? » rond avec infobulle (texte explicatif).
- `MetricTile({ label, value, hint?, info?, index?, children? })` et `MetricGrid({ children })` — code exact récupéré dans `recovery/bash/0029.out`.
- `StageIndicator({ position, total, label })`.
- `StageGroup = { id, label, description, tone: "progress" | "won" | "out", stages: { id, label, count }[] }` ; `StageBreakdown({ groups, onSelect })` : une barre proportionnelle à travers toutes les étapes (une étape vide ne prend aucune place ; tons gris / vert / gris clair), puis 3 colonnes alignées (point, nom du groupe, « 3 · 38 % », description, liste des étapes cliquables avec nombre et %).

### `packages/ui/src/components/real-estate-workspace.tsx`
- Garder les exports existants. `WorkspaceLoading` = squelette (pas de texte « Chargement »). `WorkspaceSelect` accepte `compact` (libellé masqué, largeur auto). `WorkspaceToolbar` = `flex flex-wrap items-end gap-3`.

### `apps/app/app/(app)/[slug]/real-estate/use-agency.tsx`
- Un `?agencyId=` vide ou inconnu retombe sur la première agence accessible (valider contre la liste).

## 2. API (`apps/api/src/real-estate`, `apps/api/src/presence`, `packages/db`, `packages/validation`)

Config dans `real-estate-config.ts` (forme finale récupérée en tête de `SUMMARY.txt` + ajouts `calendar` R:0079 et `lead.noteLimit` R:0195).

1. **Fiche** `byId` → `leadDetailOutput` : `lead` (+ `source`), `profile` (language, budgetMin, timeline, financing, currentSituation, escalationReason, consentSource, campaignName, formName, property), `evidence` (citations), `suggestedListings`, `events` (attribution), `emails` (courriels synchronisés par les membres de l'agence seulement), `channels` (canaux connectés), `messages`, `appointments` (+ `description`), `notes`, `deliveries`, `canWrite`, `canReassign`. Code partiel : `recovery/bash/0179.out`, `0190.out`.
2. **Boîte de réception** `inbox` (filtres ALL / UNREAD / HUMAN, recherche, pagination par curseur, compteurs) et `markRead` → `{ cleared }`. Multicanal : SMS + courriels du prospect. Envoi de courriel : impossible (scopes `gmail.readonly` / `Mail.Read`) → lien `mailto:`.
3. **Accueil** `home` (scope Moi / Toute l'équipe) → forme `RealEstateHomeData` de `recovery/files/real-estate-home.tsx`. Fuseau Toronto, tendance 14 jours, 7 jours, rendez-vous 48 h, « À faire » limité à 8 (UNREAD, HUMAN, NOT_CONTACTED).
4. **Suggestion** `suggestListing` : ajoute une propriété aux suggestions **non confirmées** du prospect, une seule fois par lien, sans toucher le budget confirmé.
5. **Portail** `portalStats` : `period` = `30D` | `90D` | `MONTH` ; entonnoir des « étapes atteintes » (Reçus, Contactés, Ont répondu, Qualifiés, Rendez-vous, Rendez-vous réalisés) ; vitesse (médiane, part < 5 min) ; tendance quotidienne ; projets ; sources ; budgets qualifiés ; messages IA / équipe / réponses ; prospects récents (10) ; rendez-vous à venir (5). `projectedCommission` et `beforeFratex` restent `null` (aucune commission hypothétique).
6. **Courtiers** `clients` : + brokerage, licenseNumber, propertyTypes, crmChoice, timezone, lastLeadAt, leadsCount, appointmentsCount, `setup: { metaForm, calendar, sms }`. `createClient` : téléphone normalisé (`northAmericanPhone`, R:0030).
7. `packages/db/src/sdr-messages.ts` : raisons de refus en français ; un envoi met à jour `conversation.lastMessageAt` et `lead.lastInteractedAt`. `packages/db/src/currency.ts` : `DEFAULT_REPORTING_CURRENCY = "CAD"`.
8. **Présence** : module `presence` (contracts, service, router, module, config, enregistrement dans `app.module.ts`), version finale R:0248 ; colonnes `lastSeenAt`, `lastSeenPath`, `lastSeenLabel` (migrations déjà en place).
9. **Google Agenda en un clic** (R:0079–0087) ; **outils du courtier** (R:0194–0202 : createLead, addNote, createAppointment, updateAppointmentStatus, reassignLead) ; `connectionsStatus.calendar`.
10. Tests d'intégration : `real-estate-e2e` (fiche, portail `period: "30D"`), `real-estate-inbox` (boîte, markRead, isolation des courriels, entonnoir, accueil, suggestListing, configuration des courtiers), `presence`, `real-estate-calendar` (R:0085), `real-estate-tools` (R:0202), `packages/validation/test/phone.spec.ts` (R:0034).

## 3. Composants UI (`packages/ui/src/components`)

- `lead-profile.tsx` : fiche en **une colonne** : `LeadProfileHeader`, `LeadKeyFacts`, `LeadQualification` (7 critères, valeur soulignée = citation du prospect au survol, compteur « 1/7 »), `LeadLastMessages`, `LeadAppointments` (version 7b avec issue, R:0208), `LeadSuggestedListings`, `LeadFollowUp`, `LeadHistory`, `LeadDisclosure`, `LeadPanel`. Code partiel : `recovery/bash/0205.out`, `0206.out`, `0207.out`.
- `lead-tools.tsx` (R:0210) : `LeadNotes`, `NewLeadDialog`.
- `inbox.tsx` : boîte unifiée : liste (onglets Tous / Non lus / Reprise humaine avec compteurs, recherche), fil (SMS + courriels fusionnés par date, titres de jour, icône de canal, statut de livraison), compositeur SMS (160 caractères, compteur), entête (nom, lien « Voir la fiche », « Reprendre la main » / « Rendre à l'assistant »). Test `apps/app/test/inbox-thread.spec.tsx`.
- `real-estate-home.tsx` : version exacte récupérée (`recovery/files/`).
- `realtor-portal-dashboard.tsx` : entête courtier (avatar, secteurs, téléphone, courriel cliquables, onglets 30 jours / 90 jours / Ce mois-ci), 4 tuiles (Prospects reçus + courbe, Première réponse médiane + part < 5 min, Rendez-vous obtenus + %, Budgets qualifiés), entonnoir, ligne « Assistant IA : 13 SMS envoyés · Équipe : 2 SMS · Réponses reçues : 7 », Projets et Sources en deux colonnes alignées, prospects récents (clic → fiche), rendez-vous à venir.
- Estimateur : `packages/ui/src/lib/real-estate-finance-config.ts` (toutes les règles, `verifiedAt: "2026-10-22T12:00:00-04:00"`), `packages/ui/src/lib/real-estate-finance.ts` (fonctions pures `minimumDownPayment`, `insurancePremiumPct`, `monthlyPayment`, `welcomeTax`, `commissionWithTaxes`, `analyzeOffer`), `property-valuation-calculator.tsx` (Propriété · Financement · Comparer 3 offres avec rabais modifiables et « ? » par ligne · « Copier le résumé » · Lier à un prospect). Règles : capitalisation semestrielle ; SCHL 4,00 / 3,10 / 2,80 % (+0,20 % sur 30 ans, plafond 1,5 M$) ; mise de fonds minimale 5 % des premiers 500 000 $, 10 % au-delà, 20 % dès 1,5 M$ ; taxe de 9 % sur la prime (payée comptant) ; taxe de bienvenue 2026 (provincial 0,5 / 1 / 1,5 % avec seuils 62 900 $ et 315 000 $ ; Montréal par tranches jusqu'à 4 % au-delà de 3 113 000 $) ; TPS 5 %, TVQ 9,975 %. Valeurs de contrôle (11 tests `apps/app/test/real-estate-finance.spec.ts`) : 400 000 $ à 5 % sur 25 ans ≈ 2 326 $/mois ; taxe de bienvenue de 800 000 $ à Montréal = 11 349 $ ; commission de 4 % sur 500 000 $ = 22 995 $ taxes incluses ; annonce 649 000 $ Montréal, 10 %, 4,79 % → mise de fonds 64 900 $, prime 18 107 $, mensualité 3 431 $, taxe de bienvenue 8 329 $, taxe sur la prime 1 630 $, fonds requis 74 859 $.
- Barre du haut : `breadcrumb.tsx` (`BreadcrumbTrail({ root, crumbs, renderLink })`), `search-trigger.tsx` (« Rechercher une page, un prospect… » + `Ctrl K`), `top-bar.tsx` (gauche : logo + fil d'Ariane ; centre : recherche ; droite : présence, séparateur, marge, avatar), `team-presence.tsx` (version finale R:0251 + R:0259 + R:0263 : pile chevauchée de 3 avatars `size-7`, fond opaque, page de chaque membre, lien vers sa page).
- `realtor-roster.tsx`, `realtor-onboarding-form.tsx` (récupérés), `connection-list.tsx` (R:0092 + R:0111), `calendar-connect-panel.tsx` (R:0099 + R:0117), `connection-setup.tsx` (R:0103 + R:0130), logos réels (R:0088, script Python + paquet npm `simple-icons@13.21.0`), `logo.tsx` (monogramme Fratex, R:0167).
- Localisation et nettoyage : `real-estate-lead-table.tsx`, `pipeline-kanban.tsx`, `crm-export-form.tsx` en français ; `status-indicator.tsx` et `dashboard-chart.tsx` : `bloom` désactivé par défaut.

## 4. Câblage des pages (`apps/app`)

- Barre du haut : `components/app-header.tsx` (utilise `TopBar`), `app-breadcrumb.tsx` (R:0244 en montre le code), `header-search.tsx`, `team-presence-control.tsx` (R:0250), `lib/navigation.ts` (`NAV_PAGES`, `SEGMENT_LABELS`, `HIDDEN_SEGMENTS`, `normalizeSearch`, `matchPages`, `presenceLabel`), `lib/presence-config.ts`, `components/page-shell.tsx` (plus compact), `components/local-date-time.tsx` (temps relatifs en français, `APP_LOCALE`), `components/crm/quick-switcher.tsx` (fenêtre plus large, plus d'informations par catégorie, pages filtrées pour les courtiers), `components/app-icon-rail.tsx` (version finale R:0007 + R:0150), `lib/use-audience.ts` (R:0150), `lib/workspace-label.ts` (`PRODUCT_NAME = "Fratex Agent"`).
- Prospects : liste (clic sur une ligne → **fiche**, jamais la conversation), `leads/[leadId]/page.tsx` + `lead-detail-view.tsx` (R:0206 montre la version avant 7b, R:0216 les ajouts), `leads/new-lead-control.tsx` (R:0215), pipeline.
- Boîte de réception : `inbox/inbox-view.tsx` + `page.tsx` (multicanal ; `?leadId=` ouvre le fil ; « Voir la fiche »).
- Accueil : `app/(app)/[slug]/page.tsx` (bascule Immobilier / Ventes CRM ; la vue Immobilier par défaut), `real-estate-home-view.tsx`, `overview-greeting.tsx` (composant serveur « Bon retour, {prénom} »), `overview-scope.tsx` (Moi / Toute l'équipe + bascule, masquée pour les courtiers R:0160), `overview-search-params.ts` (`vue`), `sales-dashboard.tsx`, `dashboard-summary.tsx` (français, sans bloom, colonnes plus larges).
- Portail, Estimateur, Courtiers (R:0000, R:0035–0037), onboarding courtier (largeur `max-w-3xl`), Connexions (R:0093–0108, R:0116), page publique `/agenda-connecte`, `proxy.ts` (mur « research » retiré, `/agenda-connecte` anonyme), `lib/onboarding.ts`, layout (métadonnées « · Fratex Agent », `lang="fr-CA"`), `auth-shell.tsx`, favicons et manifeste (R:0167–0172), `companies/page.tsx` (`EnrichmentQueue` dans `<Suspense>`), `lib/search-param-keys.ts` (`overview.view = "vue"`).

## 5. Traductions (après le câblage)

Trois périmètres disjoints, comme la première fois : (a) Paramètres + connexion + onboarding générique ; (b) Assistant IA / agents ; (c) écrans CRM (contacts, entreprises, affaires) + composants partagés de `packages/ui`. Plus : `packages/auth/src/slack-*.ts`, `packages/db/src/tracking.ts`, `apps/app/components/slack/channel-picker.tsx`, `apps/app/lib/agent-transcript.ts` (R:0228–0239).

## 6. Vérification finale

`check-types`, lint, tests, build ; parcours navigateur de chaque page (bureau 1440 px et mobile 390 px, propriétaire et courtière) ; aucune erreur console ; journal final avec captures ; liste des problèmes restants.
