cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
import re
p="apps/app/lib/agent-transcript.ts"
s=open(p).read()
T={
"Read our emails and meetings with them":"A lu nos courriels et rencontres avec cette personne",
"Read everything we have on the company":"A lu tout ce que nous avons sur l'entreprise",
"Read the deal and where it has been":"A lu l'affaire et son historique",
"Looked the record up in the CRM":"A cherché la fiche dans Fratex",
"Searched for their LinkedIn profile":"A cherché son profil LinkedIn",
"Read a LinkedIn profile":"A lu un profil LinkedIn",
"Read their work history":"A lu son parcours professionnel",
"Fetched their profile picture":"A récupéré sa photo de profil",
"Searched for their other profiles":"A cherché ses autres profils",
"Checked a profile against the account itself":"A vérifié un profil auprès du compte lui-même",
"Put a name to the address":"A associé un nom à l'adresse",
"Recorded what it found":"A enregistré ce qu'il a trouvé",
"Wrote the background":"A rédigé le contexte",
"Wrote up who we are":"A décrit qui nous sommes",
"Researched them on the web":"A fait des recherches sur le Web",
"Read the company's site":"A lu le site de l'entreprise",
"Looked up the company":"A cherché l'entreprise",
"Decided when to look again":"A choisi quand vérifier de nouveau",
"Raised a job change":"A signalé un changement d'emploi",
"Reviewed the deal pipeline":"A passé en revue le pipeline des affaires",
"Looked for outstanding work":"A cherché les tâches en attente",
"Named this chat":"A nommé cette conversation",
"Read what this workspace tracks":"A lu les champs suivis par cet espace",
"Filled in a custom field":"A rempli un champ personnalisé",
"Changed what the CRM tracks":"A modifié les champs suivis",
"Asked to retire a field":"A demandé de retirer un champ",
"Read the authorized lead":"A lu le prospect autorisé",
"Applied the agency tool policy":"A appliqué les règles de l'agence",
"Extracted and recorded lead criteria":"A extrait et enregistré les critères du prospect",
"Drafted and queued an SMS response":"A rédigé et mis en file une réponse SMS",
"Scheduled a follow-up check for this lead":"A planifié une relance pour ce prospect",
"Checked open calendar slots for the realtor":"A vérifié les créneaux libres du courtier",
"Booked a consultation with the realtor":"A réservé un rendez-vous avec le courtier",
"Escalated this lead to the human realtor":"A transféré ce prospect au courtier",
"Saved an unconfirmed listing suggestion":"A enregistré une suggestion de propriété non confirmée",
"Read its instructions for this":"A lu ses instructions pour cette tâche",
"Searched the web":"A cherché sur le Web",
"Read a web page":"A lu une page Web",
"Updated its plan":"A mis à jour son plan",
"Asked a question":"A posé une question",
"Handed part of the job to a helper":"A confié une partie du travail à un assistant",
"Looked for a tool it could use":"A cherché un outil utilisable",
"Ran a command":"A exécuté une commande",
"Read a file":"A lu un fichier",
"Wrote a file":"A écrit un fichier",
"Looked for files":"A cherché des fichiers",
"Searched inside the files":"A cherché dans les fichiers",
}
for a,b in T.items():
    assert f'"{a}"' in s, a
    s=s.replace(f'"{a}"', '"'+b.replace('"','\\"')+'"')
open(p,"w").write(s)
import json
json.dump(T, open("/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad/verbs.json","w"), ensure_ascii=False)
EOF
sed -n 55,66p apps/app/lib/agent-transcript.ts; sed -n 255,262p apps/app/lib/agent-transcript.ts; grep -n "\"[A-Z][a-z][^\"]*\"" apps/app/test/agent-transcript.spec.ts apps/app/test/agent-results.spec.ts | head -30