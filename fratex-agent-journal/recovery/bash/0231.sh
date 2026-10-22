cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/auth/test/slack-connect.integration.spec.ts"
s=open(p).read()
s=s.replace('toContain("Sign in to the CRM")','toContain("Connectez-vous à Fratex")').replace('toContain("Only an owner or an admin")','toContain("Seul un propriétaire ou un administrateur")').replace('toContain("member of this workspace")','toContain("membre de cet espace de travail")')
open(p,"w").write(s)
p="packages/db/src/tracking.ts"
s=open(p).read()
s=s.replace('{ days: 395, label: "13 months" }','{ days: 395, label: "13 mois" }').replace('{ days: 180, label: "6 months" }','{ days: 180, label: "6 mois" }').replace('{ days: 0, label: "Session only" }','{ days: 0, label: "Session seulement" }')
open(p,"w").write(s)
p="apps/app/components/slack/channel-picker.tsx"
s=open(p).read()
for a,b in [('{channel.inviteRequestedAt ? "Ask again" : "Request"}','{channel.inviteRequestedAt ? "Redemander" : "Demander"}'),
('''									Add
								</Button>''','''									Ajouter
								</Button>'''),
('` · ${channel.memberCount} people`','` · ${channel.memberCount} personne${channel.memberCount > 1 ? "s" : ""}`'),
('return `Comp AI is in${people}`;','return `Fratex y est déjà${people}`;'),
('return `Not read from Slack yet${people}`;','return `Pas encore lu depuis Slack${people}`;'),
('return `Comp AI can join this one${people}`;','return `Fratex peut le rejoindre${people}`;'),
('return `Private. Comp AI joins as you${people}`;','return `Privé. Fratex le rejoint en votre nom${people}`;'),
('return `Private. Waiting on an invite${people}`;','return `Privé. En attente d\'une invitation${people}`;'),
('return `Private. Someone inside has to invite Comp AI${people}`;','return `Privé. Un membre du canal doit inviter Fratex${people}`;')]:
    assert a in s, a
    s=s.replace(a,b)
open(p,"w").write(s)
p="apps/app/app/(landing)/onboarding/page.tsx"
s=open(p).read()
s=s.replace('<OnboardingForm placeholder={DEFAULT_WORKSPACE_NAME} />','<OnboardingForm placeholder="Ex. : Équipe Tremblay immobilier" />')
s=s.replace('import { DEFAULT_WORKSPACE_NAME } from "@crm/auth";\n','')
open(p,"w").write(s)
EOF
grep -n "months\|Session only\|13 mois" -r apps/app/test packages/db/test apps/api/test 2>/dev/null | head -5; grep -n "\"[A-Z][a-z]" apps/app/components/slack/channel-picker.tsx | head; grep -rn "label=\|aria-label\|placeholder" apps/app/components/slack/*.tsx | grep -v "channel-picker" | head