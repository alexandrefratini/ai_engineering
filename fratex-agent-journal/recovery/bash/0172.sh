cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/app/components/auth-shell.tsx"
s=open(p).read()
s=s.replace('''						<h1 className="max-w-[14ch] text-5xl/14 font-semibold text-balance">
							Every customer, one place.
						</h1>''','''						<h1 className="max-w-[16ch] text-5xl/14 font-semibold text-balance">
							Chaque prospect rappelé en moins de 2 minutes.
						</h1>''')
open(p,"w").write(s)
p="apps/app/components/app-header.tsx"
s=open(p).read()
print(s.count('<Logo className="size-5" />'))
s=s.replace('<Logo className="size-5" />','<Logo className="size-5 text-primary" />')
open(p,"w").write(s)
EOF
bunx biome check --write apps/app/components/auth-shell.tsx apps/app/components/app-header.tsx apps/app/app/layout.tsx packages/ui/src/components/logo.tsx 2>&1 | tail -1; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -3; echo app $?); grep -rn "lang=\"en\"\|toLocale.*en-US" apps/app/test/*.ts* | head -3