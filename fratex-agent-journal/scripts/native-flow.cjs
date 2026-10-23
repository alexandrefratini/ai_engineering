const { chromium } = require("/opt/node-tools/node_modules/playwright");
const crypto = require("crypto");
const fs = require("fs");
const [, , cookieFile, outDir] = process.argv;
const owner = fs.readFileSync(cookieFile, "utf8").trim();
const BASE = "http://localhost:3000";
const checks = [];
const ok = (name, value, expected) => checks.push([name, value === expected || (expected === undefined && value), value]);

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const verifier = crypto.randomBytes(32).toString("base64url");
  const challenge = crypto.createHash("sha256").update(verifier).digest("base64url");

  const app = await b.newContext({
    viewport: { width: 390, height: 844 },
    locale: "fr-CA",
    userAgent: "Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 Chrome/130 Mobile Safari/537.36 FratexMobile/1.0",
  });
  const appPage = await app.newPage();
  await appPage.goto(BASE + "/sign-in", { waitUntil: "networkidle" });
  await appPage.addStyleTag({ content: "nextjs-portal{display:none!important}" });
  await appPage.waitForTimeout(800);
  ok("dans l'app : bouton navigateur", await appPage.getByRole("button", { name: "Continuer dans le navigateur" }).count(), 1);
  ok("dans l'app : pas de bouton Google", await appPage.getByRole("button", { name: /Google/ }).count(), 0);
  await appPage.screenshot({ path: `${outDir}/native-connexion.jpg`, type: "jpeg", quality: 84 });
  await appPage.evaluate((v) => localStorage.setItem("fratex.native.verifier", JSON.stringify({ verifier: v, at: Date.now() })), verifier);

  const phone = await b.newContext({ viewport: { width: 390, height: 844 }, locale: "fr-CA" });
  await phone.addCookies([{ name: "crm.session_token", value: owner, domain: "localhost", path: "/" }]);
  const browserPage = await phone.newPage();
  const attempted = [];
  browserPage.on("requestfailed", (r) => attempted.push(r.url()));
  await browserPage.goto(`${BASE}/sign-in?native=${challenge}`, { waitUntil: "domcontentloaded" }).catch(() => {});
  await browserPage.waitForURL(/native\/handoff/, { timeout: 15000 });
  await browserPage.waitForTimeout(2500);
  await browserPage.addStyleTag({ content: "nextjs-portal{display:none!important}" }).catch(() => {});
  ok("navigateur : page de retour", browserPage.url().includes("/native/handoff"), true);
  ok("navigateur : tente d'ouvrir ca.fratex.agent://auth/done", attempted.some((u) => u.startsWith("ca.fratex.agent://auth")), true);
  await browserPage.screenshot({ path: `${outDir}/native-retour.jpg`, type: "jpeg", quality: 84 });

  const wrong = await appPage.evaluate(async () => (await fetch("/api/native-auth/exchange", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ verifier: "x".repeat(43) }) })).status);
  ok("mauvais vérificateur refusé", wrong, 400);
  const status = await appPage.evaluate(async (v) => (await fetch("/api/native-auth/exchange", { method: "POST", headers: { "content-type": "application/json" }, credentials: "include", body: JSON.stringify({ verifier: v }) })).status, verifier);
  ok("échange avec le bon vérificateur", status, 200);
  const again = await appPage.evaluate(async (v) => (await fetch("/api/native-auth/exchange", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ verifier: v }) })).status, verifier);
  ok("deuxième échange refusé", again, 400);
  await appPage.goto(BASE + "/", { waitUntil: "networkidle" });
  await appPage.addStyleTag({ content: "nextjs-portal{display:none!important}" });
  await appPage.waitForTimeout(2000);
  ok("dans l'app : connecté, hors de /sign-in", /\/crm/.test(appPage.url()), true);
  await appPage.screenshot({ path: `${outDir}/native-connecte.jpg`, type: "jpeg", quality: 84 });
  await b.close();
  for (const [name, pass, value] of checks) console.log(pass ? "OK  " : "ÉCHEC", name, pass ? "" : `(valeur: ${value})`);
  process.exit(checks.every(([, pass]) => pass) ? 0 : 1);
})().catch((e) => { console.error(e); process.exit(2); });
