cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/auth/src/slack-scopes.ts"
s=open(p).read()
pairs=[
("See the people in your workspace","Voir les personnes de votre espace Slack"),
("See their email addresses, so it can match them to CRM records","Voir leurs adresses courriel, pour les relier aux fiches de Fratex"),
("See the name and topic of every public channel","Voir le nom et le sujet de chaque canal public"),
("See private channels it has been added to","Voir les canaux privés où l'application a été ajoutée"),
("Read messages in public channels it has been added to","Lire les messages des canaux publics où l'application a été ajoutée"),
("Read messages in private channels it has been added to","Lire les messages des canaux privés où l'application a été ajoutée"),
("Post messages as the app","Publier des messages au nom de l'application"),
("Post to any public channel, including ones it has not joined","Publier dans tout canal public, même ceux qu'elle n'a pas rejoints"),
("Open a direct message with a person","Ouvrir un message direct avec une personne"),
("Join a public channel by itself","Rejoindre seule un canal public"),
("Create public channels, and rename or archive ones it is in","Créer des canaux publics, renommer ou archiver ceux où elle se trouve"),
("Create private channels, and rename or archive ones it is in","Créer des canaux privés, renommer ou archiver ceux où elle se trouve"),
("Invite people to a public channel","Inviter des personnes dans un canal public"),
("Invite people to a private channel","Inviter des personnes dans un canal privé"),
("Send and accept Slack Connect invitations","Envoyer et accepter des invitations Slack Connect"),
("Show a preview under a link it posts","Afficher un aperçu sous les liens qu'elle publie"),
("Add itself to a private channel on your behalf","S'ajouter à un canal privé en votre nom"),
('label: "People",','label: "Personnes",'),
("Names and email addresses, so it can match a Slack account to a CRM record.","Noms et adresses courriel, pour relier un compte Slack à une fiche de Fratex."),
('label: "Channels it can read",','label: "Canaux qu\'elle peut lire",'),
("Names and topics of public channels, and the messages in any channel it has been added to.","Noms et sujets des canaux publics, et messages des canaux où elle a été ajoutée."),
('label: "Messages it can send",','label: "Messages qu\'elle peut envoyer",'),
("Post as the app, open a direct message, and preview a link it posts.","Publier au nom de l'application, ouvrir un message direct et afficher l'aperçu d'un lien."),
('label: "Channels it can change",','label: "Canaux qu\'elle peut modifier",'),
("Join, create, rename, archive, and invite people to channels.","Rejoindre, créer, renommer et archiver des canaux, et y inviter des personnes."),
("An undocumented permission named ${scope}","Une autorisation non documentée nommée ${scope}"),
]
for a,b in pairs:
    assert a in s, a
    s=s.replace(a,b)
open(p,"w").write(s)
p="packages/auth/src/slack-connect.ts"
s=open(p).read()
for a,b in [("Sign in to the CRM before you connect Slack.","Connectez-vous à Fratex avant de relier Slack."),("Only a member of this workspace can connect Slack.","Seul un membre de cet espace de travail peut relier Slack."),("Only an owner or an admin can connect Slack. One Slack workspace is shared by everyone here, so ask one of them to connect or reconnect it.","Seul un propriétaire ou un administrateur peut relier Slack. Un seul espace Slack est partagé par toute l'équipe : demandez-leur de le relier ou de le reconnecter.")]:
    assert a in s, a
    s=s.replace(a,b)
open(p,"w").write(s)
EOF
sed -n 150,200p packages/auth/src/slack-scopes.ts | grep -n "\`\|\"" | head; grep -rn "See the people\|People\b\|Channels it can" packages/auth/test apps/app/test apps/api/test 2>/dev/null | head