cd /home/user/endsi3g/fratex-agent && python3 - <<'EOF'
p="packages/ui/src/components/team-presence.tsx"
s=open(p).read()
s=s.replace('''								member={member}
								size="sm"
								className={cn("bg-background ring-2 ring-background"''','''								member={member}
								size="default"
								className={cn("size-7 bg-background ring-2 ring-background"''')
s=s.replace('''<span className="relative flex size-6 items-center justify-center rounded-full bg-muted text-[10px] font-medium text-muted-foreground ring-2 ring-background">''','''<span className="relative flex size-7 items-center justify-center rounded-full bg-background text-[11px] font-medium text-muted-foreground ring-2 ring-background after:absolute after:inset-0 after:rounded-full after:border after:border-border">''')
open(p,"w").write(s)
EOF
grep -n 'size="default"' packages/ui/src/components/team-presence.tsx | head -3; sleep 5; S=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad; cd $S && node -e '
const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs=require("fs");
(async()=>{const b=await chromium.launch({executablePath:"/opt/pw-browsers/chromium"});const c=await b.newContext({viewport:{width:1440,height:300},deviceScaleFactor:3});await c.addCookies([{name:"crm.session_token",value:fs.readFileSync("cookie.txt","utf8").trim(),domain:"localhost",path:"/"}]);const p=await c.newPage();await p.goto("http://localhost:3000/crm/real-estate/inbox",{waitUntil:"networkidle"});await p.waitForTimeout(2500);
const btn=p.getByRole("button",{name:/^Équipe/});const box=await btn.boundingBox();await p.screenshot({path:"zoom.png",clip:{x:box.x-4,y:box.y-4,width:box.width+8,height:box.height+8}});await b.close();})()'