const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs = require("fs");
const [, , cookie, out] = process.argv;
const BASE = "http://localhost:3000";
const ID = { contact: "cmvjm04kl000xaw7ddzzoy4re", company: "cmvjm04gr000aaw7d6y3t7pxb", deal: "seed-deal-retool-0", lead: "cmvjm063r001bbl7d1wifzomr", user: "seed-ada-okafor", chat: "cmvk2gelv00007b7dij3m9i73", agency: "cmvjm05un0000bl7ddebn4lfi" };
const ROUTES = [
  "/crm", "/crm/account", "/crm/agents", "/crm/chat", `/crm/chat/${ID.chat}`,
  "/crm/companies", `/crm/companies/${ID.company}`, "/crm/contacts", `/crm/contacts/${ID.contact}`,
  "/crm/deals", `/crm/deals/${ID.deal}`,
  "/crm/real-estate", "/crm/real-estate/activity", "/crm/real-estate/inbox", "/crm/real-estate/leads",
  `/crm/real-estate/leads/${ID.lead}?agencyId=${ID.agency}`, "/crm/real-estate/pipeline", "/crm/real-estate/portal",
  "/crm/real-estate/realtors", "/crm/real-estate/realtors/new", "/crm/real-estate/valuation",
  "/crm/settings", "/crm/settings/api-keys", "/crm/settings/connections", "/crm/settings/connections/gemini",
  "/crm/settings/connections/google", "/crm/settings/connections/intake", "/crm/settings/connections/meta-ads",
  "/crm/settings/connections/microsoft", "/crm/settings/connections/realtor-calendar", "/crm/settings/connections/slack",
  "/crm/settings/connections/slack/people", "/crm/settings/connections/twilio", "/crm/settings/currencies",
  "/crm/settings/members", "/crm/settings/sso", "/crm/settings/tracking", "/crm/support", "/crm/team", `/crm/team/${ID.user}`,
  "/crm/cette-page-nexiste-pas",
];
const BAD_TEXT = /This page couldn.t load|A server error occurred|Failed to fetch|UNAUTHORIZED|Internal server error|\bundefined\b|\[object Object\]|\bNaN\b|Application error|Cette page n.a pas pu se charger/;
const IGNORED_CONSOLE = /Download the React DevTools|Failed to load resource.*(favicon|manifest)|googtrans|translate\.google/i;
const findings = [];
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  for (const [label, viewport] of [["bureau", { width: 1280, height: 900 }], ["mobile", { width: 390, height: 844 }]]) {
    const c = await b.newContext({ viewport, locale: "fr-CA", timezoneId: "America/Toronto", serviceWorkers: "block", isMobile: label === "mobile", hasTouch: label === "mobile" });
    await c.addCookies([
      { name: "__Secure-crm.session_token", value: cookie, domain: "localhost", path: "/", secure: true },
      { name: "crm.session_token", value: cookie, domain: "localhost", path: "/" },
    ]);
    for (const path of ROUTES) {
      const p = await c.newPage();
      const issues = [];
      p.on("pageerror", (e) => issues.push("erreur de page: " + e.message.slice(0, 110)));
      p.on("console", (m) => { if (m.type() === "error" && !IGNORED_CONSOLE.test(m.text())) issues.push("console: " + m.text().slice(0, 110)); });
      p.on("requestfailed", (r) => { if (!/_rsc=|\/_next\/image|googleapis|gstatic|translate/.test(r.url())) issues.push("requête échouée: " + r.url().slice(0, 90)); });
      p.on("response", (r) => { if (r.status() >= 400 && !/\/_next\/image|favicon/.test(r.url())) issues.push(`HTTP ${r.status()}: ${r.url().replace(BASE, "").slice(0, 90)}`); });
      let status = "?";
      try {
        const r = await p.goto(BASE + path, { waitUntil: path.startsWith("/crm/chat/") ? "domcontentloaded" : "networkidle", timeout: 45000 });
        status = r.status();
        await p.waitForTimeout(1200);
      } catch (e) { issues.push("navigation: " + e.message.slice(0, 80)); }
      const text = (await p.locator("body").innerText().catch(() => "")).replace(/\s+/g, " ");
      const bad = text.match(BAD_TEXT);
      if (bad) issues.push("texte suspect: «" + bad[0] + "» … " + text.slice(Math.max(0, text.search(BAD_TEXT) - 40), text.search(BAD_TEXT) + 60));
      const overflow = await p.evaluate(() => document.documentElement.scrollWidth - window.innerWidth).catch(() => 0);
      if (label === "mobile" && overflow > 2) issues.push(`débordement horizontal de ${overflow}px`);
      const english = /\b(Loading|Sign in|Submit|Cancel|Save|Delete|Search)\b/.exec(text);
      if (issues.length || path.includes("pas")) {
        const file = `${out}/crawl-${label}-${path.replace(/[^a-z0-9]+/gi, "_").slice(0, 50)}.png`;
        await p.screenshot({ path: file });
      }
      findings.push({ label, path, status, issues });
      console.log(`${issues.length ? "KO" : "OK"} ${label} ${status} ${path.slice(0, 60)}${issues.length ? "\n     - " + [...new Set(issues)].slice(0, 4).join("\n     - ") : ""}`);
      await p.close();
    }
    await c.close();
  }
  fs.writeFileSync(`${out}/crawl.json`, JSON.stringify(findings, null, 1));
  const ko = findings.filter((f) => f.issues.length);
  console.log(`\n${findings.length} chargements, ${ko.length} avec problèmes`);
  await b.close();
})();
