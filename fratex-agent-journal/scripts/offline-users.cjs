const { chromium } = require("/opt/node-tools/node_modules/playwright");
const [, , cookieA, cookieB, out] = process.argv;
const BASE = "http://localhost:3000";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const results = [];
const check = (name, ok, detail = "") => { results.push(ok); console.log(`${ok ? "OK " : "KO "} ${name}${detail ? " — " + detail : ""}`); };
const state = (p) => p.evaluate(async () => {
  const o = {};
  for (const n of await caches.keys()) o[n] = (await (await caches.open(n)).keys()).length;
  return o;
});
const dataNames = (s) => Object.keys(s).filter((n) => n.startsWith("fratex-data-"));
const cookies = (v) => [
  { name: "__Secure-crm.session_token", value: v, domain: "localhost", path: "/", secure: true },
  { name: "crm.session_token", value: v, domain: "localhost", path: "/" },
];
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const c = await b.newContext({ viewport: { width: 1280, height: 900 }, locale: "fr-CA", timezoneId: "America/Toronto" });
  await c.addCookies(cookies(cookieA));
  const p = await c.newPage();
  await p.goto(BASE + "/crm/real-estate/leads", { waitUntil: "networkidle" });
  await p.evaluate(() => navigator.serviceWorker.ready);
  for (const path of ["/crm/real-estate/leads", "/crm/real-estate/inbox", "/crm/account"]) { await p.goto(BASE + path, { waitUntil: "networkidle" }); await sleep(1200); }
  const a = await state(p);
  check("la personne A a sa copie", dataNames(a).length === 1, JSON.stringify(a));

  // Une autre personne ouvre une session sur le même appareil (sans se déconnecter proprement)
  await c.clearCookies();
  await c.addCookies(cookies(cookieB));
  await p.goto(BASE + "/crm/real-estate/leads", { waitUntil: "networkidle" });
  await sleep(2000);
  const b2 = await state(p);
  check("la copie de A est effacée et celle de B est séparée", dataNames(b2).length === 1 && dataNames(b2)[0] !== dataNames(a)[0], JSON.stringify(b2));

  // Déconnexion
  await p.goto(BASE + "/crm/account", { waitUntil: "networkidle" });
  await sleep(1200);
  await p.getByRole("button", { name: "Se déconnecter" }).click();
  await p.waitForURL(/sign-in/, { timeout: 15000 });
  await sleep(2500);
  const c2 = await state(p);
  check("à la déconnexion, plus aucune donnée ni identifiant de personne", dataNames(c2).length === 0 && !("fratex-meta" in c2), JSON.stringify(c2));
  await p.screenshot({ path: `${out}/offline-signout.png` });

  // Retour sur la page de connexion sans session : on purge aussi
  await c.addCookies(cookies(cookieA));
  await p.goto(BASE + "/crm/real-estate/leads", { waitUntil: "networkidle" });
  await sleep(1500);
  const filled = dataNames(await state(p)).length === 1;
  await c.clearCookies();
  await p.goto(BASE + "/sign-in", { waitUntil: "networkidle" });
  await sleep(2000);
  const after = await state(p);
  check("session expirée : la page de connexion efface la copie", filled && dataNames(after).length === 0 && !("fratex-meta" in after), JSON.stringify(after));

  console.log(results.every(Boolean) ? "TOUT OK" : "ÉCHECS");
  await b.close();
})();
