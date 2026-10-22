cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="apps/api/src/real-estate/real-estate.contracts.ts"
s=open(p).read()
s=s.replace('''import {
	listingSuggestions,
	storedQualificationEvidence,
} from "@crm/validation/real-estate";''','''import {
	listingSuggestions,
	northAmericanPhone,
	storedQualificationEvidence,
} from "@crm/validation/real-estate";''',1)
open(p,"w").write(s)
EOF
grep -n "createClient" apps/api/src/generated/server.ts | head -3; grep -n "createClient" apps/api/test/*.ts | head -5