const { chromium } = require("/opt/node-tools/node_modules/playwright");
const [, , cookie, out] = process.argv;
const BASE = "http://localhost:3000";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const cookies = [
  { name: "__Secure-crm.session_token", value: cookie, domain: "localhost", path: "/", secure: true },
  { name: "crm.session_token", value: cookie, domain: "localhost", path: "/" },
];
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  // Bureau : visite de quelques pages pour remplir la copie hors ligne, puis Mon compte
  const c = await b.newContext({ viewport: { width: 1280, height: 900 }, locale: "fr-CA", timezoneId: "America/Toronto" });
  await c.addCookies(cookies);
  const p = await c.newPage();
  await p.goto(BASE + "/crm/real-estate/leads", { waitUntil: "networkidle" });
  await p.evaluate(() => navigator.serviceWorker.ready);
  for (const path of ["/crm/real-estate/leads", "/crm/real-estate/inbox", "/crm/real-estate/pipeline", "/crm/contacts"]) { await p.goto(BASE + path, { waitUntil: "networkidle" }); await sleep(1200); }
  await p.goto(BASE + "/crm/account", { waitUntil: "networkidle" });
  await sleep(2000);
  await p.addStyleTag({ content: "nextjs-portal{display:none!important}" });
  const notif = p.getByRole("switch", { name: "Nouveau prospect" });
  await notif.scrollIntoViewIfNeeded();
  await p.evaluate(() => window.scrollBy(0, -140));
  await sleep(600);
  await p.screenshot({ path: `${out}/notifications.png` });
  await p.getByRole("button", { name: "Effacer les données hors ligne" }).scrollIntoViewIfNeeded();
  await p.evaluate(() => window.scrollBy(0, 120));
  await sleep(600);
  await p.screenshot({ path: `${out}/hors-ligne-reglage.png` });
  // Mobile
  const m = await b.newContext({ viewport: { width: 390, height: 844 }, locale: "fr-CA", timezoneId: "America/Toronto", isMobile: true, hasTouch: true });
  await m.addCookies(cookies);
  const mp = await m.newPage();
  await mp.goto(BASE + "/crm/account", { waitUntil: "networkidle" });
  await sleep(2000);
  await mp.getByRole("switch", { name: "Nouveau prospect" }).scrollIntoViewIfNeeded();
  await mp.evaluate(() => window.scrollBy(0, -260));
  await sleep(600);
  await mp.screenshot({ path: `${out}/m-notifications.png` });
  // 404
  const n = await b.newContext({ viewport: { width: 1280, height: 800 }, locale: "fr-CA", serviceWorkers: "block" });
  await n.addCookies(cookies);
  const np = await n.newPage();
  await np.goto(BASE + "/crm/cette-page-nexiste-pas", { waitUntil: "networkidle" });
  await sleep(800);
  await np.screenshot({ path: `${out}/page-introuvable.png` });
  await b.close();
})();
