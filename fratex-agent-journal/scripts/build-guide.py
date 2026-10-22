import html
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "guide" / "index.html"

GROUPS = [
    ("demarrer", "Démarrer"),
    ("immobilier", "Immobilier"),
    ("assistant", "Assistant IA"),
    ("crm", "CRM général"),
    ("parametres", "Paramètres"),
    ("compte", "Compte et aide"),
    ("transversal", "Partout dans l'application"),
    ("annexes", "Annexes"),
]

PAGES = [
    {
        "id": "connexion",
        "group": "demarrer",
        "title": "Connexion",
        "route": "/sign-in",
        "who": "Tout le monde",
        "img": "connexion.jpg",
        "purpose": "La porte d'entrée. On se connecte avec Google ou Microsoft. Seuls les courriels autorisés par l'entreprise peuvent entrer.",
        "features": [
            "Connexion avec le compte Google ou Microsoft de l'équipe.",
            "Connexion unique (SSO) si l'entreprise l'a configurée dans Paramètres.",
            "Message clair quand aucune méthode n'est configurée (cas de cet environnement local de démonstration).",
        ],
        "how": ["Le domaine autorisé est défini par la variable ALLOWED_SIGN_IN. Un courtier invité se connecte avec son courriel et ne voit que ses propres prospects."],
        "notes": ["Dans les captures de ce guide, la session de démonstration est créée directement dans la base de données. La page de connexion s'affiche donc sans bouton Google."],
    },
    {
        "id": "accueil",
        "group": "immobilier",
        "title": "Accueil",
        "route": "/{espace}",
        "who": "Équipe et courtier",
        "img": "accueil.jpg",
        "mobile": ["m-accueil.jpg", "m-menu.jpg"],
        "purpose": "Votre journée en un coup d'œil : ce qui attend une action de votre part, les rendez-vous des 48 prochaines heures et la répartition des prospects par étape.",
        "features": [
            "Quatre indicateurs : nouveaux prospects aujourd'hui (avec courbe des 7 derniers jours), prospects à traiter, rendez-vous aujourd'hui, première réponse médiane sur 7 jours.",
            "« À faire maintenant » : messages non lus, reprises humaines et prospects jamais contactés, du plus récent au plus ancien. Un bouton « Appeler » compose le numéro.",
            "« Rendez-vous des 48 prochaines heures » : un clic ouvre la fiche du prospect.",
            "« Pipeline » : barre proportionnelle par étape. Un clic sur une étape ouvre la liste filtrée.",
            "Deux bascules en haut à droite : Immobilier ou Ventes CRM, et Moi ou Toute l'équipe.",
            "Chaque section a un point d'interrogation qui explique ce qu'elle mesure.",
        ],
        "how": [
            "Les chiffres viennent des prospects, messages et rendez-vous enregistrés. Aucune estimation.",
            "Un courtier lié à un profil voit « Moi » par défaut. Sans lien avec un courtier, l'accueil affiche toute l'équipe et le dit.",
        ],
        "notes": ["Sur mobile, les boutons de bascule passent sous le titre. Le menu s'ouvre avec le bouton en haut à gauche."],
    },
    {
        "id": "accueil-ventes",
        "group": "immobilier",
        "title": "Accueil, vue Ventes CRM",
        "route": "/{espace}?vue=ventes",
        "who": "Équipe",
        "img": "accueil-ventes.jpg",
        "purpose": "Le tableau de bord du CRM général : affaires conclues, pipeline ouvert, taux de réussite et affaire moyenne.",
        "features": [
            "Totaux dans la devise de présentation (dollar canadien par défaut).",
            "Courbe des conclusions et du nouveau pipeline sur six mois.",
            "Anneau du pipeline ouvert par étape.",
            "Liste des plus grosses affaires ouvertes et des tâches en retard.",
        ],
        "how": ["Les affaires dans une autre devise sont converties avec les taux de Paramètres, Devises. Sans taux, l'affaire est exclue des totaux et le dit."],
        "notes": ["Cette vue sert à l'équipe de vente. Le courtier n'en a pas besoin."],
    },
    {
        "id": "prospects",
        "group": "immobilier",
        "title": "Prospects",
        "route": "/{espace}/real-estate/leads",
        "who": "Équipe et courtier",
        "img": "prospects.jpg",
        "mobile": ["m-prospects.jpg"],
        "purpose": "Tous les prospects au même endroit, qu'ils viennent d'une publicité Meta, d'une référence, d'un appel ou d'une visite libre.",
        "features": [
            "Recherche par nom, téléphone ou secteur, et filtre par statut.",
            "Colonnes : prospect (avec téléphone cliquable), statut et projet, score, budget maximal, secteur, courtier, dernière activité.",
            "Un clic sur la ligne ouvre la fiche. Le téléphone et le courriel sont cliquables partout.",
            "« Nouveau prospect » : ajout à la main avec source, projet, note, consentement SMS et choix de lancer l'assistant. Les doublons sont détectés.",
            "« Charger la suite » quand il y a plus de prospects que la page.",
        ],
        "how": [
            "Un courtier ne voit que ses prospects. L'équipe voit tout et la colonne « Courtier ».",
            "Une valeur non confirmée par le prospect s'affiche « À confirmer », jamais comme un fait.",
        ],
        "notes": ["Sur mobile, les colonnes secondaires sont masquées pour que le tableau tienne dans l'écran."],
    },
    {
        "id": "prospects-vide",
        "group": "immobilier",
        "title": "Prospects, état vide",
        "route": "/{espace}/real-estate/leads?search=…",
        "who": "Équipe et courtier",
        "img": "prospects-vide.jpg",
        "purpose": "Ce que l'on voit quand aucun prospect ne correspond. Chaque liste de l'application a un état vide qui explique quoi faire ensuite.",
        "features": [
            "Explication en une phrase.",
            "Bouton « Effacer les filtres ».",
            "Sans aucun prospect dans l'agence, un autre message mène aux connexions (pour l'équipe).",
        ],
        "how": [],
        "notes": [],
    },
    {
        "id": "fiche",
        "group": "immobilier",
        "title": "Fiche d'un prospect",
        "route": "/{espace}/real-estate/leads/{id}",
        "who": "Équipe et courtier",
        "img": "fiche.jpg",
        "mobile": ["m-fiche.jpg"],
        "purpose": "Tout ce que l'on sait d'un prospect, et ce que l'assistant a fait avec lui. C'est la page où se prennent les décisions.",
        "features": [
            "En-tête : score sur 100, statut, projet, téléphone et courriel cliquables, courtier.",
            "Réaffecter le courtier, changer l'étape, appeler, ouvrir la conversation.",
            "Barre d'étapes : reçu, contacté, qualification, qualifié, rendez-vous fixé, rendez-vous réalisé.",
            "Budget, secteur, échéance et prochain rendez-vous en quatre cases.",
            "Qualification : sept critères. Une valeur soulignée a été confirmée par le prospect. Survolez-la pour lire sa réponse.",
            "Rendez-vous : ajouter, marquer réalisé, absent ou annulé.",
            "Notes : ce que vous savez et que l'assistant ne voit pas. Ctrl+Entrée enregistre.",
            "Derniers messages, propriétés suggérées, suivi et consentement, historique, export vers le CRM du courtier.",
        ],
        "how": [
            "Les critères viennent de citations réelles du prospect. Les suggestions de propriétés ne changent jamais les critères confirmés.",
            "Sans consentement aux SMS, l'assistant n'envoie rien. La preuve du consentement est dans « Suivi et consentement ».",
            "Changer l'issue d'un rendez-vous met à jour le pipeline et les conversions envoyées à Meta.",
        ],
        "notes": ["Chaque section a un point d'interrogation avec son explication."],
    },
    {
        "id": "pipeline",
        "group": "immobilier",
        "title": "Pipeline",
        "route": "/{espace}/real-estate/pipeline",
        "who": "Équipe et courtier",
        "img": "pipeline.jpg",
        "mobile": ["m-pipeline.jpg"],
        "purpose": "Les prospects classés par étape, du premier SMS au rendez-vous réalisé.",
        "features": [
            "Quatre indicateurs : prospects, qualifiés, rendez-vous, taux de rendez-vous.",
            "Une colonne par étape. Chaque carte montre le nom, le projet, le téléphone (cliquable), le score et le courtier.",
            "Un clic sur la carte ouvre la fiche.",
            "Une colonne vide affiche « Aucun prospect ».",
        ],
        "how": ["Les étapes se changent depuis la fiche du prospect. Sur mobile, chaque colonne est une page que l'on fait glisser."],
        "notes": [],
    },
    {
        "id": "boite",
        "group": "immobilier",
        "title": "Boîte de réception",
        "route": "/{espace}/real-estate/inbox",
        "who": "Équipe et courtier",
        "img": "boite-conversation.jpg",
        "mobile": ["m-boite-liste.jpg", "m-boite-conversation.jpg"],
        "purpose": "Toutes les conversations avec les prospects, SMS et courriels, dans une seule liste.",
        "features": [
            "Filtres : Tous, Non lus, Reprise humaine. Recherche par nom, téléphone ou message.",
            "Conversation par jour, avec l'état de chaque SMS (livré, en attente, échec).",
            "Écrire un SMS de 160 caractères au plus. L'envoi met l'assistant en pause pour ce prospect.",
            "« Reprendre la main » et « Rendre à l'assistant ».",
            "Barre de contact : Appeler, SMS, Courriel, WhatsApp et Messenger (pour les prospects venus de Meta).",
            "Ouvrir une conversation la marque comme lue.",
        ],
        "how": [
            "Seuls les SMS envoyés dans Fratex sont enregistrés dans la fiche. L'appel, le courriel, WhatsApp et Meta s'ouvrent dans leur application et ne sont pas enregistrés.",
            "Un SMS « incertain » n'est jamais renvoyé automatiquement.",
        ],
        "notes": ["Fratex lit les courriels synchronisés mais ne les envoie pas : « Écrire un courriel » ouvre votre messagerie."],
    },
    {
        "id": "portail",
        "group": "immobilier",
        "title": "Portail courtier",
        "route": "/{espace}/real-estate/portal",
        "who": "Équipe et courtier",
        "img": "portail.jpg",
        "mobile": ["m-portail.jpg"],
        "purpose": "Ce que l'assistant a réellement accompli pour un courtier : rapidité de réponse, rendez-vous obtenus, budgets confirmés.",
        "features": [
            "Choix du courtier (équipe) et de la période : 30 jours, 90 jours, ce mois-ci.",
            "Indicateurs : prospects reçus, première réponse médiane, rendez-vous obtenus, budgets qualifiés.",
            "Entonnoir : reçus, contactés, ont répondu, qualifiés, rendez-vous, rendez-vous réalisés.",
            "Messages envoyés par l'assistant et par l'équipe, réponses reçues.",
            "Projets, sources (Meta Lead Ads, référence, etc.), prospects récents, rendez-vous à venir.",
        ],
        "how": ["Chaque chiffre est calculé à partir des données enregistrées. Aucune commission hypothétique."],
        "notes": [],
    },
    {
        "id": "estimateur",
        "group": "immobilier",
        "title": "Estimateur et offres",
        "route": "/{espace}/real-estate/valuation",
        "who": "Équipe et courtier",
        "img": "estimateur.jpg",
        "mobile": ["m-estimateur.jpg"],
        "purpose": "Préparer une offre d'achat : mise de fonds, assurance prêt hypothécaire, taxe de bienvenue et mensualité, avec trois offres comparées.",
        "features": [
            "Propriété : prix demandé, adresse et lien de l'annonce (facultatifs).",
            "Financement : mise de fonds, taux, amortissement, municipalité, commission.",
            "Comparer 3 offres : un rabais par colonne, tout se recalcule à la frappe.",
            "Fonds requis à la signature : mise de fonds, taxe de bienvenue et taxe sur la prime d'assurance.",
            "Lier la propriété à un prospect comme suggestion.",
        ],
        "how": [
            "Taux fixe canadien : intérêts composés deux fois par an, paiements mensuels. Sous 20 % de mise de fonds, la prime SCHL s'ajoute au prêt.",
            "Le barème a une date de vérification. C'est une simulation indicative : aucune valeur marchande n'est estimée.",
        ],
        "notes": ["À confirmer auprès de la municipalité et du prêteur avant de s'engager."],
    },
    {
        "id": "courtiers",
        "group": "immobilier",
        "title": "Courtiers",
        "route": "/{espace}/real-estate/realtors",
        "who": "Équipe",
        "img": "courtiers.jpg",
        "mobile": ["m-courtiers.jpg"],
        "purpose": "Les courtiers servis par l'agence, leurs résultats et ce qu'il reste à configurer pour que l'assistant travaille pour eux.",
        "features": [
            "Indicateurs : courtiers actifs, prêts à recevoir, prospects reçus, rendez-vous obtenus.",
            "Pour chaque courtier : coordonnées cliquables, prospects, rendez-vous, dernier prospect.",
            "État de configuration : Meta, Agenda, SMS. Un élément barré reste à faire.",
            "« Terminer la configuration » mène à la prochaine étape manquante. « Portail » ouvre ses résultats.",
            "« Ajouter un courtier ».",
        ],
        "how": [],
        "notes": [],
    },
    {
        "id": "nouveau-courtier",
        "group": "immobilier",
        "title": "Nouveau courtier",
        "route": "/{espace}/real-estate/realtors/new",
        "who": "Équipe",
        "img": "nouveau-courtier.jpg",
        "purpose": "Créer le profil d'un courtier : coordonnées, secteurs, types de propriété et outils.",
        "features": [
            "Identité : nom, courriel, téléphone, bannière, numéro de permis OACIQ.",
            "Prospection : secteurs desservis et types de propriété.",
            "Outils : CRM du courtier, fuseau horaire, lien de réservation.",
        ],
        "how": ["Les connexions (formulaire Meta, agenda, numéro SMS) se font ensuite, étape par étape depuis la liste des courtiers."],
        "notes": [],
    },
    {
        "id": "onboarding-courtier",
        "group": "immobilier",
        "title": "Ajouter un courtier (page d'accueil)",
        "route": "/onboarding/realtor",
        "who": "Équipe",
        "img": "onboarding-courtier.jpg",
        "purpose": "La même fiche, hors de l'application, pour l'intégration d'un nouveau courtier.",
        "features": [
            "Barre du haut avec retour aux courtiers et accès à l'application.",
            "Mêmes sections que « Nouveau courtier ».",
        ],
        "how": [],
        "notes": ["La barre du haut a été ajoutée pour qu'on ne reste jamais sans chemin de retour."],
    },
    {
        "id": "assistant",
        "group": "assistant",
        "title": "Assistant IA",
        "route": "/{espace}/chat",
        "who": "Équipe",
        "img": "assistant-accueil.jpg",
        "mobile": ["m-assistant.jpg"],
        "purpose": "Poser des questions en français sur ses prospects, ses rendez-vous et son mois, ou décrire un agent d'équipe à créer.",
        "features": [
            "Questions rapides : prospects en attente, fiche du prospect le plus avancé, rendez-vous de la semaine, résultats du mois.",
            "Cartes dans la réponse : liste de prospects, fiche, rendez-vous, performance. Chaque ligne ouvre la fiche.",
            "Historique des conversations privées. Une conversation peut être partagée.",
            "Agents suggérés pour créer une automatisation.",
        ],
        "how": [
            "L'assistant lit seulement. Il est limité à l'agence de la personne connectée. Un courtier ne voit que ses prospects.",
            "Dans les captures, un faux modèle de langage local répond. Les cartes viennent des vrais outils.",
        ],
        "notes": ["Voir ETUDE-AGENTS-IA.md pour l'essai de bout en bout."],
    },
    {
        "id": "assistant-conversation",
        "group": "assistant",
        "title": "Conversation avec l'assistant",
        "route": "/{espace}/chat/{id}",
        "who": "Équipe",
        "img": "assistant-conversation.jpg",
        "purpose": "Une réponse avec sa carte de résultats.",
        "features": [
            "Étape de l'outil dépliable (« A repéré les prospects qui attendent une action »).",
            "Carte : état, courtier, dernière citation du prospect, lien vers la fiche.",
            "Copier, « utile » et « pas utile ».",
        ],
        "how": ["Le texte sous la carte est ici celui du faux modèle. Avec un vrai modèle, c'est un résumé en français."],
        "notes": [],
    },
    {
        "id": "agents",
        "group": "assistant",
        "title": "Agents de l'équipe",
        "route": "/{espace}/agents",
        "who": "Équipe",
        "img": "agents.jpg",
        "purpose": "Les automatisations durables créées à partir de conversations privées, après vérification et déploiement.",
        "features": [
            "Liste des agents déployés, avec leur état.",
            "Création à partir d'une conversation privée (« Créer un agent »).",
            "Déploiement : un agent déployé est visible par toute l'équipe.",
        ],
        "how": ["Un agent n'agit que dans la portée et avec les actions approuvées au déploiement."],
        "notes": [],
    },
    {
        "id": "contacts",
        "group": "crm",
        "title": "Contacts",
        "route": "/{espace}/contacts",
        "who": "Équipe",
        "img": "contacts.jpg",
        "purpose": "Toutes les personnes du CRM général, avec leur entreprise et leur responsable. Distinct des prospects immobiliers.",
        "features": [
            "Recherche, filtres, tri, colonnes, vues enregistrées, archives.",
            "Courriel cliquable. Un clic sur la ligne ouvre la fiche.",
            "Création rapide d'un contact.",
        ],
        "how": [],
        "notes": ["Les données de démonstration de cette page sont des exemples traduits."],
    },
    {
        "id": "entreprises",
        "group": "crm",
        "title": "Entreprises",
        "route": "/{espace}/companies",
        "who": "Équipe",
        "img": "entreprises.jpg",
        "purpose": "Les comptes du CRM, avec leurs affaires ouvertes et leur dernier contact.",
        "features": ["Recherche, filtres, tri, colonnes, vues, archives.", "Enrichissement automatique des fiches d'entreprise.", "Nombre de contacts et d'affaires ouvertes."],
        "how": [],
        "notes": [],
    },
    {
        "id": "affaires",
        "group": "crm",
        "title": "Affaires",
        "route": "/{espace}/deals",
        "who": "Équipe",
        "img": "affaires.jpg",
        "purpose": "Le pipeline de vente et tout ce qui est déjà clôturé.",
        "features": [
            "Étape, montant, responsable et date de clôture.",
            "Montants dans la devise d'origine. Total en dollars canadiens en bas de page.",
            "Filtres, tri, colonnes, archives.",
        ],
        "how": ["La devise de présentation se change dans Paramètres, Devises."],
        "notes": [],
    },
    {
        "id": "reglages",
        "group": "parametres",
        "title": "Général",
        "route": "/{espace}/settings",
        "who": "Équipe et courtier",
        "img": "reglages.jpg",
        "purpose": "Le nom de l'espace de travail, la clé de recherche d'entreprises, la durée de conservation des fiches archivées et le modèle de l'agent de recherche.",
        "features": ["Nom et site web de l'entreprise.", "Clé de recherche d'entreprises (facultative).", "Durée de conservation des fiches archivées (180 jours par défaut).", "Modèle de l'agent de recherche."],
        "how": ["Une clé facultative absente ne bloque jamais l'application."],
        "notes": [],
    },
    {
        "id": "suivi",
        "group": "parametres",
        "title": "Suivi et analyses",
        "route": "/{espace}/settings/tracking",
        "who": "Équipe",
        "img": "suivi.jpg",
        "purpose": "Mesurer les visites du site pour les relier aux prospects.",
        "features": ["Domaines autorisés et script de suivi à copier.", "Liaison automatique entre domaines.", "Limiter le suivi aux domaines listés."],
        "how": [],
        "notes": [],
    },
    {
        "id": "connexions",
        "group": "parametres",
        "title": "Connexions",
        "route": "/{espace}/settings/connections",
        "who": "Équipe",
        "img": "connexions.jpg",
        "mobile": ["m-connexions.jpg"],
        "purpose": "Les outils qui apportent les prospects à Fratex et ce que l'assistant a le droit d'envoyer en votre nom.",
        "features": [
            "Chaîne de prospection : Meta Lead Ads, SMS Twilio, Assistant IA, Google Agenda des courtiers. L'avancement est « n/4 prêts ».",
            "Outils de l'équipe : Google Workspace, Microsoft 365, Slack.",
            "« Ajouter un outil ». Chaque maillon a un bouton Gérer ou Configurer.",
        ],
        "how": ["Tant qu'un maillon manque, l'assistant ne peut pas travailler seul. Seul un maillon entièrement prêt s'affiche en vert."],
        "notes": [],
    },
    {
        "id": "connexion-meta",
        "group": "parametres",
        "title": "Connexion Meta Lead Ads",
        "route": "/{espace}/settings/connections/meta-ads",
        "who": "Équipe",
        "img": "connexion-meta.jpg",
        "purpose": "Relier le formulaire de publicité d'un courtier. Chaque prospect qui le remplit arrive dans Fratex et reçoit un SMS en moins de 2 minutes.",
        "features": ["Courtier qui reçoit les prospects.", "Adresse de rappel (webhook) à copier dans Meta.", "Identifiants : compte publicitaire, campagne, formulaire, page, jeton d'accès, pixel (facultatif)."],
        "how": ["Chaque identifiant dit où le trouver dans Meta Business Suite."],
        "notes": [],
    },
    {
        "id": "connexion-twilio",
        "group": "parametres",
        "title": "Connexion SMS Twilio",
        "route": "/{espace}/settings/connections/twilio",
        "who": "Équipe",
        "img": "connexion-twilio.jpg",
        "purpose": "Le numéro de l'agence qui envoie le premier SMS et reçoit les réponses.",
        "features": ["Adresse de rappel à coller dans Twilio.", "Account SID, jeton d'authentification, numéro SMS au format international."],
        "how": ["Les accusés de livraison confirment chaque envoi."],
        "notes": [],
    },
    {
        "id": "connexion-gemini",
        "group": "parametres",
        "title": "Connexion Assistant IA",
        "route": "/{espace}/settings/connections/gemini",
        "who": "Équipe",
        "img": "connexion-gemini.jpg",
        "purpose": "Le modèle qui qualifie les prospects par SMS et propose les rendez-vous.",
        "features": ["État de l'assistant (prêt ou clé manquante).", "Fournisseur, modèle et variables à changer."],
        "how": ["Dans cette capture, le faux modèle local est configuré. En production, un vrai modèle est branché."],
        "notes": [],
    },
    {
        "id": "connexion-agenda",
        "group": "parametres",
        "title": "Connexion Google Agenda des courtiers",
        "route": "/{espace}/settings/connections/realtor-calendar",
        "who": "Équipe",
        "img": "connexion-agenda.jpg",
        "purpose": "Chaque courtier relie son agenda. L'assistant lit les disponibilités et inscrit les visites réservées.",
        "features": ["Jours et heures de visite, durée.", "Bouton « Connecter l'agenda ».", "Saisie avancée pour l'équipe technique."],
        "how": ["Sans agenda, l'assistant propose le lien de réservation du courtier."],
        "notes": ["Sans les clés Google dans le fichier .env, le bouton explique ce qui manque."],
    },
    {
        "id": "connexion-slack",
        "group": "parametres",
        "title": "Connexion Slack",
        "route": "/{espace}/settings/connections/slack",
        "who": "Équipe",
        "img": "connexion-slack.jpg",
        "purpose": "Une porte d'entrée et une porte de sortie. Ce qu'il en fait ensuite, c'est à vous d'en décider, une automatisation à la fois.",
        "features": ["Ce que vous accordez, groupe par groupe.", "Ce qu'elle ne fera jamais.", "Point de départ pour les automatisations d'équipe."],
        "how": [],
        "notes": [],
    },
    {
        "id": "devises",
        "group": "parametres",
        "title": "Devises",
        "route": "/{espace}/settings/currencies",
        "who": "Équipe",
        "img": "devises.jpg",
        "purpose": "La devise des chiffres du CRM, et la façon dont les autres devises sont converties.",
        "features": ["Devise de présentation (dollar canadien).", "Taux de change récupérés chaque jour, ou saisis à la main (la saisie a priorité).", "Devises utilisées dans les affaires."],
        "how": ["Changer la devise reconvertit chaque affaire au taux du jour."],
        "notes": [],
    },
    {
        "id": "membres",
        "group": "parametres",
        "title": "Membres",
        "route": "/{espace}/settings/members",
        "who": "Équipe",
        "img": "membres.jpg",
        "purpose": "Les personnes qui ont accès à Fratex.",
        "features": ["Recherche, tri, filtre par rôle.", "Courriel cliquable.", "Changer le rôle (propriétaire ou administrateur)."],
        "how": [],
        "notes": [],
    },
    {
        "id": "cles-api",
        "group": "parametres",
        "title": "Clés API",
        "route": "/{espace}/settings/api-keys",
        "who": "Équipe",
        "img": "cles-api.jpg",
        "purpose": "Clés pour connecter d'autres outils à Fratex.",
        "features": ["Nouvelle clé API.", "Une clé n'est affichée qu'une seule fois, à sa création.", "État vide qui l'explique."],
        "how": [],
        "notes": [],
    },
    {
        "id": "sso",
        "group": "parametres",
        "title": "SSO",
        "route": "/{espace}/settings/sso",
        "who": "Équipe",
        "img": "sso.jpg",
        "purpose": "Connexion unique avec le fournisseur d'identité de l'entreprise.",
        "features": ["Ajouter un fournisseur.", "Domaine de courriel, émetteur, adresse de redirection."],
        "how": ["Sans SSO, la connexion se fait avec Google ou Microsoft."],
        "notes": [],
    },
    {
        "id": "compte",
        "group": "compte",
        "title": "Mon compte",
        "route": "/{espace}/account",
        "who": "Tout le monde",
        "img": "compte.jpg",
        "mobile": ["m-compte.jpg"],
        "purpose": "Votre profil, votre connexion, vos appareils et votre affichage.",
        "features": [
            "Profil : modifier le nom affiché.",
            "Agences et rôles : ce que vous avez le droit de voir et de faire.",
            "Connexion et courriel : fournisseur, synchronisation en lecture seule.",
            "Appareils connectés : déconnecter un appareil ou tous les autres.",
            "Affichage : thème clair, sombre ou automatique, langue, fuseau, devise.",
            "Raccourcis clavier, demandes d'aide, déconnexion.",
        ],
        "how": ["Le courriel vient du compte Google ou Microsoft et ne se change pas ici."],
        "notes": ["Accessible par le bouton en bas de la barre latérale."],
    },
    {
        "id": "support",
        "group": "compte",
        "title": "Support",
        "route": "/{espace}/support",
        "who": "Tout le monde",
        "img": "support.jpg",
        "mobile": ["m-support.jpg"],
        "purpose": "Envoyer une demande à l'équipe Fratex en quelques secondes : un problème, une question ou une idée.",
        "features": [
            "Trois choix en un clic. La page où vous étiez est préremplie.",
            "Un seul champ obligatoire : le message (10 caractères au minimum).",
            "La page, l'heure et la taille de l'écran sont jointes automatiquement.",
            "Mes demandes avec leur état : ouverte, en cours, résolue.",
            "Réponses rapides aux situations fréquentes.",
            "Pour les propriétaires et administrateurs : « Demandes de l'équipe » avec changement d'état.",
        ],
        "how": [
            "Menu du compte, « Signaler un problème » ouvre cette page avec la page courante.",
            "Limite de 10 demandes par heure et par personne.",
        ],
        "notes": ["L'adresse courriel d'appui affichée (support@fratex.ca) est à confirmer."],
    },
    {
        "id": "courtier",
        "group": "transversal",
        "title": "Vue du courtier",
        "route": "(Marie Tremblay, rôle courtier)",
        "who": "Courtier",
        "img": "courtier-accueil.jpg",
        "extra": ["courtier-prospects.jpg", "courtier-boite.jpg", "courtier-portail.jpg"],
        "purpose": "Ce que voit un courtier : seulement ses propres prospects, sa boîte de réception, son portail.",
        "features": ["Barre latérale réduite : Accueil, Prospects, Pipeline, Boîte de réception, Portail, Estimateur, puis Mon compte, Support et Paramètres.", "Pas de pages Courtiers, Assistant IA ni CRM général. Les pages de paramètres réservées à l'équipe n'apparaissent pas dans la recherche.", "L'accueil montre « Moi » par défaut.", "Toutes les actions sur ses propres prospects sont disponibles."],
        "how": ["L'isolation est faite côté serveur (agence et courtier) et pas seulement dans l'affichage."],
        "notes": [],
    },
    {
        "id": "recherche",
        "group": "transversal",
        "title": "Recherche Ctrl+K",
        "route": "(partout)",
        "who": "Tout le monde",
        "img": "recherche.jpg",
        "purpose": "Aller à une page ou à un prospect sans cliquer.",
        "features": ["Pages de l'application et prospects (au moins deux lettres).", "Flèches pour naviguer, Entrée pour ouvrir, Échap pour fermer."],
        "how": [],
        "notes": [],
    },
    {
        "id": "presence",
        "group": "transversal",
        "title": "Présence de l'équipe",
        "route": "(barre du haut)",
        "who": "Équipe",
        "img": "presence.jpg",
        "purpose": "Voir qui est en ligne et sur quelle page.",
        "features": ["Avatars avec point vert pour les personnes en ligne.", "Liste : nom, page actuelle (lien) ou dernière visite."],
        "how": ["La page affichée est un libellé, jamais l'adresse complète."],
        "notes": [],
    },
    {
        "id": "traduction",
        "group": "transversal",
        "title": "Traduction avec Google",
        "route": "(barre du haut)",
        "who": "Tout le monde",
        "img": "traduction.jpg",
        "purpose": "Traduire l'interface dans la langue de la personne (anglais, espagnol, portugais, italien, arabe, créole haïtien, chinois, russe, hindi).",
        "features": ["Menu avec la langue active cochée.", "Confirmation avant la première traduction.", "Retour au français en un clic."],
        "how": [
            "Le texte affiché est envoyé à Google pour être traduit, y compris les noms et messages des prospects. Les téléphones et courriels ne sont pas traduits.",
            "Les chiffres qui se mettent à jour seuls peuvent rester figés : rechargez la page.",
        ],
        "notes": ["Cet environnement n'a pas accès à Google. Le menu, la confirmation et le cookie ont été vérifiés, pas la traduction elle-même."],
    },
    {
        "id": "menu-compte",
        "group": "transversal",
        "title": "Menu du compte",
        "route": "(barre du haut, avatar)",
        "who": "Tout le monde",
        "img": "menu-compte.jpg",
        "purpose": "Accès rapide au support, au mode sombre et à la déconnexion.",
        "features": ["Signaler un problème (avec la page courante).", "Aide et support.", "Mode sombre ou clair.", "Se déconnecter."],
        "how": [],
        "notes": [],
    },
    {
        "id": "sombre",
        "group": "transversal",
        "title": "Mode sombre",
        "route": "(Mon compte, Affichage)",
        "who": "Tout le monde",
        "img": "sombre-accueil.jpg",
        "extra": ["sombre-boite.jpg"],
        "purpose": "Le même écran avec le thème sombre. Le choix automatique suit le réglage de l'appareil.",
        "features": ["Le rouge de la marque reste lisible.", "Le vert reste réservé aux états entièrement réussis."],
        "how": [],
        "notes": [],
    },
    {
        "id": "agenda-connecte",
        "group": "transversal",
        "title": "Agenda connecté",
        "route": "/agenda-connecte?statut=ok",
        "who": "Courtier",
        "img": "agenda-connecte.jpg",
        "purpose": "La page où arrive le courtier après avoir autorisé Google Agenda.",
        "features": ["Confirme que l'agenda est connecté.", "Peut être fermée."],
        "how": ["Le lien d'autorisation est signé : il ne peut pas être modifié pour agir sur un autre courtier."],
        "notes": [],
    },
]

ANNEXES = [
    {
        "id": "statuts",
        "title": "Les étapes d'un prospect",
        "body": """
<table><thead><tr><th>Étape</th><th>Sens</th></tr></thead><tbody>
<tr><td>Nouveau</td><td>Le prospect est arrivé. Aucun SMS n'est encore envoyé.</td></tr>
<tr><td>Contacté</td><td>L'assistant a envoyé le premier SMS.</td></tr>
<tr><td>Qualification</td><td>Le prospect répond. L'assistant confirme ses critères.</td></tr>
<tr><td>Qualifié</td><td>Projet, secteur, budget et échéance confirmés par le prospect.</td></tr>
<tr><td>RDV fixé</td><td>Un rendez-vous est au calendrier du courtier.</td></tr>
<tr><td>RDV réalisé</td><td>Le rendez-vous a eu lieu. La conversion est envoyée à Meta si la connexion est configurée.</td></tr>
<tr><td>À relancer</td><td>À reprendre plus tard.</td></tr>
<tr><td>Non intéressé, invalide</td><td>Sortis du parcours.</td></tr>
</tbody></table>""",
    },
    {
        "id": "couleurs",
        "title": "Les couleurs",
        "body": """
<ul>
<li><b>Rouge-orangé</b> (<code>#D83C16</code>) : la marque, les boutons d'action, les étapes en cours.</li>
<li><b>Vert</b> : réservé aux états entièrement réussis (connecté, livré, confirmé, 100 % terminé).</li>
<li><b>Gris</b> : le reste. Une valeur « À confirmer » est grise, jamais un fait.</li>
<li>Une action destructive ne repose jamais sur la couleur seule : elle a une étiquette et une confirmation.</li>
</ul>""",
    },
    {
        "id": "infobulles",
        "title": "Les points d'interrogation",
        "body": "<p>Chaque page importante et chaque section ont un petit « ? ». Il explique en une ou deux phrases ce que l'on voit et d'où vient le chiffre. Survolez-le ou touchez-le.</p>",
    },
    {
        "id": "connus",
        "title": "Ce qui n'est pas encore vérifié",
        "body": """
<ul>
<li>La qualité des réponses d'un vrai modèle de langage (seul un faux modèle a été essayé).</li>
<li>L'envoi réel de SMS (Twilio), l'arrivée de prospects Meta et la connexion de Google Agenda : aucun service externe n'est joignable dans cet environnement.</li>
<li>La traduction elle-même par Google.</li>
<li>L'adresse courriel du support.</li>
<li>L'application mobile native : seule la version web adaptée au mobile existe.</li>
</ul>""",
    },
]


def esc(text):
    return html.escape(text, quote=True)


def img_tag(name, alt, cls=""):
    return f'<a class="shot {cls}" href="images/{esc(name)}" data-lightbox><img loading="lazy" src="images/{esc(name)}" alt="{esc(alt)}"></a>'


def render_page(page):
    parts = [f'<section class="page" id="{page["id"]}">']
    parts.append(f'<header><h2>{esc(page["title"])}</h2><p class="meta"><code>{esc(page["route"])}</code><span class="who">{esc(page["who"])}</span></p></header>')
    parts.append(f'<p class="purpose">{esc(page["purpose"])}</p>')
    shots = [img_tag(page["img"], f'Capture de la page {page["title"]} sur ordinateur', "desktop")]
    for extra in page.get("extra", []):
        shots.append(img_tag(extra, f'Capture supplémentaire : {page["title"]}', "desktop"))
    parts.append('<div class="shots">' + "".join(shots) + "</div>")
    if page.get("mobile"):
        parts.append('<div class="shots mobile">' + "".join(img_tag(m, f'Capture mobile : {page["title"]}', "phone") for m in page["mobile"]) + "</div>")
    if page["features"]:
        parts.append("<h3>Ce que vous pouvez faire</h3><ul>" + "".join(f"<li>{esc(f)}</li>" for f in page["features"]) + "</ul>")
    if page["how"]:
        parts.append("<h3>Comment ça marche</h3><ul>" + "".join(f"<li>{esc(f)}</li>" for f in page["how"]) + "</ul>")
    if page["notes"]:
        parts.append('<div class="note"><b>À savoir.</b> ' + " ".join(esc(n) for n in page["notes"]) + "</div>")
    parts.append("</section>")
    return "\n".join(parts)


def render_nav():
    out = []
    for gid, gtitle in GROUPS:
        if gid == "annexes":
            items = ANNEXES
            links = "".join(f'<li><a href="#{a["id"]}">{esc(a["title"])}</a></li>' for a in items)
        else:
            links = "".join(f'<li><a href="#{p["id"]}">{esc(p["title"])}</a></li>' for p in PAGES if p["group"] == gid)
        out.append(f'<div class="group"><h4>{esc(gtitle)}</h4><ul>{links}</ul></div>')
    return "\n".join(out)


def render_main():
    parts = []
    for gid, gtitle in GROUPS:
        parts.append(f'<h1 class="group-title" id="g-{gid}">{esc(gtitle)}</h1>')
        if gid == "annexes":
            for a in ANNEXES:
                parts.append(f'<section class="page" id="{a["id"]}"><header><h2>{esc(a["title"])}</h2></header>{a["body"]}</section>')
        else:
            parts.extend(render_page(p) for p in PAGES if p["group"] == gid)
    return "\n".join(parts)


TEMPLATE = """<!doctype html>
<html lang="fr-CA">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="claude:viewport-fit-sides" content="cover">
<title>Guide Fratex Agent</title>
<style>
:root{--bg:#fff;--fg:#171717;--muted:#6b6b6b;--line:#e5e5e5;--card:#fafafa;--brand:#d83c16;--brand-fg:#fff;--note:#fff5f2}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#111;--fg:#f2f2f2;--muted:#a3a3a3;--line:#2a2a2a;--card:#181818;--note:#2a1814;color-scheme:dark}}
:root[data-theme=dark]{--bg:#111;--fg:#f2f2f2;--muted:#a3a3a3;--line:#2a2a2a;--card:#181818;--note:#2a1814;color-scheme:dark}
*{box-sizing:border-box}
html{scroll-behavior:smooth;scroll-padding-top:16px}
body{margin:0;background:var(--bg);color:var(--fg);font:16px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
.layout{display:grid;grid-template-columns:280px minmax(0,1fr);min-height:100vh}
aside{position:sticky;top:0;height:100vh;overflow:auto;border-right:1px solid var(--line);padding:20px 16px;background:var(--card)}
aside .brand{display:flex;align-items:center;gap:10px;font-weight:600;margin-bottom:12px}
aside .logo{width:28px;height:28px;border-radius:7px;background:var(--brand);color:var(--brand-fg);display:grid;place-items:center;font-weight:700}
aside input{width:100%;padding:8px 10px;border:1px solid var(--line);border-radius:8px;background:var(--bg);color:var(--fg);margin-bottom:12px}
aside h4{margin:16px 0 4px;font-size:12px;text-transform:uppercase;letter-spacing:.06em;color:var(--muted)}
aside ul{list-style:none;margin:0;padding:0}
aside a{display:block;padding:5px 8px;border-radius:6px;color:var(--fg);text-decoration:none;font-size:14px}
aside a:hover,aside a.active{background:var(--line)}
aside a.active{font-weight:600}
main{min-width:0;padding-block:32px 96px;padding-left:max(clamp(16px,4vw,48px),env(safe-area-inset-left,0px));padding-right:max(clamp(16px,4vw,48px),env(safe-area-inset-right,0px));max-width:1180px;width:100%}
.intro{margin-bottom:32px}
.intro h1{font-size:clamp(26px,4vw,36px);margin:0 0 8px}
.intro p{color:var(--muted);max-width:70ch}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px;margin:20px 0}
.cards div{border:1px solid var(--line);border-radius:12px;padding:14px;background:var(--card)}
.cards b{display:block;margin-bottom:4px}
.group-title{font-size:13px;text-transform:uppercase;letter-spacing:.08em;color:var(--brand);margin:56px 0 12px;font-weight:700}
.page{border-top:1px solid var(--line);padding:28px 0}
.page h2{margin:0;font-size:24px}
.page h3{font-size:15px;margin:20px 0 6px}
.meta{display:flex;flex-wrap:wrap;gap:8px;align-items:center;margin:6px 0 0;color:var(--muted)}
code{background:var(--card);border:1px solid var(--line);padding:1px 6px;border-radius:6px;font-size:13px}
.who{font-size:12px;border:1px solid var(--line);padding:1px 8px;border-radius:999px}
.purpose{font-size:17px;max-width:75ch}
.shots{display:flex;flex-wrap:wrap;gap:12px;margin:14px 0}
.shot{display:block;border:1px solid var(--line);border-radius:10px;overflow:hidden;background:var(--card)}
.shot img{display:block;width:100%;height:auto}
.shot.desktop{flex:1 1 560px;max-width:100%}
.shot.phone{flex:0 0 200px}
ul{padding-left:20px}
li{margin:4px 0}
.note{border-left:3px solid var(--brand);background:var(--note);padding:10px 14px;border-radius:0 8px 8px 0;margin-top:16px}
table{border-collapse:collapse;width:100%}
th,td{border:1px solid var(--line);padding:8px 10px;text-align:left;vertical-align:top}
th{background:var(--card)}
dialog{border:0;padding:0;background:transparent;max-width:96vw;max-height:96vh}
dialog::backdrop{background:rgba(0,0,0,.75)}
dialog img{max-width:96vw;max-height:94vh;border-radius:8px;display:block}
.menu-btn{display:none}
@media (max-width:860px){
.layout{grid-template-columns:1fr}
aside{position:fixed;inset:0 20% 0 0;z-index:20;padding-left:max(16px,env(safe-area-inset-left,0px));transform:translateX(-100%);transition:transform .2s;height:100vh}
aside.open{transform:none;box-shadow:0 0 40px rgba(0,0,0,.4)}
.menu-btn{display:block;position:sticky;top:env(safe-area-inset-top,0px);z-index:11;width:100%;text-align:left;padding:12px max(16px,env(safe-area-inset-right,0px)) 12px max(16px,env(safe-area-inset-left,0px));border:0;border-bottom:1px solid var(--line);background:var(--bg);color:var(--fg);font:inherit;font-weight:600}
.shot.phone{flex-basis:160px}
}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}aside{transition:none}}
</style>
</head>
<body>
<button class="menu-btn" type="button" id="menu">Menu du guide</button>
<div class="layout">
<aside id="nav" aria-label="Table des matières">
<div class="brand"><span class="logo">F</span><span>Guide Fratex Agent</span></div>
<input type="search" id="filter" placeholder="Filtrer les pages" aria-label="Filtrer les pages">
__NAV__
</aside>
<main>
<div class="intro">
<h1>Guide de l'application Fratex Agent</h1>
<p>Chaque page de l'application, avec sa capture d'écran, son rôle et ses fonctions en détail. Les captures ont été prises le 22 octobre 2026 sur l'environnement local, avec des données de démonstration. Cliquez sur une image pour l'agrandir.</p>
<div class="cards">
<div><b>Pour le courtier</b>Accueil, Prospects, Fiche, Boîte de réception, Portail, Estimateur.</div>
<div><b>Pour l'équipe Fratex</b>Courtiers, Connexions, Assistant IA, Membres, Support.</div>
<div><b>Pour la direction</b>Portail courtier, Accueil (vue Ventes CRM), Devises, Activité de l'assistant (à venir).</div>
</div>
</div>
__MAIN__
</main>
</div>
<dialog id="lightbox"><img alt=""></dialog>
<script>
const dialog=document.getElementById("lightbox");
document.addEventListener("click",e=>{const a=e.target.closest("[data-lightbox]");if(!a)return;e.preventDefault();dialog.querySelector("img").src=a.href;dialog.querySelector("img").alt=a.querySelector("img").alt;dialog.showModal()});
dialog.addEventListener("click",()=>dialog.close());
const nav=document.getElementById("nav");
document.getElementById("menu").addEventListener("click",()=>nav.classList.toggle("open"));
nav.addEventListener("click",e=>{if(e.target.closest("a"))nav.classList.remove("open")});
const links=[...nav.querySelectorAll("a")];
const byId=new Map(links.map(a=>[a.getAttribute("href").slice(1),a]));
const io=new IntersectionObserver(entries=>{for(const en of entries)if(en.isIntersecting){links.forEach(l=>l.classList.remove("active"));byId.get(en.target.id)?.classList.add("active")}},{rootMargin:"-20% 0px -70% 0px"});
document.querySelectorAll("section.page").forEach(s=>io.observe(s));
document.getElementById("filter").addEventListener("input",e=>{const q=e.target.value.toLowerCase().normalize("NFD").replace(/[\\u0300-\\u036f]/g,"");links.forEach(l=>{const t=l.textContent.toLowerCase().normalize("NFD").replace(/[\\u0300-\\u036f]/g,"");l.parentElement.hidden=q&&!t.includes(q)})});
</script>
</body>
</html>
"""


def main():
    page = TEMPLATE.replace("__NAV__", render_nav()).replace("__MAIN__", render_main())
    OUT.write_text(page, encoding="utf-8")
    missing = []
    for p in PAGES:
        for name in [p["img"], *p.get("mobile", []), *p.get("extra", [])]:
            if not (ROOT / "guide" / "images" / name).exists():
                missing.append(name)
    print(json.dumps({"pages": len(PAGES), "missing": missing}))


main()
