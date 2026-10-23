const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs = require("fs");
const [, , cookieFile, marieFile, outDir] = process.argv;
const owner = fs.readFileSync(cookieFile, "utf8").trim();
const marie = fs.readFileSync(marieFile, "utf8").trim();
const BASE = "http://localhost:3000/crm";

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  const errors = [];
  const checks = [];
  async function open(width, height, cookie, theme) {
    const c = await b.newContext({ viewport: { width, height }, locale: "fr-CA", timezoneId: "America/Toronto" });
    await c.addCookies([{ name: "crm.session_token", value: cookie, domain: "localhost", path: "/" }]);
    if (theme) await c.addInitScript((t) => localStorage.setItem("theme", t), theme);
    const p = await c.newPage();
    p.on("pageerror", (e) => errors.push(e.message.slice(0, 140)));
    return { c, p };
  }
  async function go(p, path, wait = 2200) {
    await p.goto(BASE + path, { waitUntil: "networkidle", timeout: 40000 });
    await p.addStyleTag({ content: "nextjs-portal{display:none!important}" });
    await p.waitForTimeout(wait);
  }
  const shot = (p, name, full = false) => p.screenshot({ path: `${outDir}/${name}.jpg`, type: "jpeg", quality: 84, fullPage: full });

  let { c, p } = await open(1440, 1000, owner);
  await go(p, "/team");
  await shot(p, "equipe-liste");
  checks.push(["lignes de la liste", await p.locator("ul.divide-y > li").count()]);
  checks.push(["titre", await p.locator("h1").first().innerText()]);
  await p.getByRole("radio", { name: "En ligne" }).click();
  await p.waitForTimeout(1500);
  await shot(p, "equipe-en-ligne");
  checks.push(["lignes (en ligne)", await p.locator("ul.divide-y > li").count()]);
  await p.getByRole("radio", { name: "Tous" }).click();
  await p.getByPlaceholder("Rechercher un nom ou un courriel").fill("zzzz");
  await p.waitForTimeout(1500);
  await shot(p, "equipe-vide");
  await p.getByPlaceholder("Rechercher un nom ou un courriel").fill("");
  await p.waitForTimeout(1200);
  await p.getByRole("link", { name: /Samuel Lapointe/ }).click();
  await p.waitForURL(/team\/demo-samuel/);
  await p.waitForTimeout(2500);
  await shot(p, "membre-activite", true);
  checks.push(["fil d'activité", await p.locator("ol > li").count()]);
  await p.getByRole("tab", { name: "Tâches" }).click();
  await p.waitForTimeout(700);
  await shot(p, "membre-taches", true);
  await p.getByRole("tab", { name: "Rôle et accès" }).click();
  await p.waitForTimeout(700);
  await shot(p, "membre-acces", true);
  await p.getByRole("link", { name: "Retour à l'équipe" }).click();
  await p.waitForURL(/\/team$/);
  await c.close();

  ({ c, p } = await open(1440, 900, marie));
  await go(p, "/team");
  checks.push(["Marie voit (lignes)", await p.locator("ul.divide-y > li").count()]);
  checks.push(["Marie rail contient Équipe", await p.getByRole("link", { name: "Équipe", exact: true }).count()]);
  await shot(p, "equipe-courtier");
  await go(p, "/team/demo-samuel");
  await shot(p, "membre-refuse");
  checks.push(["Marie voit Samuel (devrait être introuvable)", await p.getByText("Membre introuvable").count()]);
  await c.close();

  ({ c, p } = await open(390, 844, owner));
  await go(p, "/team");
  await shot(p, "m-equipe-liste", true);
  await go(p, "/team/demo-marie");
  await shot(p, "m-membre", true);
  await c.close();

  ({ c, p } = await open(1440, 1000, owner, "dark"));
  await go(p, "/team/demo-user");
  await shot(p, "membre-sombre", true);
  await c.close();
  await b.close();
  console.log(JSON.stringify(checks, null, 1));
  console.log("erreurs:", errors.length ? errors : "aucune");
})();
