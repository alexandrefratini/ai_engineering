for i in $(seq 1 50); do a=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/health); b=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/agenda-connecte); [ "$a" = 200 ] && [ "$b" = 200 ] && break; sleep 3; done; echo "api $a app $b"; S=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad; cat > $S/presence-flow.cjs <<'EOF'
const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs = require("fs");
const [, , dir, out] = process.argv;
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const errors = [];
  const ctx = async (file) => {
    const c = await b.newContext({ viewport: { width: 1440, height: 700 }, locale: "fr-CA" });
    await c.addCookies([{ name: "crm.session_token", value: fs.readFileSync(`${dir}/${file}`, "utf8").trim(), domain: "localhost", path: "/" }]);
    const p = await c.newPage();
    p.on("pageerror", (e) => errors.push(e.message.slice(0, 200)));
    return p;
  };
  const marie = await ctx("cookie-marie.txt");
  await marie.goto("http://localhost:3000/crm/real-estate/portal", { waitUntil: "networkidle", timeout: 90000 });
  await marie.waitForTimeout(3000);
  const alex = await ctx("cookie.txt");
  await alex.goto("http://localhost:3000/crm/real-estate/inbox", { waitUntil: "networkidle", timeout: 90000 });
  await alex.waitForTimeout(3000);
  await alex.reload({ waitUntil: "networkidle" });
  await alex.waitForTimeout(2500);
  await alex.screenshot({ path: `${out}/p15-presence-pile.png`, clip: { x: 1100, y: 0, width: 340, height: 48 } });
  await alex.getByRole("button", { name: /^Équipe/ }).click();
  await alex.waitForTimeout(800);
  await alex.screenshot({ path: `${out}/p15-presence-liste.png`, clip: { x: 1040, y: 0, width: 400, height: 420 } });
  const link = alex.getByRole("link", { name: "Portail courtier" });
  console.log("lien vers la page de Marie :", await link.count());
  if (await link.count()) { await link.first().click(); await alex.waitForURL(/portal/); console.log("clic →", alex.url().replace(/\?.*/, "")); }
  console.log("erreurs:", errors.length ? errors : "aucune");
  await b.close();
})();
EOF
cd $S && node presence-flow.cjs $S /home/user/ai_engineering/fratex-agent-journal/screenshots/apres 2>&1 | tail -5