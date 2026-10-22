S=/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad; cat > $S/realtors-flow.cjs <<'EOF'
const { chromium } = require("/opt/node-tools/node_modules/playwright");
const [, , cookie, out] = process.argv;
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const errors = [];
  for (const [w, h, tag] of [[1440, 900, ""], [390, 844, "-mobile"]]) {
    const c = await b.newContext({ viewport: { width: w, height: h }, locale: "fr-CA" });
    await c.addCookies([{ name: "crm.session_token", value: cookie, domain: "localhost", path: "/" }]);
    const p = await c.newPage();
    p.on("pageerror", (e) => errors.push(e.message.slice(0, 200)));
    p.on("console", (m) => m.type() === "error" && errors.push("console: " + m.text().slice(0, 200)));
    await p.goto("http://localhost:3000/crm/real-estate/realtors", { waitUntil: "networkidle", timeout: 90000 });
    await p.waitForTimeout(2000);
    await p.screenshot({ path: `${out}/p5-courtiers${tag}.png`, fullPage: true });
    await p.goto("http://localhost:3000/onboarding/realtor", { waitUntil: "networkidle", timeout: 90000 });
    await p.waitForTimeout(2000);
    await p.screenshot({ path: `${out}/p5-onboarding${tag}.png`, fullPage: true });
    if (!tag) {
      await p.goto("http://localhost:3000/crm/real-estate/realtors", { waitUntil: "networkidle" });
      await p.waitForTimeout(1500);
      await p.getByRole("link", { name: "Ajouter un courtier" }).click();
      await p.waitForURL(/realtors\/new/);
      await p.waitForTimeout(2000);
      await p.screenshot({ path: `${out}/p5-nouveau.png`, fullPage: true });
      await p.getByLabel("Nom complet").fill("Sophie Gagnon");
      await p.getByLabel("Courriel").fill(`sophie.${Date.now()}@courtage.ca`);
      await p.getByLabel("Téléphone").fill("5145550199");
      await p.getByLabel("Numéro de permis OACIQ").fill("J4821");
      await p.getByLabel("Secteurs desservis").fill("Rosemont, Villeray");
      await p.getByRole("button", { name: "Ajouter le courtier" }).click();
      await p.waitForTimeout(800);
      console.log("sans type :", await p.getByText("Choisissez au moins un type").count());
      await p.getByText("Condo", { exact: true }).click();
      await p.getByText("Plex", { exact: true }).click();
      await p.getByRole("button", { name: "Ajouter le courtier" }).click();
      await p.getByText(/est ajouté/).waitFor({ timeout: 15000 });
      await p.waitForTimeout(800);
      await p.screenshot({ path: `${out}/p5-succes.png`, fullPage: true });
      const links = await p.locator("ol a").evaluateAll((a) => a.map((x) => x.getAttribute("href")));
      console.log("étapes :", links);
      await p.goto("http://localhost:3000/crm/real-estate/realtors", { waitUntil: "networkidle" });
      await p.waitForTimeout(1500);
      console.log("Sophie dans la liste :", await p.getByText("Sophie Gagnon").count());
      const meta = p.getByText("Meta", { exact: true }).first();
      await meta.hover();
      await p.waitForTimeout(700);
      await p.screenshot({ path: `${out}/p5-courtiers-infobulle.png` });
    }
    await c.close();
  }
  console.log("erreurs:", errors.length ? errors : "aucune");
  await b.close();
})();
EOF
cd $S && node realtors-flow.cjs "$(cat cookie.txt)" /home/user/ai_engineering/fratex-agent-journal/screenshots/apres 2>&1 | tail -20