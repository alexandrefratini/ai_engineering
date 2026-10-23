# Journal de travail — Fratex Agent

> Pour qui : Alexandre (et toute personne qui débute). Chaque étape dit **quoi**, **où**, **comment**, **pourquoi**, la **logique**, et **comment refaire**.
> Dépôt du produit : `Endsi3g/fratex-agent` (lecture seule depuis cette session). Ce journal, les scripts et les patchs vivent dans `alexandrefratini/ai_engineering`, branche `claude/fratex-agent-rebuild`.

## Sommaire

- Partie 0 — Incident du 22 octobre et méthode de reconstruction
- Partie A — Compréhension du produit, règles, décisions
- Partie B — Phases (B.1 à B.17)
- Partie C — Comment tout refaire depuis zéro
- Partie D — Problèmes restants
- Partie E — À faire plus tard (réseaux sociaux)
- Documents liés : `guide/index.html` (guide navigable avec captures), `ETUDE-AGENTS-IA.md` (étude des agents IA et du mobile), `REBUILD-SPEC.md` (spécification de la reconstruction)

---

## Partie 0 — Incident du 22 octobre 2026 et méthode de reconstruction

### Ce qui s'est passé
Vers 13 h 50, le conteneur de la session a été **réinitialisé**. Tout ce qui n'était pas sur GitHub a disparu :
- le clone local de `fratex-agent` avec **tout le code modifié** (environ 90 fichiers et 6 700 lignes) ;
- la base de données locale et ses données de démo ;
- ce journal, les patchs et les captures d'écran.

### Pourquoi c'est arrivé (ma responsabilité)
- Le dépôt `Endsi3g/fratex-agent` refuse l'écriture depuis cette session : je ne pouvais pas y pousser le code.
- Je produisais des patchs, mais je les gardais **dans le conteneur**. Je ne les ai pas poussés sur un dépôt accessible en écriture. Un conteneur de session est temporaire : c'était une erreur.

### Ce qui change dès maintenant
- **À la fin de chaque phase** : section du journal + patch cumulatif (`patches/TOUT-cumulatif.patch`) + commit + **push** sur la branche `claude/fratex-agent-rebuild`. Jamais sur `main`.
- Le patch est produit avec `git diff --binary`. Sans `--binary`, les icônes (fichiers binaires) empêchent `git apply` de fonctionner. J'ai découvert ce défaut en vérifiant le patch sur une copie propre du commit de base. Il est corrigé.
- Les éléments récupérés sont dans `recovery/` (voir son `README.md`).

### Ce qui a pu être récupéré
| Élément | Récupéré ? | Source |
|---------|-----------|--------|
| Travail fait **après** 05 h 45 (courtiers, connexions, Google Agenda, barre latérale, logos, outils du courtier, présence) | Oui, mot pour mot | Transcription de la session (`recovery/bash/`) |
| Trois composants complets (`real-estate-home.tsx`, `realtor-roster.tsx`, `realtor-onboarding-form.tsx`) | Oui | Contexte de la session (`recovery/files/`) |
| Travail fait **avant** 05 h 45 (accueil, boîte de réception, barre du haut, portail, estimateur…) | Seulement son **résumé** détaillé, donc réécrit | `recovery/SUMMARY.txt` + `REBUILD-SPEC.md` |
| Traductions (≈ 140 fichiers) | Non, refaites | Phase B.3 |

### Méthode de reconstruction
1. **Environnement** : Postgres local, dépendances, migrations, données de démo (`scripts/demo-seed.ts`), script `scripts/setup-local.sh`.
2. **Spécification** : `REBUILD-SPEC.md` décrit chaque élément perdu (formats, composants, API, pages).
3. **Exécution** : d'abord par vagues d'agents en parallèle (fondations, câblage, traductions, assistant IA, vérification), puis, à la demande d'Alexandre (« trop lourd en jetons »), **directement, un travail à la fois, sans agents**.
4. Après chaque phase : journal, patch, commit, push.

---

## Partie A — Compréhension du produit, règles, décisions

### Le produit en une phrase
Fratex Agent est un **assistant IA (SDR) pour courtiers immobiliers du Québec** : un prospect remplit un formulaire Meta, reçoit un SMS en moins de 2 minutes, l'IA le qualifie, réserve un rendez-vous dans l'agenda Google du courtier, et renvoie les conversions à Meta.

### Règles du dépôt (AGENTS.md) appliquées partout
Aucun commentaire dans le code · interface dans `packages/ui` · constantes dans un fichier de configuration par domaine · JSON validé à la frontière (Zod) · isolation par agence (`agencyId`) et par courtier (`clientId`) · une clé facultative absente ne fait jamais planter · l'intelligence vit dans `apps/agent` · aucune donnée personnelle dans les journaux · migrations additives avec retour arrière · une donnée non confirmée par le prospect reste une **suggestion**.

### Décisions
| # | Décision | Raison |
|---|----------|--------|
| D1 | Aucun `Co-Authored-By` dans les commits du **produit**. Les commits du journal ont les deux lignes d'attribution demandées par l'environnement. | Règle du dépôt (AGENTS.md) pour le produit. |
| D3 | Les écrans du CRM générique (Contacts, Entreprises, Affaires, Assistant IA) ne sont **pas supprimés**. Ils sont masqués de la barre latérale pour les rôles courtier. | AGENTS.md : ne pas supprimer de fonctionnalité. |
| D4 | **Couleur de marque : rouge-orangé `#D83C16`** (avant : vert `#006B4F`, puis rouge `#D92D20`). Le **vert est réservé aux états entièrement réussis** (connecté, livré, confirmé, 100 % terminé). Tout le reste est rouge ou gris. | Demandes d'Alexandre. Le blanc sur `#D83C16` donne un contraste de 4,6 pour 1, lisible. Le rouge « destructif » reste plus sombre (`#ae2e24`). Une action destructive ne repose jamais sur la couleur seule. |
| D5 | Estimateur : arithmétique réelle seulement. Aucune valeur de marché inventée. | Centris n'offre pas d'API publique ; aucune estimation sans source. |
| D6 | Portail : métriques calculées uniquement depuis les données enregistrées. | « Aucune commission hypothétique ne constitue un résultat. » |
| D7 | Devise de rapport par défaut : CAD (code **et** données de démonstration). | Fratex est au Québec. |
| D8 | Journal et patchs poussés après chaque phase. | Incident du 22 octobre. Autorisé par Alexandre. |
| D9 | Peu de pastilles : un point de couleur et du texte. | Demande d'Alexandre (lisibilité, densité). |
| D10 | Coordonnées (téléphone, courriel) **cliquables partout** (`ContactLink`). | Demande d'Alexandre. |
| D11 | Support : les demandes sont **stockées** dans la base (table `supportRequest`) et visibles des propriétaires et administrateurs. Aucun courriel n'est envoyé automatiquement. | Aucune infrastructure de courriel sortant dans le produit. Voir problème P4. |
| D12 | Traduction Google : **opt-in** avec confirmation, parce que le texte affiché (noms, messages de prospects) est envoyé à Google. | Protection des renseignements personnels (loi 25). |
| D13 | Typographie québécoise : pas d'espace avant `?` et `!`. | Glossaire de la phase de traduction. |
| D14 | L'agent démarre hors ligne grâce à `modelContextWindowTokens` explicite. | Sans cela, eve cherche la taille de contexte dans AI Gateway et refuse de compiler. |

---

## Partie B — Phases

Chaque phase : **Quoi** · **Où** · **Comment** · **Pourquoi** · **Vérifié**.

### B.1 — Fondations, API et composants d'interface (vague 1)
- **Quoi** : bibliothèques de format (fr-CA, CAD, fuseau de Toronto), animations, règles immobilières, composants de visualisation (indicateurs, barres segmentées, courbe, score), API de la fiche, de la boîte de réception, de l'accueil, du portail, des courtiers, de la présence, outils du courtier (créer un prospect, noter, rendez-vous, réaffecter).
- **Où** : `packages/ui/src/lib`, `packages/ui/src/components`, `apps/api/src/real-estate`, `apps/api/src/presence`, `packages/db`, `packages/validation`.
- **Comment** : suivre `REBUILD-SPEC.md`, un composant par fichier, Zod aux frontières, isolation par agence et par courtier dans chaque requête.
- **Pourquoi** : tout le reste en dépend. Les chiffres viennent des données enregistrées.
- **Vérifié** : tests d'intégration de l'API (fiche, portail, boîte de réception, présence, calendrier, outils).

### B.2 — Câblage des pages (vague 2)
- **Quoi** : accueil (Immobilier ou Ventes CRM, Moi ou Toute l'équipe), prospects, fiche, pipeline, boîte de réception, portail, estimateur, courtiers, ajout de courtier, connexions, barre du haut (fil d'Ariane, recherche Ctrl+K, présence).
- **Règle clé** : un clic sur un prospect ouvre **la fiche**, jamais directement la conversation.
- **Où** : `apps/app/app/(app)/[slug]/real-estate/*`, `apps/app/components`.
- **Vérifié** : parcours navigateur de chaque page (voir `guide/`).

### B.3 — Français partout (vague 3)
- **Quoi** : toute l'interface en français du Québec, formats `fr-CA`, glossaire fixe (Paramètres, Courtier, Prospect, Rendez-vous, Courriel…).
- **Comment** : trois périmètres disjoints (paramètres et connexion, assistant IA, CRM et composants partagés), puis une relecture.
- **Pourquoi** : une seule langue dans toute l'application.
- **Reste** : les messages d'erreur de l'API sont encore en anglais (P5).

### B.4 — L'assistant IA connaît vos prospects
- **Quoi** : cinq outils en lecture seule (`list_prospects_needing_attention`, `search_prospects`, `read_prospect`, `list_appointments`, `realtor_performance`) et des **cartes** dans le chat (prospects, fiche, rendez-vous, performance), des questions rapides, des liens de fiche préfixés par l'espace de travail.
- **Où** : `apps/agent/agent/tools`, `apps/agent/agent/skills/broker-assistant.md`, `packages/ui/src/components/assistant-result-cards.tsx`, `apps/app/components/agent-builder`.
- **Sécurité** : chaque outil limite les données à l'agence et, pour un courtier, à ses propres prospects.
- **Vérifié** : tests d'intégration et **essai de bout en bout** (B.13) avec les captures `screenshots/ia/`.

### B.5 — Vérification complète
- La grande revue par agents (cinq angles, contre-vérification) était prévue. Alexandre a demandé d'arrêter les agents : elle n'a **pas** été faite sous cette forme.
- Elle est remplacée par des vérifications directes, faites à la fin de chaque phase B.7 à B.14 : types, tests de chaque paquet, Biome, compilation de production, parcours navigateur avec captures (bureau, mobile, courtière), relecture des captures une par une.
- Résultats chiffrés : partie C, étape 6.

### B.6 — Aperçu et retours d'Alexandre
- **Quoi** : galerie d'aperçu (`screenshots/apercu.html`) livrée à Alexandre. Retours : accent rouge, coordonnées cliquables, retour sur la page d'ajout d'un courtier, mobile à revoir, boîte de réception multicanal, étude des agents, guide complet, journal à jour.

### B.7 — Rouge-orangé, contacts cliquables, retour d'onboarding
- **Quoi** : accent `#D83C16`, vert réservé aux succès complets, `ContactLink` (téléphone `tel:`, courriel `mailto:`) dans les tableaux, le pipeline, la fiche, la boîte de réception, le portail et les listes de courtiers, barre de retour sur la page d'ajout d'un courtier, icônes de l'application régénérées dans la nouvelle couleur.
- **Où** : `packages/ui/src/styles/globals.css`, `packages/ui/src/components/contact-link.tsx`, `apps/app/public/*`, `docs/design.md`.
- **Pourquoi** : visibilité de la marque, rapidité pour joindre un prospect, aucun cul-de-sac.
- **Piège** : `ContactLink` a un gestionnaire de clic ; il doit être un composant client (`"use client"`) pour être utilisé dans des pages serveur.

### B.8 — Infobulles et états vides
- **Infobulles** : texte d'aide pour chaque page importante (`apps/app/lib/page-help.ts`) et chaque section (prop `info` des panneaux).
- **États vides** : composant `EmptyState` (icône, titre, explication, action). Utilisé pour les prospects (vide et filtré), le pipeline, les courtiers, la boîte de réception, la fiche, l'accueil, le portail, les clés API et le SSO.
- **Pourquoi** : une page vide doit dire quoi faire ensuite.

### B.9 — Corrections de la liste (7) et pages non revues
| # | Problème | Cause | Correction |
|---|----------|-------|------------|
| 1 | Erreur React « deux clés identiques » dans la boîte de réception | `InboxThread` et `InboxComposer` avaient la même clé `lead.id` | Clés `thread:` et `composer:` |
| 2 | Titre mobile de l'accueil écrasé | Boutons dans la même grille que le titre | Boutons sous le titre sur mobile |
| 3 | Initiales de présence qui se chevauchent | Avatars trop petits et chevauchement trop grand | Avatars de 32 px, chevauchement de 4 px, initiales de 11 px |
| 4 | Portail : « Non précisée 100 % » | Source déduite seulement de l'identifiant Meta | Un prospect lié à une campagne ou à un formulaire Meta est un prospect Meta |
| 5 | Valeurs de la fiche non soulignées | Aucune citation dans les données de démonstration | `scripts/demo-evidence.ts` |
| 6 | Chat : cartes et liens | Cartes déjà faites ; liens sans l'espace de travail | Vérifié : liens `/crm/real-estate/leads/…` |
| 7 | CRM de démonstration en anglais | Données du dépôt | `scripts/demo-fr.ts` (industries, postes, activités, champs, équipe, **devise CAD**) |
- **Pages revues ensuite** : Suivi, Devises (la devise de présentation était en dollars américains : corrigée), Clés API et SSO (états vides), Slack, recherche Ctrl+K, présence, connexions.
- **Découverte** : la page `chat/preview-results` (maquette ajoutée par erreur) **cassait la compilation de production**. Elle a été supprimée.

### B.10 — Support et Mon compte
- **Support** : trois choix en un clic (problème, question, idée), page préremplie, un seul champ obligatoire, suivi « Mes demandes », vue d'équipe pour propriétaires et administrateurs.
- **API** : module `support` (`create`, `mine`, `team`, `setStatus`), table `supportRequest` (migration **additive** `20261022210000_add_support_requests`), limite de 10 demandes par heure, 4 tests d'intégration.
- **Mon compte** : profil modifiable, agences et rôles, connexion et courriel (lecture seule), appareils connectés (déconnexion), thème, raccourcis, aide, déconnexion.
- **Barre latérale** : Mon compte, Support et Paramètres **en bas, sous un séparateur**, Paramètres tout en bas. Menu du compte : « Signaler un problème ».
- **Où** : `apps/api/src/support`, `packages/ui/src/components/support-*.tsx`, `account-panel.tsx`, `session-list.tsx`, `apps/app/app/(app)/[slug]/{support,account}`.

### B.11 — Google Traduction
- **Quoi** : bouton globe dans la barre du haut, neuf langues, confirmation avant la première traduction, cookie `googtrans`, retour au français en un clic.
- **Comment** : le script du site « Google Website Translator » est chargé seulement quand une langue est active. Des garde-fous DOM évitent les plantages de React quand Google modifie la page. Les téléphones et courriels ont `translate="no"`.
- **Limites** : ce que la traduction envoie à Google (confirmation obligatoire) ; les chiffres qui se mettent à jour seuls peuvent rester figés.
- **Vérifié** : menu, confirmation, cookie, chargement du script. La vérification de la traduction elle-même est reprise en B.16 (correction : elle n'était pas faite à ce stade).

### B.12 — Boîte de réception multicanal et mobile
- **Quoi** : barre « Contacter » : Appeler (`tel:`), SMS (place le curseur dans la zone SMS), Courriel (`mailto:`), WhatsApp (`wa.me`), Messenger (pour les prospects venus de Meta). Mobile : tableau des prospects sans colonne inutile, pipeline avec glissement par colonne, boutons de contact sur une seule ligne.
- **Honnêteté** : seuls les SMS envoyés dans Fratex sont enregistrés. Les autres canaux s'ouvrent dans leur application.
- **Où** : `packages/ui/src/components/contact-channels.tsx`, `packages/ui/src/lib/contact-channels.ts`, champ `fromMeta` de l'API.
- **Vérifié** : test des liens, captures desktop et mobile.

### B.13 — Étude des agents IA et essai de bout en bout
- **Quoi** : `ETUDE-AGENTS-IA.md` (état vérifié, lacunes, protocole de messages entre agents, suivi des résultats et du contenu généré, mobile) ; faux serveur compatible OpenAI (`scripts/mock-llm.ts`) ; script de lancement local (`scripts/run-agent-local.sh`).
- **Résultat vérifié** : le chat de l'application → pont → agent → faux modèle → outil → base → cartes fonctionne. La qualification SMS d'un prospect fonctionne jusqu'à la mise en file du SMS.
- **Correction dans le code** : `modelContextWindowTokens` dans `agent.ts` et les deux sous-agents.
- **Limite** : un faux modèle valide la tuyauterie, pas le jugement.

### B.14 — Guide navigable
- **Quoi** : `guide/index.html` (menu latéral, filtre, 40 pages décrites, 59 captures, agrandissement au clic, mode sombre et mobile), sections : démarrer, immobilier, assistant IA, CRM général, paramètres, compte et aide, partout dans l'application, annexes.
- **Comment refaire** : voir la partie C, étape 9.

### B.15 — Mêmes tailles et mêmes espacements partout, Mon compte en une colonne
- **Problème** : chaque page espaçait ses cartes à sa façon (écarts, marges internes, hauteurs de tuiles), d'où l'impression de disparité.
- **Quoi** : un seul système de mise en page. `LAYOUT` (`packages/ui/src/lib/layout.ts`) fixe les écarts (`gap-4` sur mobile, `gap-5` dès `md`), la marge interne des cartes (`p-4`, `p-5` dès `md`), la hauteur minimale des tuiles (`min-h-24`), la hauteur de l'en-tête de carte (`min-h-8`) et la largeur des colonnes de formulaire (`max-w-3xl`, alignée à gauche). Le composant `Panel` (`packages/ui/src/components/panel.tsx`) applique ces valeurs : titre, aide « ? », description, action, corps.
- **Où** : Accueil immobilier, portail courtier, estimateur, intégration du courtier, fiche du prospect et ses outils, pipeline, prospects, courtiers, paramètres, devises, tableau de ventes, pages de connexions, Support. Les listes à l'intérieur d'une carte n'ont plus de deuxième bordure (`divide-y`).
- **Mon compte** : une seule colonne (`LAYOUT.column`), les sections se suivent : profil, agences, connexion, appareils, préférences, aide.
- **Comment refaire** : une nouvelle page prend `className={LAYOUT.stack}` pour la pile, `LAYOUT.column` pour une colonne de formulaire, et `<Panel>` pour chaque bloc. Ne pas écrire d'écarts à la main.
- **Vérifié** : types, 237 tests de l'application, captures desktop et mobile des pages touchées.

### B.16 — Traduction : icône refaite, essai réel auprès de Google
- **Correction** : le journal disait que la traduction n'avait pas pu être essayée. En fait seul l'hôte `translate.google.com` est bloqué par le réseau de cet environnement. Le script officiel se charge aussi depuis `translate.googleapis.com` (changé dans `apps/app/lib/translation-config.ts`) et **la vraie traduction fonctionne** : essai complet en espagnol et en anglais (`scripts/translate-flow.cjs`, `scripts/translate-real.cjs`, `scripts/translate-e2e.cjs`).
- **Icône** : globe (Carbon `Earth`) de 20 px, rempli et rouge quand une langue est active, avec le code de la langue en petit badge (ES, EN…), infobulle « Traduire la page ».
- **Défauts trouvés pendant l'essai réel, corrigés** : Google traduisait les initiales d'un avatar (« AF » devenait « Fuerza Aérea ») et les noms de personnes. `translate="no"` sur les initiales, les noms, les téléphones, les courriels et la marque. Google traduit aussi les `aria-label` : les essais automatiques s'appuient donc sur des attributs `data-*`, pas sur les libellés.
- **Limite connue (à décider)** : Google reçoit le texte affiché, y compris des noms et des messages de prospects, pour le traduire. Une confirmation est exigée avant la première traduction. **Savoir si c'est acceptable au regard de la loi 25 est une décision d'Alexandre.**
- **Limite de qualité** : certains mots du métier sont traduits de façon approximative (exemples relevés : « courtière », « Rendez-vous », « Prospects »).

### B.17 — Page Équipe
- **Quoi** : une page `/team` (barre latérale, après Pipeline, réservée au personnel de l'agence) et une fiche `/team/[userId]`.
  - **Liste** : tuiles (membres, en ligne, tâches en retard, actions sur 30 jours), recherche, filtres Tous / En ligne / Courtiers / Équipe, une ligne par personne (rôle, agences, tâches ouvertes et en retard, actions, dernière connexion).
  - **Fiche** : profil, huit tuiles (tâches ouvertes, en retard, terminées, prospects suivis, notes, SMS envoyés, conversations IA, demandes de support ouvertes) et trois onglets : **Activité** (fil des notes, appels, SMS envoyés à la main, demandes de support, conversations avec l'assistant), **Tâches** (en retard, à venir, terminées récemment), **Rôle et accès** (rôle dans l'espace, ce qu'il permet, agences et rôles).
- **Règles d'accès (testées)** : un propriétaire ou un administrateur de l'espace voit tout le monde. Un membre ne voit que sa propre fiche et reçoit « Membre introuvable » pour une autre. Les notes et SMS ne sont listés que pour les agences où la personne qui regarde est elle-même membre : aucune fuite entre agences.
- **Données** : une action est une note de prospect, une activité du CRM ou un SMS envoyé à la main. Pour savoir qui a envoyé un SMS, le champ `metadata.authorId` du message est maintenant rempli (`queueLeadSms`, paramètre `authorId`). **Les SMS envoyés avant ce changement n'ont pas d'auteur et n'apparaissent pas dans l'historique d'une personne.** Index ajouté sur `leadNote(authorId, createdAt)` (migration additive `20261023120000_add_lead_note_author_index`).
- **Où** : `apps/api/src/team/*` (configuration, contrats Zod, service, routeur, module) ; `packages/ui/src/components/team-roster.tsx` et `team-member-detail.tsx` ; `apps/app/app/(app)/[slug]/team/*` ; textes dans `apps/app/lib/team-config.ts`, rôles dans `team-roles.ts` ; le nom dans le tableau des membres (Paramètres) ouvre la fiche ; le fil d'Ariane affiche le nom de la personne.
- **Vérifié** : 7 tests d'intégration (`apps/api/test/team.integration.spec.ts`), tests de navigation, captures bureau, mobile, mode sombre, courtière (pas d'entrée dans la barre, fiche d'un autre refusée). Données de démonstration : `scripts/demo-team.ts`. Captures : `scripts/team-shots.cjs`.
- **Limites** : la fiche n'affiche pas de « changement de rôle » (il reste dans Paramètres, Membres). Un propriétaire de l'espace qui n'est membre d'aucune agence ne voit aucune note ni aucun SMS de prospect (cohérent avec le reste de l'application : l'accès aux prospects passe par l'agence).

---

## Partie C — Comment tout refaire depuis zéro

Prérequis : Linux, Bun 1.4, Node 22 (et Node 24 seulement pour l'agent), PostgreSQL 16, git, ImageMagick (pour les icônes, facultatif).

1. **Cloner le produit au commit de base**
   ```bash
   git clone https://github.com/Endsi3g/fratex-agent
   cd fratex-agent && git checkout 7fc4914
   ```
2. **Cloner le journal**
   ```bash
   git clone -b claude/fratex-agent-rebuild https://github.com/alexandrefratini/ai_engineering ../ai_engineering
   ```
3. **Appliquer toutes les modifications** (vérifié sur une copie propre : 385 fichiers, contenu identique octet par octet à la copie de travail)
   ```bash
   git apply ../ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch
   ```
4. **Préparer l'environnement local** (Postgres, `.env`, migrations, données de démonstration)
   ```bash
   bash ../ai_engineering/fratex-agent-journal/scripts/setup-local.sh "$(pwd)"
   ```
   Le script affiche deux lignes `COOKIE=` et `COOKIE_MARIE=` : ce sont les sessions de démonstration (propriétaire et courtière). Il ajoute aussi les données de l'équipe (`demo-team.ts` : tâches, notes, SMS, demande de support) et crée la base de test.
5. **Démarrer l'application**
   ```bash
   nohup bun run dev --filter=app --filter=api > /tmp/dev.log 2>&1 &
   ```
   Ouvrir `http://localhost:3000/crm`. Pour entrer sans connexion Google, ajouter le cookie `crm.session_token` (valeur `COOKIE=`) dans le navigateur.
6. **Vérifier**
   ```bash
   (cd apps/app && bunx tsc --noEmit && bun test)
   (cd packages/ui && bunx tsc --noEmit)
   set -a && . ./.env && set +a
   (cd apps/api && CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts)
   (cd apps/agent && CRM_TELEMETRY_DISABLED=1 bun test)
   (cd packages/db && bun test) && (cd packages/auth && bun test) && (cd packages/validation && bun test)
   (cd apps/app && bunx next build)
   ```
   Résultats du 22 octobre 2026 : app 236, api 429, agent 393, db 115, auth 43, validation 8 tests réussis, aucune erreur de type, Biome sans erreur (quelques avertissements), compilation de production réussie (49 pages).
   Les variables d'environnement doivent être chargées (`set -a && . ./.env`) avant `db:test` et les tests d'intégration.
7. **Essayer l'agent IA sans clé de modèle**
   ```bash
   bash ../ai_engineering/fratex-agent-journal/scripts/run-agent-local.sh
   ```
   Puis redémarrer `app` et `api`. Voir `ETUDE-AGENTS-IA.md`, partie 6.
8. **Reprendre le travail**
   - Où se trouvent les choses : `docs/design.md` (design), `docs/agent.md` (agent), `AGENTS.md` (règles), `REBUILD-SPEC.md` (spécification).
   - Après chaque phase : mettre à jour ce journal, puis
     ```bash
     git add -N . && git diff HEAD --binary > ../ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch
     ```
     puis commit et push du journal sur `claude/fratex-agent-rebuild`. **Utiliser `git diff HEAD`, pas `git diff`** : sans `HEAD`, les fichiers supprimés avec `git rm` manquent au patch (erreur trouvée le 23 octobre 2026 : deux fichiers supprimés n'y figuraient pas).
9. **Refaire le guide et ses captures** (serveurs démarrés)
   ```bash
   node ../ai_engineering/fratex-agent-journal/scripts/guide-shots.cjs cookie.txt cookie-marie.txt ../ai_engineering/fratex-agent-journal/guide/images
   python3 ../ai_engineering/fratex-agent-journal/scripts/build-guide.py
   ```
   `cookie.txt` et `cookie-marie.txt` contiennent les valeurs `COOKIE=` et `COOKIE_MARIE=` de l'étape 4. Les scripts de capture utilisent Playwright (Chromium préinstallé).

---

## Partie D — Problèmes restants

Chaque entrée : **problème**, **effet**, **proposition**, **responsable**.

| # | Problème | Effet | Proposition | Responsable |
|---|----------|-------|-------------|-------------|
| P1 | Aucun vrai modèle de langage n'a été essayé. | On ne sait pas si l'assistant respecte STOP, le transfert à un humain et la règle de 160 caractères. | Brancher `AI_GATEWAY_API_KEY` ou un serveur compatible OpenAI. Écrire les evals du SDR (`ETUDE-AGENTS-IA.md`, partie 5.4). | Alexandre (clé), technique (evals) |
| P2 | Twilio, Meta, Google Agenda et l'envoi des conversions n'ont jamais été essayés en vrai. | Le SMS du faux essai reste à l'état « incertain ». | Créer les comptes de test et rejouer le parcours complet. | Alexandre |
| P3 | La traduction Google fonctionne (essai réel, voir B.16), mais envoie le texte affiché, noms et messages de prospects compris, à Google. | Risque de conformité (loi 25) si ce n'est pas acceptable. | Décider si c'est acceptable. Sinon : retirer le bouton ou ne l'offrir qu'aux pages sans données de prospects. | Alexandre |
| P4 | L'équipe n'est pas avertie d'une nouvelle demande de support. L'adresse `support@fratex.ca` est une hypothèse. | Une demande peut rester sans réponse. | Confirmer l'adresse. Ajouter une alerte Slack ou courriel. | Alexandre, technique |
| P5 | Les messages d'erreur de l'API sont en anglais. | Un courtier peut voir de l'anglais. | Traduire les exceptions des services anciens. | Technique |
| P6 | L'application mobile native n'existe pas. | Seule la version web adaptée au mobile existe. | Suivre le plan M1 à M5 (`ETUDE-AGENTS-IA.md`, partie 7). | Alexandre (décision), technique |
| P7 | Les agents ne se parlent pas entre eux. | Aucun enchaînement automatique après « prospect qualifié ». | Suivre la partie 4 de l'étude (événements SDR, enveloppe de message, anti-boucle). | Technique |
| P8 | Il n'y a pas de registre du contenu généré ni de page « Activité de l'assistant ». | On ne relie pas un texte généré à son résultat. | Table `GeneratedContent` et page de résultats (étude, partie 5). | Technique |
| P9 | Un SMS à l'état « incertain » n'a pas d'écran de rapprochement. | Le courtier ne sait pas quoi faire. | Écran qui propose de vérifier chez Twilio puis de renvoyer ou de fermer. | Technique |
| P10 | L'agent exige Node 24 et des paquets déclarés « externes » qui ne sont pas des dépendances directes de `apps/agent`. | Il ne démarre pas sur une machine neuve sans les liens faits à la main. | Déclarer `@prisma/client`, `@prisma/adapter-pg`, `pg` et `@vercel/blob` dans `apps/agent/package.json`. Noter Node 24 dans `docs/agent.md`. | Technique |
| P11 | Biome signale un avertissement pour l'écriture directe de `document.cookie` (traduction). | Avertissement de lint seulement. | Passer à l'API Cookie Store quand elle sera répandue. | Technique |
| P12 | Le texte du faux modèle contient parfois `[blocked]`. | Marqueur inconnu dans une réponse coupée. | Vérifier avec un vrai modèle. | Technique |
| P13 | Les données de démonstration du CRM général n'ont pas de « dernière activité ». | Colonne « — » dans Affaires et Contacts. | Remplir `lastActivityAt` dans le script de démonstration. | Technique |
| P14 | La page « Connexions, Assistant IA » montre le faux modèle dans les captures. | Capture non représentative d'une vraie configuration. | Reprendre la capture après le branchement d'un vrai modèle. | Technique |
| P15 | Les tests d'intégration exigent que les variables d'environnement soient chargées. | `bun run db:test` échoue sans elles. | Charger `.env` dans le script `db:test` du dépôt. | Technique |
| P16 | Google traduit certains mots du métier de façon approximative (« courtière », « Rendez-vous », « Prospects »). | Un courtier non francophone peut mal comprendre un terme. | Ajouter `translate="no"` aux termes du métier ou fournir de vraies traductions (i18n) si la demande existe. | Technique |
| P17 | Historique des SMS d'une personne : les SMS envoyés à la main avant le 23 octobre n'ont pas d'auteur enregistré. | Ils n'apparaissent pas dans la fiche Équipe. | Aucune correction possible a posteriori. Les nouveaux SMS sont attribués. | — |
| P18 | La fiche Équipe ne montre pas les tâches du CRM assignées à une autre personne que leur créateur. | « Tâches » = tâches créées par la personne. | Ajouter un champ « assignée à » sur les activités si l'équipe en a besoin. | Technique |

---

## Partie E — À faire plus tard : gestion des réseaux sociaux

**Statut : noté, rien n'est construit.** Demande d'Alexandre : l'application devra pouvoir gérer les réseaux sociaux, mais pas maintenant.

- **Ce qui existe déjà** : prospects Meta Lead Ads, canal Messenger dans la boîte de réception (ouvre l'application externe), conversions renvoyées à Meta.
- **Ce qu'il faudrait** : (1) connecter les comptes (pages Facebook et comptes Instagram professionnels) dans Paramètres, Connexions, avec l'autorisation Meta appropriée (une revue de l'application Meta est nécessaire pour publier ou lire les messages) ; (2) un calendrier de publications avec brouillon, approbation par le courtier et publication planifiée ; (3) les commentaires et messages directs dans la boîte de réception multicanal ; (4) le suivi des résultats par publication.
- **À faire avant** : le registre du contenu généré (P8) et le protocole entre agents (P7), puisque les publications seront écrites par des agents. Chaque texte généré doit rester une **suggestion** tant que le courtier ne l'a pas approuvé (règle du dépôt : donnée non confirmée = suggestion).
- **Points d'attention** : droit d'auteur et consentement pour les photos de propriétés, mentions légales de l'Office de la protection du consommateur et de l'OACIQ dans les annonces, loi 25 pour les messages directs.
- **Décisions à prendre le moment venu** : quels réseaux d'abord (Facebook et Instagram sont les plus probables), qui approuve une publication, et si les messages directs entrent dans l'assistant SDR.
