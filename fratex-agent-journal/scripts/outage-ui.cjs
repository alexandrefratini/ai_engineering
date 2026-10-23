const { chromium } = require("/opt/node-tools/node_modules/playwright");
const [, , cookie, out, label] = process.argv;
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const c = await b.newContext({ viewport: { width: 1280, height: 800 }, locale: "fr-CA", serviceWorkers: "block" });
  await c.addCookies([
    { name: "__Secure-crm.session_token", value: cookie, domain: "localhost", path: "/", secure: true },
    { name: "crm.session_token", value: cookie, domain: "localhost", path: "/" },
  ]);
  const p = await c.newPage();
  const errors = [];
  p.on("pageerror", (e) => errors.push(e.message.slice(0, 120)));
  for (const [name, path] of [["leads", "/crm/real-estate/leads"], ["account", "/crm/account"], ["signin", "/sign-in"]]) {
    const t0 = Date.now();
    const r = await p.goto("http://localhost:3000" + path, { waitUntil: "networkidle", timeout: 60000 }).catch((e) => ({ status: () => "ERR " + e.message.slice(0, 60) }));
    await p.waitForTimeout(2500);
    const body = (await p.locator("body").innerText().catch(() => "")).replace(/\s+/g, " ").slice(0, 260);
    console.log(`[${label}] ${name} → ${r.status()} en ${Date.now() - t0} ms, url ${p.url().replace("http://localhost:3000", "")}\n   texte: ${body}`);
    await p.screenshot({ path: `${out}/outage-${label}-${name}.png` });
  }
  console.log("erreurs de page:", errors.length ? errors : "aucune");
  await b.close();
})();
