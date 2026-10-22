cd "/home/user/endsi3g/fratex-agent/apps/app/app/(app)/[slug]/settings/connections" && python3 - <<'EOF'
p="add-connection-dialog.tsx"
s=open(p).read()
def rep(a,b):
    global s
    assert a in s, a[:60]
    s=s.replace(a,b)
rep('''					{!connected.includes("Google Workspace & Agenda") ? (
						<CatalogRow
							logo={GoogleLogo}
							name="Google Workspace & Agenda"
							description="Synchronisez vos disponibilités et rendez-vous"''','''					{!connected.includes("google") ? (
						<CatalogRow
							logo={GoogleLogo}
							name="Google Workspace"
							description="Classez les courriels Gmail sur la fiche du prospect"''')
rep('''					<CatalogRow
						logo={MicrosoftLogo}
						name="Microsoft 365"
						description="Synchronisez Outlook"
						href={`/${slug}/settings/connections/microsoft`}
					/>''','''					{!connected.includes("microsoft") ? (
						<CatalogRow
							logo={MicrosoftLogo}
							name="Microsoft 365"
							description="Classez les courriels Outlook sur la fiche du prospect"
							href={`/${slug}/settings/connections/microsoft`}
						/>
					) : null}''')
rep('''					<CatalogRow
						logo={GoogleLogo}
						name="Agenda immobilier"
						description="Configurez l’agenda du courtier"''','''					<CatalogRow
						logo={GoogleCalendarLogo}
						name="Google Agenda des courtiers"
						description="Disponibilités réelles et réservation des visites"''')
rep('''{!connected.includes("Slack") ? (''','''{!connected.includes("slack") ? (''')
rep('''						? `${connected.length} outil(s) actuellement configuré(s).`
						: "Aucun outil connecté pour l'instant."}''','''						? `${connected.length} outil${connected.length > 1 ? "s" : ""} de l'équipe déjà connecté${connected.length > 1 ? "s" : ""}.`
						: "Aucun outil de l'équipe connecté pour l'instant."}''')
rep('''import GoogleLogo from "@crm/ui/components/brand-logos/google";''','''import GoogleLogo from "@crm/ui/components/brand-logos/google";
import GoogleCalendarLogo from "@crm/ui/components/brand-logos/google-calendar";''')
open(p,"w").write(s)
EOF
cd /home/user/endsi3g/fratex-agent && bunx biome check --write "apps/app/app/(app)/[slug]/settings/connections" packages/ui/src/components/connection-list.tsx 2>&1 | tail -2; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -5; echo app $?); (cd packages/ui && bunx tsc --noEmit 2>&1 | tail -5; echo ui $?)