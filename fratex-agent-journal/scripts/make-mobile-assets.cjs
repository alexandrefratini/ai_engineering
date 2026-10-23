const { chromium } = require("/opt/node-tools/node_modules/playwright");
const fs = require("fs");
const out = process.argv[2];
const GLYPH = "M160 120h200v68H232v38h88v64h-88v102h-72V120Z";
function svg(size, bg, scale, fill = "#fff") {
  const tx = size / 2 - 260 * scale, ty = size / 2 - 256 * scale;
  const rect = bg ? `<rect width="${size}" height="${size}" fill="${bg}"/>` : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">${rect}<path transform="translate(${tx} ${ty}) scale(${scale})" d="${GLYPH}" fill="${fill}"/></svg>`;
}
const jobs = [
  ["icon-only", 1024, svg(1024, "#D83C16", 2.2), false],
  ["icon-foreground", 1024, svg(1024, null, 1.7), true],
  ["icon-background", 1024, `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"><rect width="1024" height="1024" fill="#D83C16"/></svg>`, false],
  ["splash", 2732, svg(2732, "#D83C16", 2.4), false],
  ["splash-dark", 2732, svg(2732, "#141414", 2.4, "#D83C16"), false],
];
(async () => {
  fs.mkdirSync(out, { recursive: true });
  const b = await chromium.launch({ executablePath: "/opt/pw-browsers/chromium" });
  for (const [name, size, markup, transparent] of jobs) {
    const p = await b.newPage({ viewport: { width: size, height: size } });
    await p.setContent(`<style>html,body{margin:0;background:transparent}</style>${markup}`);
    await p.screenshot({ path: `${out}/${name}.png`, omitBackground: transparent, clip: { x: 0, y: 0, width: size, height: size } });
    await p.close();
  }
  await b.close();
})();
