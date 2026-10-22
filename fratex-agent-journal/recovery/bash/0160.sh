cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/app/app/(app)/[slug]/overview-scope.tsx"
s=open(p).read()
s=s.replace('''export function OverviewViewToggle() {
	const [view, setView] = useQueryState(
		SEARCH_PARAM.overview.view,
		overviewParsers[SEARCH_PARAM.overview.view],
	);
''','''export function OverviewViewToggle() {
	const audience = useAudience();
	const [view, setView] = useQueryState(
		SEARCH_PARAM.overview.view,
		overviewParsers[SEARCH_PARAM.overview.view],
	);
	if (audience === "realtor") return null;
''')
lines=s.split("\n")
idx=max(i for i,l in enumerate(lines) if l.startswith("import "))
# find end of last import statement
j=idx
while not lines[j].rstrip().endswith(";"): j+=1
lines.insert(j+1,'import { useAudience } from "@/lib/use-audience";')
s="\n".join(lines)
open(p,"w").write(s)
p="packages/ui/src/components/realtor-portal-dashboard.tsx"
s=open(p).read()
s=s.replace("<AvatarFallback>{initialsFromName(stats.client.name)}</AvatarFallback>",'<AvatarFallback>{initialsFromName(stats.client.name.split(",")[0] ?? stats.client.name)}</AvatarFallback>')
open(p,"w").write(s)
EOF
bunx biome check --write "apps/app/app/(app)/[slug]/overview-scope.tsx" packages/ui/src/components/realtor-portal-dashboard.tsx 2>&1 | tail -1; (cd apps/app && bunx tsc --noEmit 2>&1 | tail -3; echo app $?)