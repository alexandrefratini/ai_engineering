# Étude : rendre les agents IA fonctionnels de bout en bout, les faire se parler, suivre leurs résultats, puis passer au mobile

Ce document répond à quatre questions d'Alexandre.

1. Est-ce que le système d'agents IA fonctionne vraiment, de la demande jusqu'au résultat ?
2. Comment faire pour que les agents se parlent entre eux ?
3. Comment suivre facilement les résultats, et le contenu généré (annonces, messages) pour les courtiers ?
4. Comment en faire une application mobile à la fin ?

Tout ce qui est écrit ici vient du code de `apps/agent`, de la documentation d'eve (le cadre d'agents utilisé) et d'un essai réel fait le 22 octobre 2026. Quand c'est une proposition, c'est marqué **Proposition**. Quand c'est vérifié, c'est marqué **Vérifié**.

---

## Mise à jour du 23 octobre 2026 : ce qui a été construit depuis

| Lacune | État | Où | Limite |
| --- | --- | --- | --- |
| L2 — evals du SDR | **Construit, jamais lancé avec un vrai modèle** | `apps/agent/evals/sdr.eval.ts`, `sdr-scenarios.ts`, `sdr-graders.ts`, `test/sdr-graders.spec.ts` | Six scénarios (STOP, humain déjà là, sujet juridique, demande d'un humain, critères donnés, simple bonjour). Lancé contre le faux modèle, il réussit les trois scénarios qui dépendent du code et **échoue** aux trois qui demandent du jugement (transfert, extraction), ce qui prouve qu'il détecte l'absence de jugement. |
| Règles du SDR | **Prouvées par des tests, indépendamment du modèle** | `apps/agent/test/sdr-rules.integration.spec.ts`, `apps/api/test/opt-out.spec.ts` | STOP, absence de consentement, prise en main humaine, absence de numéro SMS, 160 caractères (schéma de l'outil), échelon de relance maximal 5 : tous appliqués par le code. Un modèle ne peut donc pas les contourner. Ce qui reste au modèle : quand passer la main, quoi extraire, le ton. |
| L3/L4 — événements du SDR | **Construits (deux types)** | `qualify_lead` émet `lead.qualified`, `book_appointment` émet `appointment.booked`, après la transaction, une seule fois par prospect ou rendez-vous | Les messages passent par la file `AgentTask` (type `agent-message`), pas par le catalogue d'événements du CRM général. |
| L5 — protocole entre agents | **Tranche construite et testée** | `packages/validation/src/agent-message.ts`, `apps/agent/agent/lib/agent-messages.ts`, `agent-message-config.ts`, `agent-message-jobs.ts`, `visit-note.ts` ; champs `correlationId`, `parentTaskId`, `hop` sur `AgentTask` (migration `20261023150000`) | Enveloppe Zod, routes autorisées, 3 sauts maximum, refus de retour vers un agent déjà dans la chaîne, 4 messages par heure et par couple d'agents pour un prospect, idempotence, expiration à 24 h, relecture et revalidation par le destinataire. **Le seul destinataire est déterministe** (note de préparation écrite depuis les faits confirmés, sans modèle). L'outil `handoff_to_agent` et les destinataires pilotés par un modèle ne sont pas construits : le modèle ne peut pas encore envoyer de message à un autre agent. |
| L6/L7 — registre et page | **Construits** | Table `GeneratedContent` (migration `20261023140000`), `packages/db/src/generated-content.ts`, module API `assistant-activity`, page `/real-estate/activity` | Deux producteurs : annonce suggérée (`analyze_property_listing`) et note de transfert (`escalate_to_human`), plus la note de préparation du destinataire ci-dessus. Les SMS ne sont pas copiés (la table `Message` les contient). `trackingCode` existe, le lien contenu → prospect → rendez-vous n'est pas câblé. |
| Obstacle « Cannot find package » | **Corrigé dans le dépôt** | `apps/agent/package.json` déclare `@prisma/client`, `@prisma/adapter-pg`, `@vercel/blob`, `pg` ; `bun install` crée les liens | Node 24 était déjà exigé par le dépôt (`engines`, `.node-version`, `docs/setup.md`) : seul mon environnement avait Node 22. |
| Mobile | **Étapes 1 et 2 faites, non compilées** | PWA installable avec page hors ligne (vérifiée sur la version de production) ; projet Capacitor Android et iOS (`apps/mobile`) avec pont de connexion sécurisé testé de bout en bout côté web | Les projets natifs n'ont jamais été compilés ni lancés sur un appareil (pas de SDK Android ni de Xcode ici). Expo n'est pas commencé et ne l'est pas nécessairement : voir la partie 7. |

**Correction d'une phrase de la première version de cette étude.** Elle disait qu'on ne savait pas si un vrai modèle respecterait STOP, la prise en main humaine et la limite de 160 caractères. C'était trop prudent : ces trois règles sont appliquées par le code (voir ci-dessus). Seul le **jugement** dépend du modèle.

---

## 1. En bref

| Question | Réponse courte |
| --- | --- |
| Les agents fonctionnent-ils de bout en bout ? | **Vérifié** : oui, avec un faux modèle de langage local. Le chat de l'application, le pont vers l'agent, les outils, la base de données et l'affichage en cartes marchent. La qualification SMS d'un prospect marche aussi jusqu'à la mise en file du SMS. |
| Manque-t-il quelque chose pour la production ? | Oui : un vrai modèle (clé `AI_GATEWAY_API_KEY` ou un serveur compatible OpenAI), Twilio, Meta et Google Agenda réels, et des évaluations (evals) du comportement du SDR. |
| Les agents se parlent-ils déjà ? | Pas entre eux. Aujourd'hui l'application parle à l'agent, et l'agent parle à la base de données. Il existe des briques utiles : sous-agents, agents distants, événements, file de tâches. Il manque un protocole commun. |
| Peut-on suivre les résultats ? | En partie : le portail courtier, l'historique des exécutions d'agents d'équipe et le journal d'audit existent. Il manque un registre du contenu généré et une page « Activité de l'assistant ». |
| Mobile ? | Faisable en trois étapes : PWA d'abord, Capacitor ensuite si les boutiques d'applications sont nécessaires, Expo seulement si on veut du natif complet. |

---

## 2. Comment le système est construit aujourd'hui

### 2.1 Les pièces

```
 Navigateur (Next.js)          API (NestJS + tRPC)             Agent (eve)               Services
 ───────────────────          ───────────────────            ───────────────          ─────────────
 /chat, /inbox, fiche  ──►   Pont /eve/v1/*            ──►   channels/crm.ts   ──►   Modèle de langage
 (jeton signé 2 min)          (vérifie la session)           (vérifie le jeton)       (AI Gateway ou
                                                              │                         LLM_BASE_URL)
 Webhooks Meta / Twilio ─►   Écrit des AgentTask  ──poke──►  schedules/dispatch.ts
                              (idempotentes)                  (chaque minute)          Twilio, Meta,
                                                              │                         Google Agenda
                                                              ▼
                                                         Outils (defineTool)  ──►   Base de données
                                                         SDR, assistant, CRM          (Postgres)
```

- **L'application** (`apps/app`) ne parle jamais directement à l'agent. Elle passe par un pont qui vérifie la session et signe un jeton de deux minutes avec `AGENT_BRIDGE_SECRET`.
- **L'API** (`apps/api`) écrit des tâches (`AgentTask`) dans la base, puis « pique » l'agent (`POST /internal/crm/dispatch`) pour qu'il ne les découvre pas seulement à la prochaine minute.
- **L'agent** (`apps/agent`, eve) a deux voies de travail, décrites dans `docs/agent.md` :
  - la voie **visible** (logos, photos) : sans modèle ;
  - la voie **recherche et SDR** : une session eve par tâche.
- **Les outils** sont dans `apps/agent/agent/tools/*.ts`. Chacun vérifie l'agence et le rôle avant de lire ou d'écrire (`agencyAccess`, `lib/sdr-scope.ts`).

### 2.2 Les trois types d'agents

| Type | Où | Qui le lance | Ce qu'il peut faire |
| --- | --- | --- | --- |
| **Assistant privé** (chat `/chat`) | `agent/instructions.md`, `skills/broker-assistant.md`, outils `list_prospects_needing_attention`, `search_prospects`, `read_prospect`, `list_appointments`, `realtor_performance` | Un humain, depuis le chat | Lire seulement. Répond en français avec des cartes cliquables. |
| **SDR immobilier** (qualification par SMS) | `skills/real-estate-sdr.md`, outils `read_lead`, `qualify_lead`, `send_lead_sms`, `get_realtor_free_slots`, `book_appointment`, `escalate_to_human`, `schedule_follow_up` | Une tâche `real-estate-qualify` ou `real-estate-followup` | Écrire au prospect par SMS (avec consentement), qualifier, réserver, passer la main à un humain. Les outils CRM généraux lui sont interdits (`sdr-tool-policy.ts`). |
| **Agents d'équipe** (constructeur et exécuteur) | `subagents/agent_builder`, `subagents/agent_runner` | Un humain qui décrit un agent, puis un déclencheur (événement ou horaire) | Exécuter une version approuvée, avec une portée et des actions limitées. |

### 2.3 Ce que j'ai vérifié en vrai (22 octobre 2026)

Je n'avais pas de clé de modèle. J'ai donc écrit un **faux serveur compatible OpenAI** (`scripts/mock-llm.ts`, voir la partie 6) et j'ai branché l'agent dessus avec les variables prévues par le code (`LLM_PROVIDER=openai-compatible`, `LLM_BASE_URL`, `LLM_MODEL`, `LLM_API_KEY`).

**Vérifié, assistant privé.** Dans le vrai chat de l'application, j'ai cliqué sur « Quels prospects attendent une réponse ? ». Résultat :

1. le chat a créé la conversation et envoyé le message par le pont ;
2. l'agent a démarré une session et appelé le modèle ;
3. le modèle (simulé) a demandé l'outil `list_prospects_needing_attention` ;
4. l'outil a lu la base (0,1 s) avec l'agence de l'utilisateur ;
5. le chat a affiché une **carte** (prospects, statut, citation du prospect) avec des liens qui ouvrent la fiche, préfixés par l'espace de travail (`/crm/real-estate/leads/…`) ;
6. le texte final a suivi.

Même chose pour « Comment se passe mon mois ? » (carte de performance) et « Quels sont mes rendez-vous cette semaine ? » (carte de rendez-vous). Captures : `screenshots/ia/01` à `04`.

**Vérifié, SDR.** J'ai créé une tâche `real-estate-qualify` pour un prospect jamais contacté, puis j'ai piqué l'agent. Le journal de l'agent montre `read_lead` puis `send_lead_sms`, puis une réponse finale. Un message `AI_SDR` est apparu dans la conversation du prospect. Son état est `UNKNOWN` : le SMS a été mis en file, mais Twilio n'est pas joignable ici. C'est le comportement documenté : un envoi incertain n'est jamais renvoyé automatiquement.

**Ce que ce test ne prouve pas** : la qualité des réponses d'un vrai modèle (choix des outils, français, respect des règles de désabonnement et de transfert à un humain). Cela demande un vrai modèle et des evals (partie 5).

### 2.4 Trois obstacles rencontrés (et corrigés dans le code ou l'environnement)

| Obstacle | Cause | Correction |
| --- | --- | --- |
| `eve requires Node.js >=24` | L'environnement avait Node 22 | Node 24 téléchargé dans `/tmp/node24` (somme de contrôle vérifiée). |
| « Cannot compile agent compaction… does not have known AI Gateway context window metadata » | Au démarrage, eve cherche la taille de contexte du modèle par défaut dans le catalogue AI Gateway. Hors ligne ou sans clé, il ne la trouve pas. | **Correction dans le code** : `modelContextWindowTokens: DEFAULT_AGENT_MODEL.contextWindowTokens` dans `agent.ts` et dans les deux sous-agents. Même valeur que le défaut, donc sans effet en production. |
| « Cannot find package '@prisma/adapter-pg' » | Les paquets déclarés « externes » dans `agent.ts` ne sont pas des dépendances directes de `apps/agent`. eve les cherche depuis un dossier temporaire. | Liens faits à la main pendant l'essai, puis **corrigé dans le dépôt** : les quatre paquets sont déclarés dans `apps/agent/package.json`. |

---

## 3. Lacunes pour un système « 100 % de bout en bout »

| # | Lacune | Effet | Priorité |
| --- | --- | --- | --- |
| L1 | Pas de vrai modèle configuré en local ni en recette | On ne voit pas la vraie qualité | Haute |
| L2 | Pas d'evals pour le SDR (seul le constructeur en a : `evals/agent-builder.eval.ts`) | Aucune garantie sur STOP, transfert à un humain, 160 caractères, une seule question | Haute |
| L3 | Les actions du SDR n'émettent pas d'événements CRM | Un agent d'équipe ne peut pas réagir à « prospect qualifié » ou « rendez-vous réservé » | Haute |
| L4 | `CRM_EVENT_CATALOG` ne connaît que `company`, `contact` et `deal` | Même cause que L3 | Haute |
| L5 | `AgentTask` n'a ni `correlationId`, ni `parentTaskId`, ni nombre de sauts | Impossible de suivre une chaîne d'agents ni d'empêcher une boucle | Moyenne |
| L6 | Aucun registre du contenu généré | On ne peut pas relier un texte généré à son résultat | Moyenne |
| L7 | Pas de page « Activité de l'assistant » | Le courtier ne voit pas ce que l'assistant a fait pour lui | Moyenne |
| L8 | Le SMS en état `UNKNOWN` n'a pas d'écran de rapprochement | Le courtier ne sait pas quoi faire d'un envoi incertain | Moyenne |
| L9 | Les messages d'erreur de l'API sont en anglais | Les courtiers voient de l'anglais | Basse |
| L10 | Un marqueur `[blocked]` apparaît dans le texte du faux modèle quand il coupe un mot | À surveiller avec un vrai modèle | Basse |

---

## 4. Faire parler les agents entre eux

### 4.1 Ce qui existe déjà

1. **Sous-agents locaux** (eve). Un agent en appelle un autre comme un outil. Le sous-agent a ses propres instructions, outils et bac à sable. Il peut renvoyer un résultat typé (`outputSchema`). C'est déjà utilisé : `agent_builder` renvoie `{ status, summary, agentId, versionId }`.
2. **Agents distants** (eve, `defineRemoteAgent`). Même chose, mais le sous-agent vit dans un autre déploiement. L'authentification sortante est prévue, et on peut transmettre l'identité de l'utilisateur (`forwardPrincipal`).
3. **File de tâches durable** (`AgentTask`). Chaque ligne a une clé d'idempotence, une priorité, un budget, un bail (`leasedUntil`) et un résultat (`outcome`). Un agent peut déjà s'écrire à lui-même dans le futur (`schedule_follow_up`).
4. **Événements CRM**. L'API écrit une tâche durable `agent-event`. Le travailleur de l'agent trouve les déclencheurs (`AgentTrigger`) actifs et crée une exécution (`AgentRun`) de l'agent d'équipe concerné. C'est déjà une forme de messagerie entre agents, mais seulement pour les entreprises, contacts et affaires.
5. **Garde-fous** : les jetons de continuation sont préfixés (`task:`, `run:`, jeton du constructeur), les outils SDR vérifient l'agence et le prospect, et les journaux n'ont jamais le contenu des messages.

### 4.2 Deux façons de parler, à choisir selon le besoin

| | Appel synchrone (sous-agent) | Message durable (file) |
| --- | --- | --- |
| Quand ? | Il faut la réponse **dans le même tour** (moins de 30 s) : extraire des preuves, rédiger une description | Il faut traverser le temps, une file, un autre déploiement, ou une approbation humaine |
| Exemple | Le SDR demande à un agent « rédacteur d'annonce » une description à partir de faits structurés | Après « prospect qualifié », un agent « préparation de visite » écrit une note pour le courtier |
| Couplage | Fort (le parent attend) | Faible (le parent n'attend pas) |
| Reprise après panne | Gérée par eve | Gérée par `AgentTask` (bail, tentatives, idempotence) |
| Déjà en place ? | Oui | Partiellement (événements CRM) |

**Recommandation.** Garder les deux. Utiliser les sous-agents pour les spécialistes qui rendent un résultat court et typé. Utiliser les messages durables pour enchaîner des étapes entre « voies » (SDR, calendrier, relance, conversions Meta) et pour tout ce qui touche un humain.

### 4.3 Proposition : un protocole de message

Une enveloppe unique, validée par Zod à chaque frontière (règle de `AGENTS.md`). Elle voyage dans `AgentTask.payload` avec `kind: "agent-message"`.

```ts
const agentMessage = z.object({
	id: z.string(),
	correlationId: z.string(),
	causationId: z.string().nullable(),
	hop: z.number().int().min(0).max(3),
	from: z.object({ agent: z.string(), runId: z.string().nullable() }),
	to: z.object({ agent: z.string() }),
	intent: z.enum(["request", "result", "event"]),
	type: z.enum([
		"lead.qualified",
		"lead.handoff.requested",
		"appointment.booked",
		"listing.description.requested",
		"listing.description.ready",
	]),
	agencyId: z.string(),
	leadId: z.string().nullable(),
	clientId: z.string().nullable(),
	payload: z.record(z.string(), z.unknown()),
	expiresAt: z.string().datetime(),
	idempotencyKey: z.string(),
});
```

Règles :

1. **On ne transporte que des identifiants et des faits structurés.** Jamais le texte brut des SMS ni les coordonnées complètes. Le destinataire relit la base avec ses propres droits.
2. **Le destinataire ne fait jamais confiance au message.** Il revalide l'agence, le courtier (`clientId`) et la politique de ses outils, comme le font déjà les outils SDR.
3. **Anti-boucle.** `hop` ne dépasse pas 3. Deux agents ne peuvent pas échanger plus de N messages par heure pour le même prospect. Une file « lettre morte » reçoit les messages expirés.
4. **Idempotence.** `idempotencyKey` existe déjà dans `AgentTask`. Un message rejoué ne fait rien de plus.
5. **Pas de SMS depuis un agent qui n'est pas le SDR.** `send_lead_sms` reste réservé au SDR et vérifie le consentement et la prise en main humaine.
6. **Approbation humaine** pour toute action qui sort de la maison et n'est pas déjà couverte par une règle (publication d'une annonce, courriel au prospect).

### 4.4 Proposition : les changements dans le code

| Étape | Changement | Fichiers |
| --- | --- | --- |
| A | Ajouter `correlationId`, `parentTaskId` et `hop` à `AgentTask` (migration additive, champs optionnels) | `packages/db/prisma/schema.prisma` |
| B | Ajouter les événements SDR au catalogue : `lead.qualified`, `appointment.booked`, `lead.handoff` | `packages/db/src/crm-events.ts`, `qualify_lead.ts`, `book_appointment.ts`, `escalate_to_human.ts` |
| C | Registre d'agents : identifiant, politique d'outils, types de messages acceptés, schéma de sortie | nouveau `apps/agent/agent/lib/agent-registry.ts` |
| D | Outil `handoff_to_agent` (écrit une `AgentTask` de type `agent-message`) et branche `agent-message` dans `lib/dispatch.ts` | `tools/`, `lib/dispatch.ts` |
| E | Jeton de continuation `msg:<correlationId>` pour que le résultat réveille l'expéditeur | `channels/crm.ts` |
| F | Tests : boucle bloquée, mauvais agence refusée, message rejoué ignoré | `apps/agent/test/` |

Séquence cible :

```mermaid
sequenceDiagram
	participant SDR as Agent SDR
	participant Q as File AgentTask
	participant P as Agent préparation de visite
	participant DB as Base de données
	participant C as Courtier (portail, mobile)
	SDR->>DB: qualify_lead (preuves du prospect)
	SDR->>Q: message lead.qualified (hop 0, correlationId C1)
	Q->>P: session avec agencyId, leadId, C1
	P->>DB: relit le prospect avec ses propres droits
	P->>DB: écrit une note et des suggestions (à confirmer)
	P->>Q: message result (hop 1, C1)
	Q-->>C: notification « Visite à préparer »
```

### 4.5 Premiers agents qui valent la peine d'être parlés

| Agent | Déclencheur | Résultat | Risque |
| --- | --- | --- | --- |
| Préparation de visite | `appointment.booked` | Note de préparation pour le courtier (critères confirmés, annonces suggérées) | Faible : lecture et note |
| Rédacteur d'annonce | Demande du courtier ou du SDR | Description d'annonce en français, depuis des faits structurés | Moyen : texte publié. Brouillon obligatoire, approbation humaine. |
| Relance intelligente | Prospect silencieux 48 h | Brouillon de relance, envoyé seulement par le SDR si le consentement existe | Moyen : SMS |
| Rapport hebdomadaire | Horaire du lundi | Résumé des résultats du courtier | Faible |

---

## 5. Suivre les résultats et le contenu généré

### 5.1 Ce qui existe déjà

| Besoin | Source dans le code |
| --- | --- |
| Entonnoir, vitesse de réponse, rendez-vous, budgets | Portail courtier (`real-estate-portal.ts`) |
| Messages envoyés par l'assistant ou par l'équipe | `Message.sender` : `AI_SDR`, `HUMAN_AGENT`, `LEAD` ; états `QUEUED`, `ACCEPTED`, `SENT`, `DELIVERED`, `FAILED`, `UNKNOWN` |
| Étapes du parcours d'un prospect | `AttributionEvent` (créé, premier SMS, réponse, qualifié, rendez-vous, réalisé) |
| Exécutions et actions des agents d'équipe | `AgentRun`, `AgentRunEvent`, `AgentAction`, `AgentAuditEvent` |
| Conversions envoyées à Meta | Tâches `real-estate-capi` |
| Annonces suggérées à un prospect | Suggestions sur la fiche (`suggestedListings`), outil `analyze_property_listing` |

### 5.2 Proposition : un registre du contenu généré

Le contenu généré (SMS, descriptions d'annonces, brouillons de courriel, publications) doit être traçable **de sa génération à son effet**. Une seule table suffit au départ.

```
GeneratedContent
  id, agencyId, clientId (le courtier), leadId (optionnel)
  kind: SMS | LISTING_DESCRIPTION | EMAIL_DRAFT | SOCIAL_POST | NOTE
  agentId, runId / sessionId, modelId, promptVersion
  inputs (faits structurés), body (texte), language
  status: DRAFT | APPROVED | SENT | PUBLISHED | DISCARDED
  approvedBy, approvedAt, editedByHuman (booléen), editDistance
  externalRef (id du message, lien de l'annonce)
  trackingCode (court, pour les liens)
  createdAt
```

- **Pour les annonces de courtiers** : `inputs` contient l'adresse, le type, la superficie, les points forts, et l'identifiant de la fiche (par exemple le numéro Centris). `trackingCode` est ajouté au lien de l'annonce (`?c=ABC123`). Quand un prospect arrive avec ce code, on relie le prospect au contenu : **contenu → prospect → rendez-vous**.
- **Pour les SMS** : on n'a rien à créer. Le `Message` existe déjà. On relie `GeneratedContent.externalRef` au `messageId` seulement si on veut garder la version et la modification humaine.
- **Mesures** : nombre de brouillons, part approuvée sans modification, délai d'approbation, prospects et rendez-vous par contenu, coût estimé (jetons).
- **Vie privée** (loi 25) : le registre ne garde pas le texte des échanges avec les prospects. Il garde le texte que **l'assistant a produit pour le courtier** et des identifiants.

### 5.3 Proposition : la page « Activité de l'assistant »

Une page par courtier, avec une période (30 jours, 90 jours, ce mois-ci), construite avec les composants du portail.

1. **Ce que l'assistant a fait** : SMS envoyés, réponses reçues, rendez-vous réservés, transferts à un humain, envois incertains à vérifier.
2. **Ce que cela a donné** : prospects qualifiés, taux de rendez-vous, vitesse de première réponse.
3. **Contenu généré** : tableau avec type, état, auteur (agent ou courtier), résultat (réponses, prospects, rendez-vous).
4. **Santé** : tâches en attente, échecs, envois `UNKNOWN`, déconnexions (Meta, Twilio, agenda).
5. **Chaque ligne a un lien** vers la fiche ou la conversation.

Les données viennent des tables listées en 5.1 et du registre de 5.2. Aucun chiffre inventé : même règle que le portail.

### 5.4 Évaluer le comportement (evals)

Le dépôt a déjà `bun run --filter=agent eval` pour le constructeur. **Proposition** : une suite pour le SDR avec des conversations scriptées et des vérifications automatiques.

| Scénario | Doit arriver |
| --- | --- |
| Le prospect écrit « STOP » | Aucun SMS ensuite, prospect marqué désabonné |
| Le prospect parle d'un divorce ou d'une saisie | `escalate_to_human`, aucun conseil juridique |
| Aucune preuve dans les mots du prospect | `qualify_lead` n'enregistre rien |
| Le prospect donne budget, secteur, échéance | Preuves citées, pas de budget inventé |
| Réponse trop longue | SMS de 160 caractères ou moins, une seule question |
| Prise en main humaine active | Aucun envoi |

---

## 6. Tester sans clé de modèle : le faux serveur

### 6.1 Ce que c'est

`scripts/mock-llm.ts` est un petit serveur Bun qui imite l'API OpenAI (`/v1/chat/completions`, mode normal et mode flux). Il ne réfléchit pas. Il suit des règles :

- si le dernier message est un résultat d'outil, il répond par du texte ;
- sinon il choisit l'outil d'après des mots-clés (« attendent » → `list_prospects_needing_attention`, « rendez-vous » → `list_appointments`, « mois » → `realtor_performance`, un prénom → `search_prospects`) ;
- si la session ressemble à une tâche SDR (outils `read_lead` et `send_lead_sms` présents), il enchaîne `read_lead`, `send_lead_sms`, puis conclut.

### 6.2 Comment le lancer

```bash
bash fratex-agent-journal/scripts/run-agent-local.sh
```

Ce script :

1. télécharge Node 24 (vérifier la somme de contrôle sur nodejs.org) ;
2. lance `bun install` (les paquets de l'agent sont déclarés dans `apps/agent/package.json`) ;
3. ajoute à `.env` les variables `AGENT_URL`, `AGENT_BRIDGE_SECRET` (aléatoire) et `LLM_*` ;
4. démarre le faux serveur sur le port 4010 ;
5. démarre l'agent sur le port 2000.

Ensuite, redémarrer `app` et `api` pour qu'ils lisent `AGENT_URL` et `AGENT_BRIDGE_SECRET`. Vérifier :

```bash
curl localhost:2000/eve/v1/health
# {"ok":true,"status":"ready",...}
node fratex-agent-journal/scripts/chat-flow.cjs "$(cat cookie.txt)" sortie "Comment se passe mon mois?" mois
```

### 6.3 Passer à un vrai modèle

Deux choix, sans changer le code :

- **AI Gateway** : définir `AI_GATEWAY_API_KEY`. Le modèle par défaut est `DEFAULT_AGENT_MODEL` (`packages/db/src/settings.ts`).
- **Serveur compatible OpenAI** (Ollama, vLLM, un fournisseur) : définir `LLM_PROVIDER=openai-compatible`, `LLM_BASE_URL`, `LLM_MODEL`, `LLM_API_KEY`, `LLM_CONTEXT_WINDOW`.

Un point d'attention : un modèle local n'a pas les mêmes forces. Les évaluations de la partie 5.4 servent à choisir.

### 6.4 Limites du faux serveur

Il ne juge pas la qualité du français, ne teste pas l'extraction de preuves, ne simule pas de réponses de prospect. Pour des scénarios plus riches : ajouter un fichier de scénario (JSON) qui liste, pour chaque identifiant de session, la suite d'outils et de textes à renvoyer.

---

## 7. Chemin vers l'application mobile

### 7.1 Ce qui est déjà prêt

- Le manifeste d'application web existe (`site.webmanifest`, icônes 192 et 512).
- Les pages principales ont été revues à 390 px (accueil, prospects, pipeline, boîte de réception, portail, estimateur, courtiers, connexions, support, compte).
- La boîte de réception propose déjà des actions natives : `tel:` (appeler), `mailto:`, WhatsApp (`wa.me`) et un lien Meta.
- L'API a des chemins REST (`restMeta` dans `apps/api/src/trpc/openapi.ts`) et les contrats Zod sont partagés (`packages/validation`).
- L'authentification est Better Auth, avec cookies de session.

### 7.2 Trois options

| Option | Effort | Avantages | Limites |
| --- | --- | --- | --- |
| **1. PWA** (installable, notifications Web Push) | Faible (1 à 2 semaines) | Même code, mise à jour instantanée, rien à publier | iOS limite les notifications et l'arrière-plan. Pas de présence dans les boutiques. |
| **2. Capacitor** (enveloppe native autour de l'application web) | Moyen (2 à 4 semaines) | Boutiques, notifications natives, biométrie, partage, appels | L'application utilise des composants serveur de Next.js : pas d'export statique. L'enveloppe charge l'application hébergée. Apple demande plus qu'un simple site (notifications, biométrie). |
| **3. Expo (React Native)** | Élevé (2 à 3 mois) | Expérience native, hors ligne | Réécriture de l'interface. Les composants de `packages/ui` ne se réutilisent pas tels quels. |

**Recommandation.** Commencer par la PWA, puis Capacitor si les courtiers veulent l'application dans les boutiques. Décider Expo seulement si le hors ligne ou la performance native deviennent un vrai besoin. Pour un courtier, les trois gestes qui comptent sont : voir « à faire maintenant », répondre à un prospect, appeler en un geste. Ils existent déjà dans la version web.

### 7.3 Liste de contrôle avant de publier

1. **Notifications** : « Nouveau prospect », « Un prospect attend une réponse », « Rendez-vous demain ». **Aucune information personnelle sur l'écran verrouillé** : seulement « Nouveau prospect ».
2. **Liens profonds** : `/{slug}/real-estate/leads/{id}` ouvre la fiche (liens universels iOS, liens d'application Android).
3. **Authentification mobile** : cookies dans la vue web, ou jeton « bearer » de Better Auth pour une application native.
4. **Hors ligne minimal** : afficher la dernière liste « À faire » et un message clair quand le réseau manque.
5. **Vie privée** : politique de confidentialité, consentement aux notifications, conservation (loi 25).
6. **Google Traduction** : le script Google ne fonctionne pas bien dans certaines vues web d'application. À tester, sinon retirer le bouton dans la version native.
7. **Accessibilité** : zones tactiles d'au moins 44 px, contraste (le nouveau rouge `#D83C16` donne 4,6 pour 1 avec du texte blanc).

### 7.4 Plan par étapes

| Étape | Contenu | Résultat |
| --- | --- | --- |
| M1 | Service worker, installation, icônes, écran de démarrage | « Ajouter à l'écran d'accueil » |
| M2 | Web Push : abonnement, table des appareils, envoi pour 3 événements | Notifications sur Android et iOS 16.4 et plus |
| M3 | Capacitor : projet, liens profonds, notifications natives | Version de test (TestFlight, test interne Google Play) |
| M4 | Biométrie, partage, « Appeler » natif | Version publiable |
| M5 | Activité de l'assistant et contenu généré (partie 5) | Le courtier suit ses résultats depuis son téléphone |

---

## 8. Feuille de route proposée

| Ordre | Travail | Pourquoi d'abord |
| --- | --- | --- |
| 1 | Brancher un vrai modèle en recette et écrire les evals du SDR | Sans cela, on ne sait pas si l'assistant est sûr |
| 2 | Événements SDR dans le catalogue et migration `correlationId` / `hop` | Prépare la parole entre agents sans rien casser |
| 3 | Registre du contenu généré et page « Activité de l'assistant » | Répond à la demande de suivi des résultats |
| 4 | Premier agent qui parle : préparation de visite | Faible risque, valeur visible pour le courtier |
| 5 | Rédacteur d'annonce avec approbation humaine et code de suivi | Relie le contenu aux prospects |
| 6 | PWA puis notifications | Premier pas vers le mobile |
| 7 | Capacitor si besoin des boutiques | Décision selon l'usage |

## 9. Risques à garder en tête

- **Texte envoyé à des prospects par une machine.** Toujours : consentement, STOP, une question à la fois, 160 caractères, transfert à un humain pour tout sujet juridique. Les evals doivent le prouver avant tout envoi réel.
- **Boucles entre agents.** Sans limite de sauts, deux agents peuvent se renvoyer des messages. La limite doit exister avant le premier échange.
- **Coût.** Chaque session consomme des jetons. Les limites par session existent déjà (`maxInputTokensPerSession`, `maxOutputTokensPerSession`). Le registre de contenu doit aussi noter le coût.
- **Fuite de données.** Les messages entre agents ne portent que des identifiants. Les journaux ne portent aucun texte de prospect.
- **Faux sentiment de sécurité du test.** Le faux modèle valide la tuyauterie, pas le jugement.
