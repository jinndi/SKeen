import { readFile } from 'node:fs/promises'
import { performance } from 'node:perf_hooks'
import vm from 'node:vm'

const templateSource = await readFile(new URL('./template.js', import.meta.url), 'utf8')
const rounds = Number(process.env.BENCH_ROUNDS ?? 5)

if (!Number.isInteger(rounds) || rounds < 1) {
  throw new Error('BENCH_ROUNDS must be a positive integer')
}

const regions = [
  ['🇩🇪', 'Berlin'],
  ['🇫🇮', 'Helsinki'],
  ['🇳🇱', 'Amsterdam'],
  ['🇺🇸', 'New York'],
  ['🇯🇵', 'Tokyo'],
  ['🇬🇧', 'London'],
  ['🇫🇷', 'Paris'],
  ['🇨🇦', 'Toronto'],
  ['🇸🇪', 'Stockholm'],
  ['🇵🇱', 'Warsaw'],
  ['🇪🇸', 'Madrid'],
  ['🇦🇺', 'Canberra'],
]
const markers = [
  'vless',
  'proxy',
  'v2',
  'foo|bar',
  'edge|node',
  'test',
  '0.5x',
  'other',
  'server-a',
  'server-b',
]
function makeProxies(count) {
  return Array.from({ length: count }, (_, index) => {
    const marker = markers[index % markers.length]
    if (marker.startsWith('server-')) return { tag: `${marker}-${index}` }

    const [flag, city] = regions[index % regions.length]
    return { tag: `${flag} ${city} ${marker}-${index}` }
  })
}

async function runTemplate(artifactJson, contentJson, outbound) {
  const context = {
    $arguments: {
      type: 'collection',
      name: 'benchmark',
      outbound,
      includeUnsupportedProxy: false,
    },
    $content: contentJson,
    ProxyUtils: {},
    produceArtifact: async () => artifactJson,
    console: { log() {} },
  }

  const output = await vm.runInNewContext(
    `(async () => {\n${templateSource}\nreturn $content\n})()`,
    context,
  )

  return JSON.parse(output)
}

function median(values) {
  const sorted = [...values].sort((left, right) => left - right)
  const middle = Math.floor(sorted.length / 2)
  return sorted.length % 2
    ? sorted[middle]
    : (sorted[middle - 1] + sorted[middle]) / 2
}

const scenarios = [
  { name: 'small', proxies: 100, selectors: 1, pattern: 'vless', matches: 'simple' },
  { name: 'typical', proxies: 500, selectors: 10, pattern: 'vless', matches: 'simple' },
  { name: 'large', proxies: 1500, selectors: 30, pattern: 'vless', matches: 'simple' },
  {
    name: 'regex-heavy',
    proxies: 500,
    selectors: 10,
    pattern: String.raw`(?:vless|proxy)|v[1-3]|foo\|bar|edge[|]node|test|0\.5x|^server-(?:a|b)-\d+$🚫proxy|v[1-3]|foo\|bar|edge[|]node|test|0\.5x|^server-(?:a|b)-\d+$`,
  },
]

console.log(`Sub-Store template benchmark; warm-up: 1, measured runs: ${rounds}`)
console.log('Includes template initialization and country detection; excludes network/subscription fetch.')

for (const scenario of scenarios) {
  const artifactJson = JSON.stringify({
    outbounds: makeProxies(scenario.proxies),
    endpoints: [],
  })
  const contentJson = JSON.stringify({
    outbounds: Array.from({ length: scenario.selectors }, (_, index) => ({
      tag: `Bench selector ${index + 1}`,
      type: 'selector',
      outbounds: [],
    })),
    endpoints: [],
  })
  const outbound = `📂Bench🔖${scenario.pattern}🌐🚫`
  const expectedMatches = Array.from(
    { length: scenario.proxies },
    (_, index) => markers[index % markers.length],
  ).filter(marker => marker === 'vless').length
  const samples = []
  for (let run = 0; run <= rounds; run++) {
    const start = performance.now()
    const result = await runTemplate(artifactJson, contentJson, outbound)
    const elapsed = performance.now() - start

    if (run > 0) samples.push(elapsed)
    const selectedGroups = result.outbounds.filter(outbound =>
      outbound.tag.startsWith('Bench selector ')
    )
    if (
      selectedGroups.length !== scenario.selectors ||
      selectedGroups.some(group => group.outbounds.length !== expectedMatches)
    ) {
      throw new Error(`Unexpected benchmark output for ${scenario.name}`)
    }
  }

  console.log(
    `${scenario.name.padEnd(11)} ${String(scenario.proxies).padStart(4)} proxies, ` +
    `${String(scenario.selectors).padStart(2)} selectors: ` +
    `median ${median(samples).toFixed(1)} ms; min ${Math.min(...samples).toFixed(1)} ms`,
  )
}
