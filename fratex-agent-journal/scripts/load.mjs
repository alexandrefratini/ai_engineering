const [, , url, concurrency, seconds, cookie] = process.argv;
const headers = cookie ? { cookie } : {};
const latencies = [];
const statuses = new Map();
let errors = 0;
const stopAt = Date.now() + Number(seconds) * 1000;
async function loop() {
  while (Date.now() < stopAt) {
    const started = performance.now();
    try {
      const response = await fetch(url, { headers, redirect: "manual", signal: AbortSignal.timeout(20000) });
      await response.arrayBuffer();
      statuses.set(response.status, (statuses.get(response.status) ?? 0) + 1);
    } catch {
      errors += 1;
    }
    latencies.push(performance.now() - started);
  }
}
await Promise.all(Array.from({ length: Number(concurrency) }, loop));
latencies.sort((a, b) => a - b);
const q = (p) => latencies[Math.min(latencies.length - 1, Math.floor(latencies.length * p))].toFixed(0);
console.log(JSON.stringify({ url: url.slice(0, 70), requests: latencies.length, perSecond: (latencies.length / Number(seconds)).toFixed(0), p50: q(0.5), p95: q(0.95), p99: q(0.99), max: latencies.at(-1).toFixed(0), statuses: Object.fromEntries(statuses), errors }));
