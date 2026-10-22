S=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad/brand; P=/home/user/endsi3g/fratex-agent/apps/app/public; cp $S/icon.svg $P/favicon.svg && cp $S/favicon.ico $S/favicon-96x96.png $S/apple-touch-icon.png $S/web-app-manifest-192x192.png $S/web-app-manifest-512x512.png $P/ && python3 - <<'EOF'
import json
p="/home/user/endsi3g/fratex-agent/apps/app/public/site.webmanifest"
m=json.load(open(p))
m["name"]="Fratex Agent"; m["short_name"]="Fratex"; m["theme_color"]="#006B4F"
open(p,"w").write(json.dumps(m,indent="\t",ensure_ascii=False)+"\n")
EOF
cd /home/user/endsi3g/fratex-agent && sed -n 25,45p apps/app/components/auth-shell.tsx; grep -n "<Logo" apps/app/components/app-header.tsx; grep -rn "Comp AI\|title:.*CRM\|applicationName" apps/app/app/layout.tsx | head