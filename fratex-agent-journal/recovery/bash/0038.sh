cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/components/realtor-roster.tsx"
s=open(p).read()
s=s.replace('''				<SegmentMeter value={ready} total={Math.max(realtors.length, 1)} label="Courtiers entièrement configurés" />''','''				{realtors.length <= 24 && (
					<SegmentMeter filled={ready} total={realtors.length} label="Courtiers entièrement configurés" />
				)}''')
open(p,"w").write(s)
EOF
bunx biome check --write packages/ui/src/components/realtor-roster.tsx packages/ui/src/components/realtor-onboarding-form.tsx "apps/app/app/(app)/[slug]/real-estate/realtors" packages/validation apps/api/src/real-estate/real-estate.contracts.ts 2>&1 | tail -3; (cd packages/ui && bunx tsc --noEmit; echo ui $?); (cd apps/app && bunx tsc --noEmit; echo app $?); (cd apps/api && bunx tsc --noEmit -p tsconfig.json 2>&1 | tail -3; echo api $?)