cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/app/app/(app)/[slug]/settings/connections/add-connection-dialog.tsx"
s=open(p).read()
s=s.replace('description="Envoyez des alertes à votre équipe à chaque nouveau rendez-vous"','description="Prévenez l\'équipe quand un prospect demande un humain"')
open(p,"w").write(s)
p="packages/ui/src/components/connection-setup.tsx"
s=open(p).read()
old=s[s.index("	return (\n		<Field>\n			<FieldLabel>{label}</FieldLabel>"):s.index("	);\n}",s.index("export function WebhookAddress"))]
new='''	return (
		<Field>
			<FieldLabel>{label}</FieldLabel>
			<div className="flex gap-2">
				<Input readOnly value={url} aria-label={label} className="font-mono text-xs" />
				<Button
					type="button"
					variant="outline"
					onClick={() => {
						void copy();
					}}
				>
					{copied ? "Copié" : "Copier"}
				</Button>
			</div>
			{failed && (
				<WorkspaceNotice title="Copie impossible. Sélectionnez l’adresse." />
			)}
		</Field>
'''
s=s.replace(old,new)
open(p,"w").write(s)
EOF
bunx biome check --write packages/ui/src/components/connection-setup.tsx "apps/app/app/(app)/[slug]/settings/connections/add-connection-dialog.tsx" 2>&1 | tail -1; (cd packages/ui && bunx tsc --noEmit; echo ui $?)