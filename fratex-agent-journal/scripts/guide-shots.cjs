const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs = require("fs");
const [, , cookieFile, marieFile, outDir] = process.argv;
const owner = fs.readFileSync(cookieFile, "utf8").trim();
const marie = fs.readFileSync(marieFile, "utf8").trim();
const KARIM = "cmvjm05x50009bl7dq6u0h1mo";
const AGENCY = "cmvjm05un0000bl7ddebn4lfi";
const MARIE_ID = "cmvjm05v70001bl7d4sbma8m0";
const CHAT = "cmvk2ijfs00067b7d8i3bdgj0";

const DESKTOP = [
  ["accueil", "/crm", 1100],
  ["accueil-ventes", "/crm?vue=ventes&scope=everyone", 1000],
  ["prospects", "/crm/real-estate/leads", 800],
  ["prospects-vide", "/crm/real-estate/leads?search=zzzzzz", 600],
  ["fiche", `/crm/real-estate/leads/${KARIM}?agencyId=${AGENCY}`, 2100],
  ["pipeline", "/crm/real-estate/pipeline", 900],
  ["boite-liste", "/crm/real-estate/inbox", 800],
  ["boite-conversation", `/crm/real-estate/inbox?leadId=${KARIM}`, 900],
  ["portail", "/crm/real-estate/portal", 1500],
  ["estimateur", "/crm/real-estate/valuation", 1700],
  ["courtiers", "/crm/real-estate/realtors", 800],
  ["nouveau-courtier", "/crm/real-estate/realtors/new", 1700],
  ["onboarding-courtier", "/onboarding/realtor", 1700],
  ["assistant-accueil", "/crm/chat", 900],
  ["assistant-conversation", `/crm/chat/${CHAT}`, 900],
  ["agents", "/crm/agents", 800],
  ["contacts", "/crm/contacts", 900],
  ["entreprises", "/crm/companies", 900],
  ["affaires", "/crm/deals", 900],
  ["reglages", "/crm/settings", 1000],
  ["suivi", "/crm/settings/tracking", 700],
  ["connexions", "/crm/settings/connections", 1300],
  ["connexion-meta", `/crm/settings/connections/meta-ads?agencyId=${AGENCY}`, 1000],
  ["connexion-twilio", `/crm/settings/connections/twilio?agencyId=${AGENCY}`, 1000],
  ["connexion-gemini", `/crm/settings/connections/gemini?agencyId=${AGENCY}`, 900],
  ["connexion-agenda", `/crm/settings/connections/realtor-calendar?agencyId=${AGENCY}&client=${MARIE_ID}`, 1000],
  ["connexion-slack", "/crm/settings/connections/slack", 1300],
  ["devises", "/crm/settings/currencies", 1300],
  ["membres", "/crm/settings/members", 800],
  ["cles-api", "/crm/settings/api-keys", 700],
  ["sso", "/crm/settings/sso", 700],
  ["compte", "/crm/account", 1500],
  ["support", "/crm/support", 1100],
];
const MARIE = [
  ["courtier-accueil", "/crm", 1000],
  ["courtier-prospects", "/crm/real-estate/leads", 800],
  ["courtier-boite", "/crm/real-estate/inbox", 800],
  ["courtier-portail", "/crm/real-estate/portal", 1500],
];
const PUBLIC = [
  ["connexion", "/sign-in", 800],
  ["agenda-connecte", "/agenda-connecte?statut=ok", 700],
];
const MOBILE = [
  ["m-accueil", "/crm", 1500],
  ["m-prospects", "/crm/real-estate/leads", 844],
  ["m-fiche", `/crm/real-estate/leads/${KARIM}?agencyId=${AGENCY}`, 2400],
  ["m-pipeline", "/crm/real-estate/pipeline", 844],
  ["m-boite-liste", "/crm/real-estate/inbox", 844],
  ["m-boite-conversation", `/crm/real-estate/inbox?leadId=${KARIM}`, 844],
  ["m-portail", "/crm/real-estate/portal", 2000],
  ["m-estimateur", "/crm/real-estate/valuation", 2200],
  ["m-courtiers", "/crm/real-estate/realtors", 844],
  ["m-connexions", "/crm/settings/connections", 1600],
  ["m-support", "/crm/support", 1700],
  ["m-compte", "/crm/account", 2400],
  ["m-assistant", "/crm/chat", 844],
];

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const errors = [];
  async function run(list, cookie, width, label, theme) {
    const c = await b.newContext({ viewport: { width, height: 900 }, locale: "fr-CA", timezoneId: "America/Toronto", deviceScaleFactor: 1 });
    if (cookie) await c.addCookies([{ name: "crm.session_token", value: cookie, domain: "localhost", path: "/" }]);
    if (theme) await c.addInitScript((t) => localStorage.setItem("theme", t), theme);
    const p = await c.newPage();
    p.on("pageerror", (e) => errors.push(`${label}: ${e.message.slice(0, 120)}`));
    for (const [name, url, height] of list) {
      await p.setViewportSize({ width, height });
      try {
        await p.goto("http://localhost:3000" + url, { waitUntil: "networkidle", timeout: 30000 });
      } catch (e) {
        errors.push(`${name}: ${e.message.slice(0, 80)}`);
      }
      await p.addStyleTag({ content: "nextjs-portal{display:none!important}" });
      await p.waitForTimeout(2200);
      await p.screenshot({ path: `${outDir}/${name}.jpg`, type: "jpeg", quality: 84 });
      console.log(name);
    }
    await c.close();
  }
  await run(DESKTOP, owner, 1440, "bureau");
  await run(MARIE, marie, 1440, "courtier");
  await run(PUBLIC, null, 1440, "public");
  await run(MOBILE, owner, 390, "mobile");
  await run([["sombre-accueil", "/crm", 1000], ["sombre-boite", `/crm/real-estate/inbox?leadId=${KARIM}`, 900]], owner, 1440, "sombre", "dark");

  const c = await b.newContext({ viewport: { width: 1440, height: 800 }, locale: "fr-CA", timezoneId: "America/Toronto" });
  await c.addCookies([{ name: "crm.session_token", value: owner, domain: "localhost", path: "/" }]);
  const p = await c.newPage();
  await p.goto("http://localhost:3000/crm/real-estate/leads", { waitUntil: "networkidle" });
  await p.addStyleTag({ content: "nextjs-portal{display:none!important}" });
  await p.keyboard.press("Control+k");
  await p.keyboard.type("kar");
  await p.waitForTimeout(1500);
  await p.screenshot({ path: `${outDir}/recherche.jpg`, type: "jpeg", quality: 84 });
  await p.keyboard.press("Escape");
  await p.waitForTimeout(400);
  await p.getByRole("button", { name: /Équipe : / }).click();
  await p.waitForTimeout(800);
  await p.screenshot({ path: `${outDir}/presence.jpg`, type: "jpeg", quality: 84 });
  await p.keyboard.press("Escape");
  await p.getByRole("button", { name: "Traduire la page" }).click();
  await p.waitForTimeout(600);
  await p.screenshot({ path: `${outDir}/traduction.jpg`, type: "jpeg", quality: 84 });
  await p.keyboard.press("Escape");
  await p.getByRole("button", { name: "Menu du compte" }).click();
  await p.waitForTimeout(600);
  await p.screenshot({ path: `${outDir}/menu-compte.jpg`, type: "jpeg", quality: 84 });
  await c.close();

  const m = await b.newContext({ viewport: { width: 390, height: 844 }, locale: "fr-CA", timezoneId: "America/Toronto" });
  await m.addCookies([{ name: "crm.session_token", value: owner, domain: "localhost", path: "/" }]);
  const q = await m.newPage();
  await q.goto("http://localhost:3000/crm", { waitUntil: "networkidle" });
  await q.addStyleTag({ content: "nextjs-portal{display:none!important}" });
  await q.getByRole("button", { name: "Ouvrir la navigation" }).click();
  await q.waitForTimeout(800);
  await q.screenshot({ path: `${outDir}/m-menu.jpg`, type: "jpeg", quality: 84 });
  await m.close();
  await b.close();
  console.log("erreurs:", errors.length ? errors : "aucune");
})();
