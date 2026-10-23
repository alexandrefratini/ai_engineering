const { chromium } = require("/opt/node-tools/node_modules/playwright");
const { execSync, spawn } = require("child_process");
const [, , cookie, serverPid, out] = process.argv;
const BASE = "http://localhost:3000";
const LEAD = "cmvjm0613000ubl7d26em6t70";
const AGENCY = "cmvjm05un0000bl7ddebn4lfi";
const APP_DIR = "/home/user/endsi3g/fratex-agent/apps/app";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const results = [];
const check = (name, ok, detail = "") => {
  results.push({ name, ok });
  console.log(`${ok ? "OK " : "KO "} ${name}${detail ? " — " + detail : ""}`);
};
const notes = () => Number(execSync(`psql -U postgres -h localhost crm -Atc "select count(*) from \\"leadNote\\" where \\"leadId\\"='${LEAD}'"`).toString().trim());
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const c = await b.newContext({ viewport: { width: 1280, height: 1000 }, locale: "fr-CA", timezoneId: "America/Toronto" });
  await c.addCookies([
    { name: "__Secure-crm.session_token", value: cookie, domain: "localhost", path: "/", secure: true },
    { name: "crm.session_token", value: cookie, domain: "localhost", path: "/" },
  ]);
  const p = await c.newPage();
  const errors = [];
  p.on("pageerror", (e) => errors.push(e.message.slice(0, 200)));

  const leadUrl = `/crm/real-estate/leads/${LEAD}?agencyId=${AGENCY}`;
  const pages = ["/crm/real-estate/leads", "/crm/real-estate/inbox", "/crm/real-estate/pipeline", "/crm/account", leadUrl];
  await p.goto(BASE + pages[0], { waitUntil: "networkidle" });
  await p.evaluate(() => navigator.serviceWorker.ready);
  await p.reload({ waitUntil: "networkidle" });
  await sleep(800);
  check("le service worker contrôle la page", await p.evaluate(() => Boolean(navigator.serviceWorker.controller)));

  for (const path of pages) {
    await p.goto(BASE + path, { waitUntil: "networkidle" });
    await sleep(1500);
  }
  const caches1 = await p.evaluate(async () => {
    const o = {};
    for (const n of await caches.keys()) o[n] = (await (await caches.open(n)).keys()).length;
    return o;
  });
  console.log("caches:", JSON.stringify(caches1));
  const dataNames = Object.keys(caches1).filter((n) => n.startsWith("fratex-data-"));
  check("une seule copie de données, réservée à la personne connectée", dataNames.length === 1 && caches1[dataNames[0]] >= pages.length);
  check("fichiers de l'application gardés", Object.entries(caches1).some(([n, v]) => n.startsWith("fratex-static-") && v > 3));
  check("aucun identifiant de compte lisible dans les noms de cache", !/demo|user_|usr_/.test(dataNames.join("")));
  const cachedUrls = await p.evaluate(async () => {
    const urls = [];
    for (const n of await caches.keys()) if (n.startsWith("fratex-data-")) for (const r of await (await caches.open(n)).keys()) urls.push(new URL(r.url).pathname);
    return urls;
  });
  check("aucune route d'authentification ni de clés API dans la copie", !cachedUrls.some((u) => /api\/auth|apiKeys|sso\./.test(u)), cachedUrls.length + " entrées");
  const notesBefore = notes();

  process.kill(Number(serverPid), "SIGKILL");
  await sleep(1500);
  check("le serveur est bien arrêté", !(await fetch(BASE + "/sign-in").then(() => true).catch(() => false)));

  await p.goto(BASE + pages[0], { waitUntil: "domcontentloaded" }).catch(() => {});
  await sleep(3500);
  const body1 = await p.locator("body").innerText();
  check("liste des prospects (avec noms) affichée sans serveur", /Sophie Roy/.test(body1));
  const banner = await p.getByRole("status").filter({ hasText: "Hors ligne" }).first().innerText().catch(() => "");
  check("bandeau hors ligne avec la date d'enregistrement", /Hors ligne : données enregistrées le/.test(banner), banner);
  await p.screenshot({ path: `${out}/offline-1-leads.png` });

  await p.getByRole("link", { name: "Boîte de réception" }).first().click();
  await sleep(4500);
  check("navigation interne vers une page consultée", p.url().includes("inbox") && /Boîte de réception/.test(await p.locator("body").innerText()), p.url());
  await p.screenshot({ path: `${out}/offline-2-inbox.png` });

  await p.goto(BASE + "/crm/deals", { waitUntil: "domcontentloaded" }).catch(() => {});
  await sleep(2000);
  const h1 = await p.locator("h1").first().innerText().catch(() => "");
  check("page jamais consultée → page hors ligne", /Vous êtes hors ligne/.test(h1), h1);
  await p.screenshot({ path: `${out}/offline-3-never.png` });

  await p.goto(BASE + leadUrl, { waitUntil: "domcontentloaded" }).catch(() => {});
  await sleep(4000);
  check("fiche d'un prospect consultée, lisible hors ligne", /Sophie/.test(await p.locator("body").innerText()));
  const box = p.getByRole("textbox", { name: /note/i }).first();
  await box.fill("Note écrite hors ligne — ne doit jamais partir plus tard.");
  const t0 = Date.now();
  await p.getByRole("button", { name: "Ajouter la note" }).click();
  const toast = await p.getByText("Vous êtes hors ligne. Cette action n'a pas été envoyée").first().waitFor({ timeout: 6000 }).then(() => true).catch(() => false);
  check("l'écriture hors ligne échoue tout de suite avec un message", toast, `${Date.now() - t0} ms`);
  await p.screenshot({ path: `${out}/offline-4-write.png` });

  // Le serveur revient : rien ne doit partir tout seul
  const child = spawn("node", ["node_modules/.bin/next", "start", "-p", "3000"], { cwd: APP_DIR, env: process.env, detached: true, stdio: "ignore" });
  child.unref();
  let up = false;
  for (let i = 0; i < 40 && !up; i += 1) { await sleep(500); up = await fetch(BASE + "/sign-in").then(() => true).catch(() => false); }
  check("le serveur est revenu", up, "pid " + child.pid);
  await sleep(3000);
  check("aucune note n'est partie toute seule au retour du réseau", notes() === notesBefore, `${notesBefore} → ${notes()}`);
  await p.reload({ waitUntil: "networkidle" });
  await sleep(2500);
  const bannerBack = await p.getByRole("status").filter({ hasText: "Hors ligne" }).count();
  check("le bandeau disparaît quand le réseau revient", bannerBack === 0);
  await p.screenshot({ path: `${out}/offline-5-back.png` });

  console.log("erreurs de page:", errors.length ? errors : "aucune");
  console.log(results.every((r) => r.ok) ? "TOUT OK" : "ÉCHECS: " + results.filter((r) => !r.ok).map((r) => r.name).join(" | "));
  console.log("nouveau pid serveur:", child.pid);
  await b.close();
})();
