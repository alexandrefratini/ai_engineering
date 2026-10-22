cd /home/user/endsi3g/fratex-agent && sed -i 's/"Réglages généraux",/"Paramètres généraux",/' apps/app/test/navigation.spec.ts && python3 - <<'EOF'
p="packages/ui/src/lib/real-estate.ts"
s=open(p).read()
s=s.replace('''export const INTENT_LABELS: Record<string, string> = {''','''export const TIMEZONE_OPTIONS = [
	{ id: "America/Toronto", name: "Québec et Ontario (heure de l'Est)" },
	{ id: "America/Halifax", name: "Maritimes (heure de l'Atlantique)" },
	{ id: "America/Winnipeg", name: "Manitoba (heure du Centre)" },
	{ id: "America/Edmonton", name: "Alberta (heure des Rocheuses)" },
	{ id: "America/Vancouver", name: "Colombie-Britannique (heure du Pacifique)" },
];

export const INTENT_LABELS: Record<string, string> = {''',1)
open(p,"w").write(s)
p="packages/ui/src/components/realtor-onboarding-form.tsx"
s=open(p).read()
a=s.index("const TIMEZONES = [")
b=s.index("];",a)+3
s=s[:a]+s[b:]
s=s.replace("options={TIMEZONES}","options={TIMEZONE_OPTIONS}")
s=s.replace('import { REVEAL, staggerStyle } from "../lib/motion";','import { REVEAL, staggerStyle } from "../lib/motion";\nimport { TIMEZONE_OPTIONS } from "../lib/real-estate";')
open(p,"w").write(s)
p="packages/ui/src/components/calendar-connect-panel.tsx"
s=open(p).read()
s=s.replace('import { formatDateTime } from "../lib/real-estate";','import { formatDateTime, TIMEZONE_OPTIONS } from "../lib/real-estate";')
s=s.replace("Agenda. Fuseau : {selected.timezone}.","Agenda. Fuseau : {TIMEZONE_OPTIONS.find((zone) => zone.id === selected.timezone)?.name ?? selected.timezone}.")
open(p,"w").write(s)
EOF
grep -n "TIMEZONE_OPTIONS" packages/ui/src/components/*.tsx; bunx biome check --write packages/ui/src apps/app/lib/navigation.ts apps/app/test/navigation.spec.ts 2>&1 | tail -1; (cd packages/ui && bunx tsc --noEmit; echo ui $?); (cd apps/app && bunx tsc --noEmit; echo app $?; bun test test/navigation.spec.ts 2>&1 | tail -3)