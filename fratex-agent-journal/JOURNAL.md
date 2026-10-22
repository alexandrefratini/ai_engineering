# Journal de travail — Fratex Agent

> Pour qui : Alexandre (et toute personne qui débute). Chaque étape dit **quoi**, **où**, **comment**, **pourquoi**, la **logique**, et **comment refaire**.
> Dépôt du produit : `Endsi3g/fratex-agent` (lecture seule depuis cette session). Ce journal, les scripts et les patchs vivent dans `alexandrefratini/ai_engineering`, branche `claude/fratex-agent-rebuild`.

## Sommaire

- Partie 0 — Incident du 22 octobre et méthode de reconstruction
- Partie A — Compréhension du produit, règles, décisions
- Partie B — Phases (B.1 à B.14)
- Partie C — Comment tout refaire depuis zéro
- Partie D — Problèmes restants
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
- **Vérifié** : menu, confirmation, cookie, chargement du script. **Non vérifié** : la traduction elle-même (cet environnement n'atteint pas Google).

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
3. **Appliquer toutes les modifications** (vérifié sur une copie propre : 365 fichiers)
   ```bash
   git apply ../ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch
   ```
4. **Préparer l'environnement local** (Postgres, `.env`, migrations, données de démonstration)
   ```bash
   bash ../ai_engineering/fratex-agent-journal/scripts/setup-local.sh "$(pwd)"
   ```
   Le script affiche deux lignes `COOKIE=` et `COOKIE_MARIE=` : ce sont les sessions de démonstration (propriétaire et courtière). Il crée aussi la base de test.
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
     git add -N . && git diff --binary > ../ai_engineering/fratex-agent-journal/patches/TOUT-cumulatif.patch
     ```
     puis commit et push du journal sur `claude/fratex-agent-rebuild`.
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
| P3 | La traduction Google n'a pas été essayée (le réseau de l'environnement l'empêche). | Le menu marche, le résultat de traduction est inconnu. | Essayer sur un vrai navigateur. Décider si le texte des prospects peut être envoyé à Google (loi 25). | Alexandre |
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
