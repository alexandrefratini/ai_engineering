cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/settings/connections" && python3 - <<'EOF'
pages={
 "meta-ads/page.tsx":("Meta Lead Ads & CAPI","Meta Lead Ads","Reliez le formulaire de publicité d'un courtier. Chaque prospect qui le remplit arrive dans Fratex et reçoit un SMS en moins de 2 minutes."),
 "twilio/page.tsx":("Twilio SMS & Téléphonie","SMS Twilio","Le numéro de l'agence qui envoie le premier SMS et reçoit les réponses des prospects."),
 "gemini/page.tsx":("Google Gemini AI","Assistant IA","Le modèle qui qualifie les prospects par SMS et propose les rendez-vous."),
}
for p,(old,title,desc) in pages.items():
    s=open(p).read()
    s=s.replace(f'export const metadata: Metadata = {{ title: "{old}" }};',f'export const metadata: Metadata = {{ title: "{title}" }};')
    assert "<ConnectionPage>" in s, p
    comp=s[s.index("<ConnectionPage>")+len("<ConnectionPage>"):s.index("</ConnectionPage>")]
    s=s.replace("<ConnectionPage>"+comp+"</ConnectionPage>",f'''<ConnectionPage className="gap-4">
			<ConnectionHeader
				slug={{slug}}
				title="{title}"
				description="{desc}"
			/>{comp.rstrip()}
		</ConnectionPage>''')
    s=s.replace('import { ConnectionPage, ConnectionPageLoading } from "../connection-page";','import { ConnectionHeader } from "../connection-header";\nimport { ConnectionPage, ConnectionPageLoading } from "../connection-page";')
    open(p,"w").write(s)
EOF
grep -n "description" ../../../../../../../packages/ui/src/components/connection-setup.tsx | head -3; sed -n 18,40p meta-ads/page.tsx