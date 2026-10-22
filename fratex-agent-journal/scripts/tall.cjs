const { chromium } = require("/opt/node-tools/node_modules/playwright");
const [, , cookie, out, width, height, ...routes] = process.argv;
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const c = await b.newContext({ viewport: { width: Number(width), height: Number(height) }, locale: "fr-CA", timezoneId: "America/Toronto" });
  if (cookie) await c.addCookies([{ name: "crm.session_token", value: cookie, domain: "localhost", path: "/" }]);
  const p = await c.newPage();
  const errors = [];
  p.on("pageerror", (e) => errors.push(e.message.slice(0, 200)));
  p.on("console", (m) => m.type() === "error" && errors.push("console: " + m.text().slice(0, 200)));
  for (const r of routes) {
    const i = r.indexOf("="); const name = r.slice(0, i), url = r.slice(i + 1);
    await p.goto("http://localhost:3000" + url, { waitUntil: "networkidle", timeout: 90000 });
    await p.addStyleTag({ content: "nextjs-portal{display:none!important}" });
    await p.waitForTimeout(2500);
    await p.screenshot({ path: `${out}/${name}.png` });
    console.log(name, "->", p.url());
  }
  console.log("erreurs:", errors.length ? errors : "aucune");
  await b.close();
})();
