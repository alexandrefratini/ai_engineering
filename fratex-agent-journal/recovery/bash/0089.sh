cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/components/brand-logos/google-calendar.tsx"
s=open(p).read()
s=s.replace('\t\t<path fill="#FBBC04"','\t\t<rect x="5.684" y="5.684" width="12.632" height="12.632" fill="#fff" />\n\t\t<path fill="#FBBC04"',1)
open(p,"w").write(s)
EOF
S=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad; python3 - "$S" <<'EOF'
import re,sys,glob
S=sys.argv[1]
base="/home/user/endsi3g/fratex-agent/packages/ui/src/components/brand-logos/"
html='<html><body style="margin:0;display:flex;gap:24px;padding:24px;background:#fff;font:12px sans-serif">'
for n in ["meta","twilio","gemini","google-calendar","google"]:
    s=open(base+n+".tsx").read()
    svg=re.search(r"<svg.*?</svg>",s,re.S).group(0)
    svg=svg.replace("{...props}","").replace("stopColor","stop-color").replace("gradientUnits","gradientUnits")
    svg=re.sub(r'id=\{gradient\}','id="g"',svg); svg=svg.replace('fill={`url(#${gradient})`}','fill="url(#g)"')
    svg=svg.replace("<svg ",'<svg width="64" height="64" ')
    html+=f'<div style="text-align:center">{svg}<div>{n}</div></div>'
html+='</body></html>'
open(S+"/logos.html","w").write(html)
EOF
cd $S && node -e '
const { chromium } = require("/opt/node-tools/node_modules/playwright");
(async()=>{const b=await chromium.launch({executablePath:"/opt/pw-browsers/chromium"});const p=await b.newPage({viewport:{width:520,height:130}});await p.goto("file://'$S'/logos.html");await p.screenshot({path:"'$S'/logos.png"});await b.close();})()'