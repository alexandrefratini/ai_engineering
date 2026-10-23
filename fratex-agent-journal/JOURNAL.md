# Journal de travail — Fratex Agent

> Pour qui : Alexandre (et toute personne qui débute). Chaque étape dit **quoi**, **où**, **comment**, **pourquoi**, la **logique**, et **comment refaire**.
> Dépôt du produit : `Endsi3g/fratex-agent` (lecture seule depuis cette session). Ce journal, les scripts et les patchs vivent dans `alexandrefratini/ai_engineering`, branche `claude/fratex-agent-rebuild`.

## Sommaire

- Partie 0 — Incident du 22 octobre et méthode de reconstruction
- Partie A — Compréhension du produit, règles, décisions
- Partie B — Phases (B.1 à B.28)
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
- **Quoi** : `guide/index.html` (menu latéral, filtre, 45 pages décrites, 74 captures, agrandissement au clic, mode sombre et mobile), sections : démarrer, immobilier, assistant IA, CRM général, paramètres, compte et aide, partout dans l'application, annexes.
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

### B.18 — Les restes : alerte de support, règles et evals du SDR, dépendances de l'agent
- **Alerte de support** : une pastille rouge avec le nombre de demandes ouvertes sur l'icône Support, visible seulement des propriétaires et administrateurs, mise à jour chaque minute (API `support.pending`, test d'intégration). **Personne n'est encore averti par courriel ni Slack** : seul l'affichage dans l'application existe. L'adresse affichée se règle par `NEXT_PUBLIC_SUPPORT_EMAIL` (défaut `support@fratex.ca`, **hypothèse à confirmer**).
- **Désabonnement renforcé** : « Stop. », « STOP SVP », « Arrêtez de m'écrire », « ARRÊT » sont maintenant reconnus (`apps/api/src/messaging/opt-out.ts`, 29 cas testés, dont des phrases qui ne doivent **pas** désabonner comme « L'arrêt Berri est le plus proche »). Avant, seuls les mots exacts passaient.
- **Les règles du SDR sont dans le code, pas dans le modèle** : STOP, consentement, prise en main humaine, numéro SMS absent, 160 caractères, échelon de relance 1 à 5. `apps/agent/test/sdr-rules.integration.spec.ts` le prouve sans modèle. **Correction** : le journal disait qu'on ne savait pas si un vrai modèle respecterait STOP et les 160 caractères. Il n'a pas le choix : le code refuse.
- **Evals du jugement** : `apps/agent/evals/sdr.eval.ts` (six scénarios) avec des correcteurs testés. Lancé contre le faux modèle sur l'agent en marche : trois scénarios réussis (ceux qui dépendent du code), trois échecs attendus (transfert à un humain, extraction des critères) : l'eval détecte bien l'absence de jugement. Commande : `eve eval sdr --url http://127.0.0.1:2000` avec les variables du `.env`. **Jamais lancé avec un vrai modèle.**
- **Dépendances de l'agent** : `@prisma/client`, `@prisma/adapter-pg`, `@vercel/blob` et `pg` déclarés dans `apps/agent/package.json` (verrou `bun.lock` : 4 lignes). Node 24 était déjà exigé par le dépôt ; seul mon environnement avait Node 22.

### B.19 — Registre du contenu généré et page « Activité de l'assistant »
- **Table** `GeneratedContent` (migration additive `20261023140000_add_generated_content`) : agence, courtier, prospect, genre (annonce suggérée, description, courriel, publication, note), état (à vérifier, approuvé, transmis, publié, écarté), agent, session, texte, faits d'entrée, clé d'idempotence, approbateur.
- **Qui écrit dedans** : `analyze_property_listing` (annonce suggérée, à vérifier), `escalate_to_human` (note de transfert), et le destinataire du protocole (B.20, note de préparation). Les SMS ne sont pas copiés.
- **API** : module `assistant-activity` (`summary`, `review`), portée par agence et par courtier, révision réservée aux rôles qui peuvent écrire. 7 tests d'intégration (comptes, période, isolation d'un courtier, approbation une seule fois).
- **Page** `/real-estate/activity` : période 7, 30 ou 90 jours, huit indicateurs (SMS envoyés, réponses, qualifiés, transferts, à vérifier, envois incertains, envois échoués, tâches en retard), liste du contenu avec Approuver / Écarter.
- **Limites** : « transferts à un humain » ne compte que depuis le 23 octobre ; `trackingCode` n'est pas câblé (contenu → prospect → rendez-vous reste à faire).

### B.20 — Protocole entre agents (tranche minimale)
- **Quoi** : enveloppe de message validée par Zod, file durable `AgentTask` de type `agent-message`, champs `correlationId`, `parentTaskId`, `hop` (migration additive `20261023150000_add_agent_message_fields`), routes autorisées (`agent-message-config.ts`), anti-boucle (3 sauts, refus d'un retour vers un agent déjà dans la chaîne, 4 messages par heure et par couple d'agents pour un prospect), idempotence, expiration à 24 h.
- **Émetteurs** : `qualify_lead` (`lead.qualified`) et `book_appointment` (`appointment.booked`), après la transaction, une seule fois. Un échec d'émission ne fait jamais échouer la qualification.
- **Destinataire** : `visit_prep`, **déterministe, sans modèle** : relit le prospect avec ses propres droits, revalide l'agence et le courtier, puis écrit une note de préparation (critères confirmés seulement, jamais les mots du prospect) dans le registre.
- **Vérifié** : 10 tests (enveloppe, rejeu, expéditeur sans route, charge utile avec champ en trop, prospect d'une autre agence, boucle, trop de sauts, limite horaire, note unique, expiré, message cassé, prospect déplacé) et **en direct** : message mis en file, agent en marche, note écrite par la voie directe du répartiteur (« Note de préparation écrite. »).
- **Défaut trouvé en direct et corrigé** : une fourchette de budget contradictoire (minimum plus grand que maximum) apparaissait dans la note ; elle est maintenant omise au lieu d'être devinée.
- **Non construit** : l'outil `handoff_to_agent`, les destinataires pilotés par un modèle, les jetons de continuation `msg:`. Aucun modèle ne peut donc envoyer de message à un autre agent pour l'instant.

### B.21 — Application installable (PWA) et page hors ligne
- **Quoi** : manifeste complet (`id`, portée, langue, icônes `any` et `maskable`, raccourcis), couleur de thème claire et sombre, balises iOS, service worker qui ne garde **que** la page hors ligne (aucune page connectée n'est mise en cache), page `/offline.html` en français. Le service worker et la page hors ligne sont exclus du contrôle de connexion (`proxy.ts`).
- **Vérifié sur la version de production** : enregistrement du service worker (portée `/`), manifeste lu par le navigateur, puis arrêt réel du serveur : la page « Vous êtes hors ligne » s'affiche (`scripts/pwa-register.cjs`, `scripts/pwa-offline.cjs`). Le simulateur « hors ligne » de Playwright n'affecte pas les requêtes du service worker : il faut vraiment arrêter le serveur.
- **Non fait** : Capacitor, Expo, boutiques d'applications, notifications natives. Ces outils ne sont pas disponibles dans cet environnement.

### B.22 — Application mobile (Android et iOS) et mise en conformité du lint
- **Quoi** : `apps/mobile`, une enveloppe [Capacitor](https://capacitorjs.com) 8.5.3 qui ouvre l'application web déployée dans une vue native. Identifiant `ca.fratex.agent`. Projets natifs générés **et commités** (`android/`, `ios/`), icônes et écrans de démarrage (clair et sombre) produits à partir du glyphe de la marque (`apps/mobile/assets`, `scripts/make-mobile-assets.cjs`), page « Impossible de joindre Fratex » (`offline.template.html`), schéma d'URL `ca.fratex.agent` dans `AndroidManifest.xml` et `Info.plist`, sauvegarde Android désactivée (les cookies de session ne sont pas sauvegardés), agent utilisateur `FratexMobile/1.0` pour que le serveur reconnaisse l'application. Le projet iOS utilise Swift Package Manager (pas de CocoaPods). Guide d'emploi : `docs/mobile.md` dans le dépôt du produit.
- **Choix et raison** : Capacitor et non Expo, parce que toutes les pages existent déjà et sont adaptées au mobile ; un portage natif ne se justifie que pour le hors ligne complet. L'application web est rendue côté serveur : elle ne peut pas être empaquetée en fichiers statiques, d'où l'ouverture de l'adresse du déploiement (variable `CAPACITOR_SERVER_URL` à fournir avant `bun run sync`).
- **Le vrai problème : la connexion.** Google refuse la connexion OAuth dans une vue web intégrée (`disallowed_useragent`). Solution construite et testée : l'application génère un **vérificateur** secret (qui reste dans l'application) et en envoie l'**empreinte** au navigateur du téléphone ; après la connexion, le navigateur dépose un jeton à usage unique sous cette empreinte (`POST /api/native-auth/handoff`) puis rouvre l'application par `ca.fratex.agent://auth/done` **sans aucun secret dans l'adresse** ; l'application présente alors son vérificateur (`POST /api/native-auth/exchange`) et reçoit le cookie de session. Une autre application qui s'enregistrerait sur le même schéma d'URL ne reçoit rien d'utile. Le jeton expire en 2 minutes, ne sert qu'une fois, un mauvais vérificateur ne le consomme pas, et le plugin `one-time-token` est configuré **sans** accès pour les scripts de page.
- **Où** : `packages/auth/src/native-constants.ts` et `native-session.ts`, `apps/api/src/native-auth`, `apps/app/lib/native-*.ts`, `apps/app/components/native-shell.tsx` (liens profonds, bouton retour d'Android, retour au premier plan), `apps/app/app/(landing)/sign-in/native-sign-in.tsx` et `native/handoff`, `proxy.ts` (`/native` exempté de la redirection vers l'espace de travail), workflow manuel `.github/workflows/mobile.yml`.
- **Vérifié** : 8 tests d'intégration de l'échange (`apps/api/test/native-auth.e2e.spec.ts` : succès, usage unique, double demande, mauvais vérificateur sans consommation, expiration, session requise, entrées mal formées, jeton jamais remis à un script), 8 tests des utilitaires (`apps/app/test/native.spec.ts`), 7 tests de configuration (`apps/mobile/test`), et le parcours complet dans un vrai navigateur avec la vraie pile (`scripts/native-flow.cjs` : bouton « Continuer dans le navigateur » sans bouton Google dans l'application, page de retour, tentative d'ouverture de `ca.fratex.agent://auth/done`, échange, session ouverte). `cap sync` réussit avec une adresse `https://` (texte clair désactivé) et `cap doctor` donne « Android looking great ».
- **Défaut trouvé par la compilation de production et corrigé** : la page `/native/handoff` lisait `searchParams` hors de `<Suspense>` (règle de Next 16). Le serveur de développement ne le signale pas ; seule la compilation de production l'a refusé.
- **NON vérifié** : (1) **aucun projet natif n'a été compilé** : cet environnement n'a ni SDK Android (le site de téléchargement de Google est bloqué) ni Xcode. La première compilation se fait avec Android Studio, Xcode ou le workflow `Mobile`, qui n'a jamais tourné. (2) Les écouteurs de `NativeShell` (lien profond, retour d'Android) n'ont pas été exécutés dans une vraie vue native : seule la partie web du parcours est prouvée. (3) Aucune notification push, aucun hors ligne complet, pas de liens universels (le domaine de production n'est pas connu), pas de publication dans les boutiques.

### B.23 — `lint:slop` : 69 erreurs de ma part, corrigées
- **Découverte** : en préparant le mobile, `bun run lint:slop` (oxlint avec des règles « anti-slop » maison, exécuté par le CI et par le hook de pré-push) donnait **69 erreurs**. Le commit de base en avait **zéro**. Je ne l'avais jamais lancé depuis le début : mes « tout est vérifié » précédents étaient donc incomplets, et le CI aurait refusé la branche.
- **Causes** : dictionnaires de libellés annotés `Record<string, string>` (36 : la règle veut `satisfies`), paramètres `unknown` (15), `typeof` (10), spreads conditionnels `...(x ? {…} : {})` (5), types de dictionnaire ouverts, une assertion chaînée.
- **Correction** : `satisfies` et un petit utilitaire `lookup` (`packages/ui/src/lib/lookup.ts`) pour les lectures par clé quelconque ; erreurs typées structurellement (`CodedError`) ; lecture de `localStorage` analysée avec zod ; objets Prisma construits en deux temps ; charges utiles des messages entre agents typées par leurs schémas. `PageShellTitle` n'accepte plus que du texte comme enfant (l'étiquette de l'infobulle en dépend). Résultat : `lint:slop` à 0 erreur, types, Biome (0 erreur, 26 avertissements) et tous les tests inchangés ou meilleurs.
- **À retenir** : la liste de vérification de la partie C contient maintenant `bun run lint:slop`.

### B.24 — Notifications push (Android et iOS)
- **Quoi** : trois alertes sans donnée de prospect (nouveau prospect, réponse d'un prospect, passage à un humain), envoyées par Firebase Cloud Messaging (Android) et Apple Push Notification service (iOS), avec un panneau « Notifications » dans Mon compte (trois interrupteurs, bouton « Activer » visible seulement dans l'application mobile).
- **Où** : migration additive `20261023170000_add_push_devices` (`PushDevice`, `PushPreference`), `packages/db/src/push*.ts`, `apps/agent/agent/lib/push/` (JWT RS256 pour FCM, ES256 pour APNs, transports injectables), `apps/api/src/push` (routeur `push` : `state`, `registerDevice`, `unregisterDevice`, `setPreferences`), `apps/app/components/push-registration.tsx` et `push-settings.tsx`, configuration native (`POST_NOTIFICATIONS`, `App.entitlements`, méthodes de `AppDelegate`), variables dans `.env.example`.
- **Logique** : chaque événement crée une tâche durable `push-notify` (voie directe de l'agent) avec une **clé d'idempotence** (`push:reply:<agence>:<MessageSid>`, `push:lead:<id>`, `push:handoff:<session>:<appel>`). Les destinataires sont calculés **au moment de l'envoi** (courtier assigné, sinon propriétaires et administrateurs) en respectant les préférences. Un jeton refusé désactive l'appareil, un échec transitoire relance la tâche (3 tentatives). Le jeton est retiré à la déconnexion. Un échec d'enfilage ne fait jamais échouer le traitement du message (`queuePushSafely`).
- **Vérifié** : 36 tests de l'agent (signature JWT, identifiants, classement des réponses FCM et APNs, destinataires, silence, reprise, tâche mal formée, idempotence), 8 de l'API (appareil enregistré une seule fois, repris par la personne suivante, plafond de 10, retrait limité à son propriétaire, préférences, entrées refusées), assertions dans le test de bout en bout du SMS (une tâche par SMS reçu même en double, aucune pour un STOP), et le panneau dans un vrai navigateur (interrupteur modifié, page rechargée, valeur conservée).
- **NON vérifié** : aucun envoi réel (pas de compte Firebase ni de clé APNs), aucun appareil, aucune compilation native. Mise en service : `docs/mobile.md`.

### B.25 — Liens universels et App Links (domaine configurable)
- **Quoi** : `/.well-known/assetlinks.json` et `/.well-known/apple-app-site-association` servis par l'application web **seulement si** `ANDROID_CERT_SHA256` et `APPLE_TEAM_ID` sont définis (sinon 404) ; filtre d'intention Android avec vérification automatique et droit associé iOS (`applinks:$(APP_LINK_HOST)`), tous deux pilotés par `APP_LINK_HOST` (valeur par défaut `app-link.invalid`, jamais résolue) ; `sync` refuse un `APP_LINK_HOST` qui n'est pas l'hôte de `CAPACITOR_SERVER_URL`.
- **Choix important** : seules les pages de l'application sont revendiquées (dix sections, avec ou sans l'espace de travail devant). La connexion, `/api`, `/native` et les pages publiques ne le sont **jamais**, sinon le retour OAuth du navigateur pourrait être capté par l'application. Android ne sait pas exclure des chemins : le manifeste liste donc des préfixes précis (`pathAdvancedPattern` pour l'espace de travail, Android 12 et plus).
- **Vérifié** : 15 tests (fichiers refusés sans configuration ou avec une valeur invalide, mêmes chemins revendiqués côté iOS et Android, aucun chemin de connexion revendiqué, ouverture d'un lien https seulement pour son propre hôte et une section reconnue), version de production avec les variables (les deux fichiers servis en JSON) et sans (404), `.well-known` exempté de la redirection de connexion.
- **NON vérifié** : aucun appareil, aucun domaine réel (Google et Apple valident le fichier depuis leurs serveurs).

### B.26 — Hors ligne : lecture sans connexion
- **Quoi** : service worker v2 qui garde une copie **par personne** des pages et des lectures tRPC déjà consultées (réseau d'abord, copie après 4 s ou en cas d'échec), bandeau « Hors ligne : données enregistrées le … », panneau « Hors ligne » dans Mon compte (nombre d'éléments, date du plus ancien, effacement), purge à la déconnexion, sur la page de connexion et au changement de personne.
- **Décision de fond** : **aucune écriture hors ligne**. Une file qui enverrait un SMS plus tard, sur un contexte périmé, serait pire qu'un échec visible : les mutations échouent tout de suite avec un message (`networkMode: "always"` et message unique), sauf les requêtes de fond (présence, enregistrement de l'appareil).
- **Confidentialité (loi 25)** : cache nommé par une empreinte de l'identifiant ; expiration à 7 jours ; 200 éléments au plus ; jamais de connexion, clés d'API, SSO, connexions Google, Microsoft, Slack, suivi, notifications, présence ni recherche ; une page rendue en erreur par le serveur n'écrase jamais une bonne copie ; fichiers de l'application liés à la version du déploiement.
- **Défauts trouvés en vérifiant, corrigés** : (1) le client tRPC regroupait les lectures en lots dont la composition changeait à chaque chargement, donc la copie n'était presque jamais retrouvée : une requête par lecture ; (2) une lecture échouée sur une page qui avait déjà ses données la faisait passer en erreur (cartes « Accès indisponible ») : les données déjà là sont conservées ; (3) les requêtes de fond affichaient un message d'écriture refusée ; (4) mon essai utilisait le mauvais nom de cookie en production (`__Secure-crm.session_token`) : toutes mes premières « réussites » étaient en réalité la page de connexion, repérées grâce à des assertions sur les noms des prospects.
- **Vérifié** : 26 tests (service worker complet avec une fausse API de cache : routes ignorées, une seule personne, expiration, plafond, lenteur, erreur de rendu, bienvenue au rechargement ; helpers, bandeau, détection des erreurs réseau, conservation des données) et, dans un vrai navigateur sur la version de production **avec arrêt réel du serveur** (`scripts/offline-flow.cjs`) : 15 vérifications (copie unique et sans identifiant lisible, liste avec noms, bandeau daté, navigation interne, page jamais consultée, fiche de prospect, écriture refusée en 94 ms, aucune note envoyée au retour du serveur, bandeau disparu) et `scripts/offline-users.cjs` (changement de personne, déconnexion, session expirée).
- **iOS** : un service worker dans WKWebView exige `WKAppBoundDomains` : activé quand `APP_LINK_HOST` est défini. **NON vérifié** sur un appareil.

### B.27 — Campagne de stress et code défensif
Détail complet : `docs/robustesse.md` (dépôt du produit) et l'annexe « Campagne de stress » du guide. Résumé :
- **Balayage des 202 procédures** (`authz-sweep.e2e.spec.ts`) : sans session tout est refusé sauf `sso.signInOptions` ; aucune fuite entre agences ni entre courtiers (témoin positif inclus) ; des entrées hostiles ne donnent plus aucune erreur 5xx.
- **Points d'entrée publics** (`public-endpoints.e2e.spec.ts`, 13 tests) : webhooks signés mais hostiles, tâches planifiées, suivi, retours OAuth, pont REST.
- **File de l'agent** (`queue-stress.integration.spec.ts`) : 400 tâches, 12 travailleurs, plantages simulés, exactement une exécution, 3 tentatives au plus.
- **Pannes réelles** : Postgres arrêté brutalement (503 en 15 à 40 ms, page d'erreur française, reprise en moins de 50 ms sans redémarrage) ; agent arrêté (tâches en attente, exécutées une fois au retour). **Charge** : zéro erreur sur 19 000 requêtes à 50 utilisateurs simultanés (conteneur partagé : indicatif).
- **Parcours de 41 pages** (`scripts/crawl-pages.cjs`, bureau et mobile) : aucune page en erreur.
- **Défauts réels corrigés** : caractère nul → 500 ; erreurs de validation et de base causées par l'utilisateur → 500 (maintenant 400, 409, 404) ; corps trop gros → 500 au lieu de 413 et aucune limite côté relais web ; base arrêtée → « session expirée » et page anglaise ; messages d'erreur qui montraient chemins de fichiers, code et hôte de la base ; appels sortants sans délai (révocation Google, deux appels OAuth Slack) ; **liste des appareils connectés cassée à partir du deuxième jour** (session « pas assez fraîche » pour Better Auth, maintenant `freshAge` = durée de session) ; `/real-estate` donnait un 404 (redirection relative) ; aucune page d'erreur en français (ajoutées).
- **Ma propre erreur de méthode** : mon premier balayage d'entrées avait pollué la base de test et fait échouer six tests voisins ; les balayages nettoient maintenant ce qu'ils créent, et la base de test se réinitialise avec `bun run db:test` dans `packages/db`.
- **Reste** : erreur d'hydratation React n° 418 intermittente en production (environ 5 % des chargements, jamais en développement, sans effet visible, cause inconnue, présente sans les ajouts de cette session) ; pas de limitation de débit sur les routes publiques ; services externes jamais appelés pour de vrai.

### Défauts trouvés en vérifiant le travail, tous corrigés
1. Le patch cumulatif omettait deux fichiers supprimés (voir la partie C, étape 8).
2. La liste d'outils de la télémétrie ignorait cinq outils de l'assistant (`list_appointments`, `list_prospects_needing_attention`, `read_prospect`, `realtor_performance`, `search_prospects`) : un test échouait depuis la phase B.4 sans que je l'aie lancé. Les tests de `packages/telemetry` sont maintenant dans la liste de vérification.
3. Le type de tâche `agent-message` manquait dans les phrases d'état de la file (erreur de type).
4. Les mots de désabonnement avec ponctuation n'étaient pas reconnus (voir B.18).
5. 69 erreurs de `lint:slop`, jamais lancé jusque-là (voir B.23).
6. La page `/native/handoff` cassait la compilation de production (voir B.22).
7. Un caractère nul faisait échouer en 500 tout texte écrit en base ; des erreurs de données renvoyées en 500 ; liste des appareils connectés cassée après un jour ; `/real-estate` en 404 ; pas de page d'erreur française (voir B.27).

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
3. **Appliquer toutes les modifications** (vérifié sur une copie propre : 647 fichiers, contenu identique octet par octet à la copie de travail)
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
   (cd apps/api && bunx tsc --noEmit) && (cd apps/agent && bunx tsc --noEmit) && (cd apps/mobile && bunx tsc --noEmit)
   (cd packages/ui && bunx tsc --noEmit)
   set -a && . ./.env && set +a
   (cd packages/db && bun run db:test)
   (cd apps/api && CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts)
   (cd apps/agent && CRM_TELEMETRY_DISABLED=1 bun test)
   (cd packages/db && bun test) && (cd packages/auth && bun test) && (cd packages/validation && bun test) && (cd packages/telemetry && bun test) && (cd packages/env && bun test) && (cd apps/mobile && bun test)
   bunx biome check .
   bun run lint:slop
   (cd apps/app && bunx next build)
   ```
   Résultats du 23 octobre 2026 (fin de B.27, `bun run test` : 11 tâches réussies) : app 303, api 529, agent 465, mobile 11, db 115, auth 44, validation 8, telemetry 61, env 17 tests réussis, `lint:slop` à 0 erreur, aucune erreur de type, Biome sans erreur (26 avertissements), compilation de production réussie.
   Les variables d'environnement doivent être chargées (`set -a && . ./.env`) avant `db:test` et les tests d'intégration. La base de test peut être réinitialisée avec `(cd packages/db && bun run db:test)` après un `--reset` ; si des tests voisins échouent « sans raison », vérifier d'abord qu'une exécution interrompue n'a pas laissé de lignes.
7. **Essayer l'agent IA sans clé de modèle**
   ```bash
   bash ../ai_engineering/fratex-agent-journal/scripts/run-agent-local.sh
   ```
   Puis redémarrer `app` et `api`. Voir `ETUDE-AGENTS-IA.md`, partie 6. Pour lancer les evals du SDR contre l'agent en marche : `(cd apps/agent && set -a && . ../../.env && set +a && bunx eve eval sdr --url http://127.0.0.1:2000)` (avec le faux modèle, trois scénarios échouent : c'est attendu).
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

10. **Essais de robustesse** (voir `docs/robustesse.md` du produit)
   ```bash
   (cd apps/api && CRM_TELEMETRY_DISABLED=1 bun test --preload ./test/setup.ts test/authz-sweep.e2e.spec.ts test/public-endpoints.e2e.spec.ts)
   (cd apps/agent && bun test test/queue-stress.integration.spec.ts)
   bash ../ai_engineering/fratex-agent-journal/scripts/restart-services.sh   # après un redémarrage du conteneur
   node ../ai_engineering/fratex-agent-journal/scripts/offline-flow.cjs <cookie> <pid du serveur web> <dossier de captures>   # tue réellement le serveur
   node ../ai_engineering/fratex-agent-journal/scripts/crawl-pages.cjs <cookie> <dossier>   # parcours de 41 pages, bureau et mobile
   node ../ai_engineering/fratex-agent-journal/scripts/load.mjs <url> <simultanés> <secondes> [cookie]
   ```
   `offline-flow.cjs` démarre lui-même un nouveau serveur à la fin et suppose la version de production de l'application sur le port 3000.

11. **Application mobile**
   ```bash
   cd apps/mobile
   CAPACITOR_SERVER_URL=https://<domaine-de-production> bun run sync
   bun run open:android      # Android Studio
   bun run open:ios          # Xcode, macOS seulement
   ```
   Voir `docs/mobile.md` dans le dépôt du produit (pont de connexion, liste de contrôle de publication). Le workflow GitHub « Mobile » compile un APK de débogage et une version simulateur iOS à la main.

---

## Partie D — Problèmes restants

Chaque entrée : **problème**, **effet**, **proposition**, **responsable**.

| # | Problème | Effet | Proposition | Responsable |
|---|----------|-------|-------------|-------------|
| P1 | Aucun vrai modèle de langage n'a été essayé. | STOP, consentement, prise en main humaine et 160 caractères sont appliqués par le code (testés). On ne sait pas si un vrai modèle sait **quand** passer la main à un humain ni s'il extrait bien les critères. | Brancher `AI_GATEWAY_API_KEY` ou un serveur compatible OpenAI et lancer `eve eval sdr` (déjà écrit, B.18). | Alexandre (clé) |
| P2 | Twilio, Meta, Google Agenda et l'envoi des conversions n'ont jamais été essayés en vrai. | Le SMS du faux essai reste à l'état « incertain ». | Créer les comptes de test et rejouer le parcours complet. | Alexandre |
| P3 | La traduction Google fonctionne (essai réel, voir B.16), mais envoie le texte affiché, noms et messages de prospects compris, à Google. | Risque de conformité (loi 25) si ce n'est pas acceptable. | Décider si c'est acceptable. Sinon : retirer le bouton ou ne l'offrir qu'aux pages sans données de prospects. | Alexandre |
| P4 | Une nouvelle demande de support n'avertit personne par courriel ni Slack (seule la pastille dans l'application existe, B.18). L'adresse `support@fratex.ca` est une hypothèse. | Une demande peut rester sans réponse si personne n'ouvre l'application. | Confirmer l'adresse (`NEXT_PUBLIC_SUPPORT_EMAIL`). Ajouter une alerte Slack ou courriel. | Alexandre, technique |
| P5 | Les messages d'erreur de l'API sont en anglais. | Un courtier peut voir de l'anglais. | Traduire les exceptions des services anciens. | Technique |
| P6 | Les projets mobiles (Capacitor, B.22) existent mais n'ont jamais été compilés ni lancés sur un appareil. | On ne sait pas s'ils démarrent ; les écouteurs natifs (lien profond, retour Android) n'ont pas été exécutés. | Lancer le workflow `Mobile` ou ouvrir `apps/mobile` dans Android Studio et Xcode, essayer la connexion sur un appareil, puis TestFlight et test interne Google Play. | Alexandre (comptes et appareils), technique |
| P7 | Les agents se parlent par messages durables (B.20), mais le seul destinataire est déterministe et aucun modèle ne peut envoyer de message. | Pas encore d'agent piloté par un modèle qui réagit à « prospect qualifié ». | Ajouter l'outil `handoff_to_agent` et un premier destinataire à modèle, avec les evals correspondantes. | Technique |
| P8 | Le registre et la page existent (B.19), mais le lien contenu → prospect → rendez-vous (`trackingCode`) n'est pas câblé et seuls trois producteurs écrivent dans le registre. | On voit ce que l'assistant a produit, pas encore ce que cela a rapporté. | Générer le code de suivi dans les liens d'annonces et le relier aux nouveaux prospects. | Technique |
| P9 | Un SMS à l'état « incertain » n'a pas d'écran de rapprochement. | Le courtier ne sait pas quoi faire. | Écran qui propose de vérifier chez Twilio puis de renvoyer ou de fermer. | Technique |
| P10 | ~~Paquets externes non déclarés~~ **Corrigé** (B.18) : les quatre paquets sont déclarés dans `apps/agent/package.json`. Node 24 reste exigé (déjà noté dans le dépôt). | — | — | — |
| P11 | Biome signale un avertissement pour l'écriture directe de `document.cookie` (traduction). | Avertissement de lint seulement. | Passer à l'API Cookie Store quand elle sera répandue. | Technique |
| P12 | Le texte du faux modèle contient parfois `[blocked]`. | Marqueur inconnu dans une réponse coupée. | Vérifier avec un vrai modèle. | Technique |
| P13 | Les données de démonstration du CRM général n'ont pas de « dernière activité ». | Colonne « — » dans Affaires et Contacts. | Remplir `lastActivityAt` dans le script de démonstration. | Technique |
| P14 | La page « Connexions, Assistant IA » montre le faux modèle dans les captures. | Capture non représentative d'une vraie configuration. | Reprendre la capture après le branchement d'un vrai modèle. | Technique |
| P15 | Les tests d'intégration exigent que les variables d'environnement soient chargées, et la base de test doit être migrée (`bun run db:test`) après chaque nouvelle migration. | Des dizaines d'échecs trompeurs (« colonne introuvable ») sur une base de test en retard. | Charger `.env` dans le script `db:test` du dépôt ; migrer la base de test dans le script `test` de l'API. | Technique |
| P16 | Google traduit certains mots du métier de façon approximative (« courtière », « Rendez-vous », « Prospects »). | Un courtier non francophone peut mal comprendre un terme. | Ajouter `translate="no"` aux termes du métier ou fournir de vraies traductions (i18n) si la demande existe. | Technique |
| P17 | Historique des SMS d'une personne : les SMS envoyés à la main avant le 23 octobre n'ont pas d'auteur enregistré. | Ils n'apparaissent pas dans la fiche Équipe. | Aucune correction possible a posteriori. Les nouveaux SMS sont attribués. | — |
| P18 | La fiche Équipe ne montre pas les tâches du CRM assignées à une autre personne que leur créateur. | « Tâches » = tâches créées par la personne. | Ajouter un champ « assignée à » sur les activités si l'équipe en a besoin. | Technique |
| P19 | Le répartiteur de l'agent ne reprend pas tout de suite un message `agent-message` déjà « loué » par une ancienne version du code. | Après un déploiement, un message en vol peut attendre la fin de son bail (quelques minutes). | Rien à faire en production ; en local, redémarrer l'agent puis libérer le bail. | — |
| P20 | Notifications push codées et testées (B.24) mais jamais essayées avec de vrais serveurs ni sur un appareil. | On ne sait pas si Google et Apple acceptent nos messages ni si l'application reçoit et ouvre la bonne fiche. | Créer le projet Firebase et la clé APNs, renseigner les variables (`docs/mobile.md`), essayer sur un appareil Android puis iOS. | Alexandre (comptes et appareils) |
| P21 | Liens universels et App Links codés (B.25) mais inactifs : le domaine de production n'est pas connu. | Les liens de courriel ouvrent le navigateur ; le schéma `ca.fratex.agent` reste utilisé. | Définir `APP_LINK_HOST`, `ANDROID_CERT_SHA256` et `APPLE_TEAM_ID`, recompiler, vérifier avec `adb shell pm get-app-links`. | Alexandre (domaine, comptes), technique |
| P22 | Erreur d'hydratation React n° 418 intermittente sur la version de production (environ 5 % des chargements, pages différentes, jamais en développement). | Aucun effet visible (React se corrige), mais du travail inutile et un signal d'un rendu serveur et client légèrement différents. | Reproduire avec une version de production non minifiée pour lire le message complet ; chercher une valeur qui change entre la pré-génération et le rendu client. | Technique |
| P23 | Aucune limitation de débit sur les routes publiques (webhooks, suivi) ; une requête fragmentée sans longueur déclarée n'est pas limitée côté API (B.27). | Un client malveillant pourrait saturer ces routes. | Limiter au niveau du fournisseur d'hébergement ou ajouter un limiteur Nest. | Technique |
| P24 | Le hors ligne ne permet que la lecture, et seulement pour les pages déjà consultées. | Pas de saisie hors ligne ; une page jamais ouverte n'est pas disponible. | Décision de produit : si une saisie hors ligne est voulue, la concevoir avec confirmation avant envoi (jamais d'envoi silencieux de SMS). | Alexandre, technique |
| P25 | En production, l'application web et l'API utilisent des noms de cookie de session différents si elles ne tournent pas dans le même mode (`__Secure-crm.session_token` ou `crm.session_token`). | En local, un mélange (application en production, API en développement) exige les deux cookies. | Faire tourner les deux dans le même mode ; à retenir pour les essais. | — |

---

## Partie E — À faire plus tard : gestion des réseaux sociaux

**Statut : noté, rien n'est construit.** Demande d'Alexandre : l'application devra pouvoir gérer les réseaux sociaux, mais pas maintenant.

- **Ce qui existe déjà** : prospects Meta Lead Ads, canal Messenger dans la boîte de réception (ouvre l'application externe), conversions renvoyées à Meta.
- **Ce qu'il faudrait** : (1) connecter les comptes (pages Facebook et comptes Instagram professionnels) dans Paramètres, Connexions, avec l'autorisation Meta appropriée (une revue de l'application Meta est nécessaire pour publier ou lire les messages) ; (2) un calendrier de publications avec brouillon, approbation par le courtier et publication planifiée ; (3) les commentaires et messages directs dans la boîte de réception multicanal ; (4) le suivi des résultats par publication.
- **À faire avant** : le registre du contenu généré (P8) et le protocole entre agents (P7), puisque les publications seront écrites par des agents. Chaque texte généré doit rester une **suggestion** tant que le courtier ne l'a pas approuvé (règle du dépôt : donnée non confirmée = suggestion).
- **Points d'attention** : droit d'auteur et consentement pour les photos de propriétés, mentions légales de l'Office de la protection du consommateur et de l'OACIQ dans les annonces, loi 25 pour les messages directs.
- **Décisions à prendre le moment venu** : quels réseaux d'abord (Facebook et Instagram sont les plus probables), qui approuve une publication, et si les messages directs entrent dans l'assistant SDR.
