cd /home/user/endsi3g/fratex-agent && sed -n 24,50p apps/app/components/auth-shell.tsx | head -5; python3 - <<'EOF'
p="apps/app/app/layout.tsx"
s=open(p).read()
s=s.replace('''		default: "Comp AI - CRM",
		template: "%s · Comp AI CRM",
	},
	description: "Customer Relationship Management for Comp AI",''','''		default: "Fratex Agent",
		template: "%s · Fratex Agent",
	},
	description:
		"L'assistant IA des courtiers immobiliers : il contacte chaque prospect en moins de 2 minutes, le qualifie et réserve le rendez-vous.",''')
s=s.replace('			lang="en"','			lang="fr-CA"')
open(p,"w").write(s)
p="apps/app/components/auth-shell.tsx"
s=open(p).read()
s=s.replace('''					<Link href="/" aria-label="Homepage" className="flex">''','''					<Link href="/" aria-label="Accueil Fratex" className="flex">''')
s=s.replace('''						<p className="font-mono text-xs/4 text-muted-foreground uppercase">
							CRM
						</p>''','''						<p className="font-mono text-xs/4 text-muted-foreground uppercase">
							Fratex Agent
						</p>''')
s=s.replace('''					Made with love by{" "}
					<a
						href="https://trycomp.ai"
						target="_blank"
						rel="noreferrer"
						className="underline underline-offset-4 hover:text-foreground"
					>
						Comp AI
					</a>''','''					Fratex · Québec''')
open(p,"w").write(s)
EOF
sed -n 20,40p apps/app/components/auth-shell.tsx