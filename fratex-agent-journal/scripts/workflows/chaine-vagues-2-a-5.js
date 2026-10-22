export const meta = {
  name: 'fratex-rebuild-chain',
  description: 'Run the remaining rebuild waves in order: wiring, French, AI assistant tools, full verification (each ends with journal, commit and push)',
  phases: [
    { title: 'Vague 2', detail: 'câblage des pages' },
    { title: 'Vague 3', detail: 'français partout' },
    { title: 'Vague 4', detail: 'assistant IA immobilier' },
    { title: 'Vague 5', detail: 'vérification complète' },
  ],
}
const DIR = '/tmp/claude-0/-home-user-ai-engineering/c993277d-f1c4-5244-883e-a4d59bd72f58/scratchpad'
const WAVES = [
  ['Vague 2', `${DIR}/wf2.js`],
  ['Vague 3', `${DIR}/wf3.js`],
  ['Vague 4', `${DIR}/wf4.js`],
  ['Vague 5', `${DIR}/wf5.js`],
]
const out = {}
for (const [title, scriptPath] of WAVES) {
  phase(title)
  try {
    out[title] = await workflow({ scriptPath })
    log(`${title} terminée`)
  } catch (error) {
    out[title] = { error: String(error) }
    log(`${title} en échec : ${String(error).slice(0, 200)}`)
  }
}
return out
