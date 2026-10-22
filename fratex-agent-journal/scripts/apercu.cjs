const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs = require("fs");
const [, , dir, out] = process.argv;
const A = "agencyId=cmvjm05un0000bl7ddebn4lfi";
const OWNER = [
  ["01-accueil", "/crm"],
  ["02-accueil-ventes", "/crm?vue=ventes"],
  ["03-prospects", "/crm/real-estate/leads"],
  ["04-fiche-karim", `/crm/real-estate/leads/cmvjm05x50009bl7dq6u0h1mo?${A}`],
  ["05-fiche-sophie", `/crm/real-estate/leads/cmvjm0613000ubl7d26em6t70?${A}`],
  ["06-pipeline", "/crm/real-estate/pipeline"],
  ["07-boite-reception", "/crm/real-estate/inbox"],
  ["08-boite-sophie", `/crm/real-estate/inbox?${A}&leadId=cmvjm0613000ubl7d26em6t70`],
  ["09-portail", "/crm/real-estate/portal"],
  ["10-estimateur", "/crm/real-estate/valuation"],
  ["11-courtiers", "/crm/real-estate/realtors"],
  ["12-nouveau-courtier", "/crm/real-estate/realtors/new"],
  ["13-onboarding-courtier", "/onboarding/realtor"],
  ["14-connexions", "/crm/settings/connections"],
  ["15-agenda-google", "/crm/settings/connections/realtor-calendar"],
  ["16-meta", "/crm/settings/connections/meta-ads"],
  ["17-parametres", "/crm/settings"],
  ["18-membres", "/crm/settings/members"],
  ["19-assistant-ia", "/crm/chat"],
  ["20-contacts", "/crm/contacts"],
  ["21-entreprises", "/crm/companies"],
  ["22-affaires", "/crm/deals"],
];
const MARIE = [
  ["m1-accueil", "/crm"],
  ["m2-prospects", "/crm/real-estate/leads"],
  ["m3-portail", "/crm/real-estate/portal"],
];
const MOBILE = [
  ["x1-accueil", "/crm"],
  ["x2-prospects", "/crm/real-estate/leads"],
  ["x3-fiche", `/crm/real-estate/leads/cmvjm05x50009bl7dq6u0h1mo?${A}`],
  ["x4-boite", "/crm/real-estate/inbox"],
];
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const report = [];
  async function run(cookieFile, list, width, height) {
    const c = await b.newContext({ viewport: { width, height }, locale: "fr-CA", timezoneId: "America/Toronto" });
    await c.addCookies([{ name: "crm.session_token", value: fs.readFileSync(`${dir}/${cookieFile}`, "utf8").trim(), domain: "localhost", path: "/" }]);
    const p = await c.newPage();
    let errors = [];
    p.on("pageerror", (e) => errors.push("pageerror: " + e.message.slice(0, 160)));
    p.on("console", (m) => m.type() === "error" && errors.push("console: " + m.text().slice(0, 160)));
    for (const [name, url] of list) {
      errors = [];
      let status = "ok";
      try {
        await p.goto("http://localhost:3000" + url, { waitUntil: "networkidle", timeout: 60000 });
        await p.waitForTimeout(2200);
        await p.screenshot({ path: `${out}/${name}.png`, fullPage: true });
      } catch (e) { status = "ÉCHEC " + String(e).slice(0, 100); }
      report.push({ name, url, final: p.url().replace("http://localhost:3000", ""), status, errors: [...new Set(errors)].slice(0, 4) });
    }
    await c.close();
  }
  await run("cookie.txt", OWNER, 1440, 900);
  await run("cookie-marie.txt", MARIE, 1440, 900);
  await run("cookie.txt", MOBILE, 390, 844);
  fs.writeFileSync(`${out}/rapport.json`, JSON.stringify(report, null, 1));
  for (const r of report) console.log(r.name.padEnd(24), r.status.padEnd(6), r.final.slice(0, 60), r.errors.length ? "| " + r.errors.join(" | ") : "");
  await b.close();
})();
