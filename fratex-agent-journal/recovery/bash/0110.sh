S=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad; cat > $S/connections-flow.cjs <<'EOF'
const { chromium } = require("/opt/node-tools/node_modules/playwright");
const [, , cookie, out, suffix = ""] = process.argv;
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const errors = [];
  const c = await b.newContext({ viewport: { width: 1440, height: 1100 }, locale: "fr-CA", permissions: ["clipboard-read", "clipboard-write"] });
  await c.addCookies([{ name: "crm.session_token", value: cookie, domain: "localhost", path: "/" }]);
  const p = await c.newPage();
  p.on("pageerror", (e) => errors.push(e.message.slice(0, 200)));
  p.on("console", (m) => m.type() === "error" && errors.push("console: " + m.text().slice(0, 200)));
  const go = async (path, name) => {
    await p.goto("http://localhost:3000" + path, { waitUntil: "networkidle", timeout: 90000 });
    await p.waitForTimeout(2000);
    if (name) await p.screenshot({ path: `${out}/${name}${suffix}.png` });
  };
  await go("/crm/settings/connections", "p6-connexions");
  await p.getByText("À relier").first().hover().catch(() => {});
  await p.waitForTimeout(600);
  await go("/crm/settings/connections/realtor-calendar", "p6-agenda");
  if (suffix) {
    await p.getByRole("button", { name: "Copier le lien pour le courtier" }).click();
    await p.waitForTimeout(1500);
    const link = await p.evaluate(() => navigator.clipboard.readText());
    const u = new URL(link);
    console.log("lien :", u.origin + u.pathname, "| scope :", u.searchParams.get("scope"), "| redirect :", u.searchParams.get("redirect_uri"));
    await p.screenshot({ path: `${out}/p6-agenda-lien${suffix}.png` });
  }
  await go("/crm/settings/connections/meta-ads", "p6-meta");
  await go("/crm/settings/connections/twilio", "p6-twilio");
  await go("/crm/settings/connections/gemini", "p6-ia");
  await go("/crm/settings/connections?add=1", "p6-ajouter");
  await c.clearCookies();
  for (const s of ["ok", "expired"]) await go(`/agenda-connecte?statut=${s}`, `p6-resultat-${s}`);
  console.log("erreurs:", errors.length ? errors : "aucune");
  await b.close();
})();
EOF
cd $S && node connections-flow.cjs "$(cat cookie.txt)" /home/user/ai_engineering/fratex-agent-journal/screenshots/apres 2>&1 | tail -6