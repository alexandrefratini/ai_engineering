const { chromium } = require("/opt/node-tools/node_modules/playwright");
const [, , cookie, out] = process.argv;
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const c = await b.newContext({ viewport: { width: 1440, height: 900 }, locale: "fr-CA", timezoneId: "America/Toronto" });
  await c.addCookies([
    { name: "crm.session_token", value: cookie, domain: "localhost", path: "/" },
    { name: "googtrans", value: "/fr/en", domain: "localhost", path: "/" },
  ]);
  const p = await c.newPage();
  const errors = [];
  const reqs = [];
  p.on("pageerror", (e) => errors.push(e.message.slice(0, 160)));
  p.on("console", (m) => m.type() === "error" && errors.push("console: " + m.text().slice(0, 160)));
  p.on("requestfailed", (r) => reqs.push("FAIL " + r.url().slice(0, 100)));
  p.on("response", (r) => { if (r.url().includes("google")) reqs.push(r.status() + " " + r.url().slice(0, 100)); });
  await p.goto("http://localhost:3000/crm", { waitUntil: "networkidle" });
  await p.addStyleTag({ content: "nextjs-portal{display:none!important}" });
  await p.waitForTimeout(8000);
  const title = await p.locator("h1").first().innerText();
  const html = await p.evaluate(() => document.documentElement.className + " | lang=" + document.documentElement.lang);
  console.log("h1:", title);
  console.log("html:", html);
  console.log(reqs.join("\n"));
  await p.screenshot({ path: `${out}/trad-reel.png` });
  console.log("erreurs:", errors.length ? errors : "aucune");
  await b.close();
})();
