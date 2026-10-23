const { chromium } = require("/opt/node-tools/node_modules/playwright");
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const c = await b.newContext({ viewport: { width: 390, height: 844 }, locale: "fr-CA" });
  const p = await c.newPage();
  await p.goto("http://localhost:3100/sign-in", { waitUntil: "networkidle" });
  const registered = await p.evaluate(async () => {
    const reg = await navigator.serviceWorker.ready;
    return { scope: reg.scope, active: Boolean(reg.active) };
  });
  console.log("service worker:", JSON.stringify(registered));
  const manifest = await p.evaluate(async () => {
    const href = document.querySelector('link[rel="manifest"]').href;
    const m = await (await fetch(href)).json();
    return { href, name: m.name, display: m.display, icons: m.icons.length };
  });
  console.log("manifest:", JSON.stringify(manifest));
  await p.reload({ waitUntil: "networkidle" });
  await c.setOffline(true);
  await p.goto("http://localhost:3100/sign-in").catch((e) => console.log("goto offline:", e.message.slice(0, 60)));
  await p.waitForTimeout(800);
  console.log("hors ligne ->", (await p.locator("h1").first().innerText().catch(() => "aucun h1")));
  await p.screenshot({ path: process.argv[2], type: "jpeg", quality: 80 });
  await c.setOffline(false);
  await b.close();
})();
