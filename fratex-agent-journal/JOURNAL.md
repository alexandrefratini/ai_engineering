# Journal de travail — Fratex Agent

> Pour qui : Alexandre (et toute personne qui débute). Chaque étape dit **quoi**, **où**, **comment**, **pourquoi**, la **logique**, et **comment refaire**.
> Dépôt du produit : `Endsi3g/fratex-agent` (lecture seule depuis cette session). Ce journal, les scripts et les patchs vivent dans `alexandrefratini/ai_engineering`, branche `claude/fratex-agent-rebuild`.

## Sommaire

- Partie 0 — Incident du 22 octobre et méthode de reconstruction
- Partie A — Compréhension du produit, règles, décisions
- Partie B — Phases (une section par phase, ajoutée à la fin de chaque phase)
- Partie C — Comment tout refaire depuis zéro

---

## Partie 0 — Incident du 22 octobre 2026 et méthode de reconstruction

### Ce qui s'est passé
Vers 13 h 50, le conteneur de la session a été **réinitialisé**. Tout ce qui n'était pas sur GitHub a disparu :
- le clone local de `fratex-agent` avec **tout le code modifié** (phases 1 à 7b, environ 90 fichiers et 6 700 lignes) ;
- la base de données locale et ses données de démo ;
- ce journal, les patchs et les captures d'écran.

### Pourquoi c'est arrivé (ma responsabilité)
- Le dépôt `Endsi3g/fratex-agent` refuse l'écriture depuis cette session : je ne pouvais pas y pousser le code.
- Je produisais des patchs, mais je les gardais **dans le conteneur**. Je ne les ai pas poussés sur un dépôt accessible en écriture. Un conteneur de session est temporaire : c'était une erreur.

### Ce qui change dès maintenant
- **À la fin de chaque phase** : section du journal + patch cumulatif (`patches/TOUT-cumulatif.patch`) + commit + **push** sur la branche `claude/fratex-agent-rebuild` de `ai_engineering` (autorisé par Alexandre le 22 oct.). Jamais sur `main`.
- Les éléments récupérés sont sauvegardés dans `recovery/` (voir son `README.md`).

### Ce qui a pu être récupéré
| Élément | Récupéré ? | Source |
|---------|-----------|--------|
| Travail fait **après** 05 h 45 (courtiers, connexions, Google Agenda, barre latérale, logos, outils du courtier, présence) | Oui, mot pour mot | Transcription de la session : chaque commande et son contenu (`recovery/bash/`) |
| Trois composants complets (`real-estate-home.tsx`, `realtor-roster.tsx`, `realtor-onboarding-form.tsx`) | Oui | Contexte de la session (`recovery/files/`) |
| Travail fait **avant** 05 h 45 (phases 1 à 4, accueil, boîte de réception, barre du haut, portail, estimateur) | Non, seulement son **résumé** détaillé | `recovery/SUMMARY.txt` |
| Traductions faites par 3 agents (≈ 140 fichiers) | Non | À refaire |
| Sections B.9 à B.11 de l'ancien journal | Oui | `recovery/bash/0055.journal.md`, `0136.journal.md`, `0241.journal.md` |

### Méthode de reconstruction
1. **Environnement** : Postgres local, dépendances, migrations, données de démo réécrites (`scripts/demo-seed.ts`), script complet `scripts/setup-local.sh`.
2. **Spécification** : `REBUILD-SPEC.md` décrit précisément chaque élément perdu (formats, composants, API, pages) à partir du résumé et du code récupéré. Elle sert de brief à chaque agent.
3. **Exécution par vagues** (agents en parallèle, chacun sur des fichiers distincts, puis un relecteur indépendant par piste qui corrige) :
   - Vague 1 : fondations, API, composants d'interface.
   - Vague 2 : câblage des pages.
   - Vague 3 : traductions.
   - Vague 4 : vérification complète (revue multi-angles, parcours navigateur, captures).
4. Après chaque vague : section du journal, patch, commit, push.

### Environnement restauré (fait)
| Étape | Commande | Pourquoi |
|-------|----------|----------|
| Postgres | `initdb` puis `pg_ctl … start` dans `/tmp/pgdata` | L'API et les tests ont besoin d'une base. |
| Variables | `.env` copié de `.env.example`, `BETTER_AUTH_SECRET` aléatoire, `ALLOWED_SIGN_IN="fratex.ca"` | Sans `ALLOWED_SIGN_IN`, l'API refuse de démarrer (c'est elle qui décide qui peut se connecter). |
| Dépendances | `bun install` | |
| Migrations | `prisma migrate deploy` (+ 3 migrations additives restaurées : présence, notes, source du prospect) | Vérifié : `prisma migrate diff --from-config-datasource --to-schema` donne une migration **vide** (schéma et base identiques). |
| Données | seed du dépôt (CRM) + `scripts/demo-seed.ts` (Agence Fratex, courtière Marie Tremblay, 8 prospects couvrant chaque étape, conversations, rendez-vous, connexions Meta et SMS de démo, sessions de test) | Les chiffres reproduisent ceux des captures d'avant : médiane de première réponse 6 min, 43 % en moins de 5 min, budgets qualifiés 2 400 000 $. |

---

## Partie A — Compréhension du produit, règles, décisions

### Le produit en une phrase
Fratex Agent est un **assistant IA (SDR) pour courtiers immobiliers du Québec** : un prospect remplit un formulaire Meta, reçoit un SMS en moins de 2 minutes, l'IA le qualifie, réserve un rendez-vous dans l'agenda Google du courtier, et renvoie les conversions à Meta.

### Règles du dépôt (AGENTS.md) appliquées partout
Aucun commentaire dans le code · interface dans `packages/ui` · constantes dans un fichier de configuration par domaine · JSON validé à la frontière (Zod) · isolation par agence (`agencyId`) et par courtier (`clientId`) · une clé facultative absente ne fait jamais planter · l'intelligence vit dans `apps/agent` · aucune donnée personnelle dans les journaux · migrations additives avec retour arrière · une donnée non confirmée par le prospect reste une **suggestion**.

### Décisions
| # | Décision | Raison |
|---|----------|--------|
| D1 | Aucun `Co-Authored-By` dans les commits du produit. | Règle du dépôt (AGENTS.md), elle l'emporte. |
| D3 | Les écrans du CRM générique (Contacts, Entreprises, Affaires, Assistant IA) ne sont **pas supprimés**. Ils sont masqués de la barre latérale pour les rôles courtier. | AGENTS.md : ne pas supprimer de fonctionnalité. |
| D4 | Couleur de marque inchangée : vert `#006B4F`. | `docs/design.md` et l'interface l'utilisent. |
| D5 | Estimateur : arithmétique réelle seulement (commission, TPS/TVQ, mensualité, mise de fonds, 3 scénarios d'offre). Aucune valeur de marché inventée. | Centris n'offre pas d'API publique ; aucune estimation sans source. |
| D6 | Portail : métriques calculées uniquement depuis les données enregistrées. | « Aucune commission hypothétique ne constitue un résultat. » |
| D7 | Devise de rapport par défaut : CAD. | Fratex est au Québec. |
| D8 | Le journal et les patchs sont poussés sur `ai_engineering` après chaque phase. | Incident du 22 octobre. Autorisé par Alexandre. |

---

## Partie B — Phases

Les sections sont ajoutées à la fin de chaque phase de la reconstruction, avec de nouvelles captures.
Les anciennes sections B.9 (Courtiers), B.10 (Connexions) et B.11 (Outils du courtier) sont conservées dans `recovery/bash/*.journal.md` et seront réécrites après vérification.
