const { chromium } = require("/opt/node-tools/node_modules/playwright");
const { execSync } = require("child_process");
(async () => {
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const c = await b.newContext({ viewport: { width: 390, height: 844 }, locale: "fr-CA" });
  const p = await c.newPage();
  await p.goto("http://localhost:3100/sign-in", { waitUntil: "networkidle" });
  await p.evaluate(() => navigator.serviceWorker.ready);
  await p.reload({ waitUntil: "networkidle" });
  const pid = process.argv[2];
  console.log("arrêt du serveur pid", pid);
  if (!pid || Number(pid) < 2) throw new Error("pid manquant"); process.kill(Number(pid), "SIGKILL");
  await new Promise((r) => setTimeout(r, 1500));
  await p.goto("http://localhost:3100/sign-in").catch((e) => console.log("goto:", e.message.slice(0, 80)));
  await p.waitForTimeout(800);
  console.log("serveur arrêté ->", await p.locator("h1").first().innerText().catch(() => "aucun h1"));
  await p.screenshot({ path: "pwa-offline.jpg", type: "jpeg", quality: 80 });
  await b.close();
})();
