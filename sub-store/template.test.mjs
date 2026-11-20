import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'
import vm from 'node:vm'

const templateSource = await readFile(new URL('./template.js', import.meta.url), 'utf8')

async function runTemplate({ outbound, proxies, templateOutbounds, countryUrltestTolerance }) {
  const context = {
    $arguments: {
      type: 'collection',
      name: 'test',
      outbound,
      countryUrltestTolerance,
      includeUnsupportedProxy: false,
    },
    $content: JSON.stringify({
      outbounds: templateOutbounds,
      endpoints: [],
    }),
    ProxyUtils: {},
    produceArtifact: async () => JSON.stringify({
      outbounds: proxies,
      endpoints: [],
    }),
    console: { log() {} },
  }

  const result = await vm.runInNewContext(
    `(async () => {\n${templateSource}\nreturn $content\n})()`,
    context,
  )
  return JSON.parse(result)
}

function selector(config, tag = 'Main') {
  return config.outbounds.find(outbound => outbound.tag === tag)
}

test('default rule adds nodes, country groups, and singleton countries in order', async () => {
  const config = await runTemplate({
    outbound: '📂Main',
    proxies: [
      { tag: '🇩🇪 Berlin' },
      { tag: '🇩🇪 Frankfurt' },
      { tag: '🇫🇮 Helsinki' },
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: ['manual'] },
    ],
  })

  const main = selector(config)
  assert.deepEqual(main.outbounds, [
    'manual',
    '🇩🇪 Germany',
    '🇩🇪 Berlin',
    '🇩🇪 Frankfurt',
    '🇫🇮 Helsinki',
  ])
  assert.deepEqual(
    config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').outbounds,
    ['🇩🇪 Berlin', '🇩🇪 Frankfurt'],
  )
})

test('country urltest interval grows by 20 seconds per additional node and is capped at 10 minutes', async () => {
  const config = await runTemplate({
    outbound: '📂Main',
    proxies: [
      { tag: '🇩🇪 Berlin' },
      { tag: '🇩🇪 Frankfurt' },
      { tag: '🇸🇪 Sweden 1' },
      { tag: '🇸🇪 Sweden 2' },
      { tag: '🇸🇪 Sweden 3' },
      { tag: '🇫🇮 Finland 1' },
      { tag: '🇫🇮 Finland 2' },
      { tag: '🇫🇮 Finland 3' },
      { tag: '🇫🇮 Finland 4' },
      ...Array.from({ length: 23 }, (_, index) => ({ tag: `🇨🇦 Canada ${index + 1}` })),
      ...Array.from({ length: 60 }, (_, index) => ({ tag: `🇳🇱 Netherlands ${index + 1}` })),
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').interval, '3m')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').tolerance, 75)
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').idle_timeout, '10m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇸🇪 Sweden').interval, '3m20s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇫🇮 Finland').interval, '3m40s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇨🇦 Canada').interval, '10m')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇳🇱 Netherlands').interval, '10m')
})

test('country urltest tolerance accepts numeric strings or numbers from 10 through 500', async () => {
  for (const countryUrltestTolerance of ['10', 500, '125', 250]) {
    const config = await runTemplate({
      outbound: '📂Main',
      countryUrltestTolerance,
      proxies: [
        { tag: '🇩🇪 Berlin' },
        { tag: '🇩🇪 Frankfurt' },
      ],
      templateOutbounds: [
        { tag: 'Main', type: 'selector', outbounds: [] },
      ],
    })

    assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').tolerance, Number(countryUrltestTolerance))
  }
})

test('invalid or out-of-range country urltest tolerance falls back to 75', async () => {
  for (const countryUrltestTolerance of ['9', 501, 'not-a-number', 10.5]) {
    const config = await runTemplate({
      outbound: '📂Main',
      countryUrltestTolerance,
      proxies: [
        { tag: '🇩🇪 Berlin' },
        { tag: '🇩🇪 Frankfurt' },
      ],
      templateOutbounds: [
        { tag: 'Main', type: 'selector', outbounds: [] },
      ],
    })

    assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').tolerance, 75)
  }
})

test('country and regex include/exclude alternatives filter only matching nodes', async () => {
  const config = await runTemplate({
    outbound: String.raw`📂Europe🔖de|nl🚫hetzner|test|0\.5x🌐🚫`,
    proxies: [
      { tag: '🇩🇪 Berlin' },
      { tag: '🇳🇱 Amsterdam' },
      { tag: '🇩🇪 Hetzner' },
      { tag: '🇳🇱 test' },
      { tag: '🇩🇪 0.5x' },
      { tag: '🇳🇱 0x5x' },
      { tag: '🇺🇸 Hetzner' },
    ],
    templateOutbounds: [
      { tag: 'Europe', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config, 'Europe').outbounds, [
    '🇩🇪 Berlin',
    '🇳🇱 Amsterdam',
    '🇳🇱 0x5x',
  ])
})

test('regex groups, character classes, anchors, and escaped pipes stay intact', async () => {
  const config = await runTemplate({
    outbound: String.raw`📂Regex🔖(?:game|premium)|v[1-3]|foo\|bar|edge[|]node|^server-(?:a|b)$🌐🚫`,
    proxies: [
      { tag: 'GAME-node' },
      { tag: 'premium-node' },
      { tag: 'v2-node' },
      { tag: 'v4-node' },
      { tag: 'foo|bar-node' },
      { tag: 'edge|node' },
      { tag: 'server-a' },
      { tag: 'server-b' },
      { tag: 'prefix-server-a' },
    ],
    templateOutbounds: [
      { tag: 'Regex', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config, 'Regex').outbounds, [
    'GAME-node',
    'premium-node',
    'v2-node',
    'foo|bar-node',
    'edge|node',
    'server-a',
    'server-b',
  ])
})

test('Cyrillic regex literals match regardless of letter case', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖москва|тест🌐🚫',
    proxies: [
      { tag: '🇷🇺 МОСКВА premium' },
      { tag: '🇷🇺 ТЕСТовый узел' },
      { tag: '🇷🇺 Сочи' },
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config).outbounds, [
    '🇷🇺 МОСКВА premium',
    '🇷🇺 ТЕСТовый узел',
  ])
})

test('exclusions without an include expression start from all nodes', async () => {
  const config = await runTemplate({
    outbound: '📂World🔖🚫ru|🇷🇺|moscow|мск🌐🚫',
    proxies: [
      { tag: '🇷🇺 Moscow' },
      { tag: '🇷🇺 Vladivostok' },
      { tag: '🇺🇸 moscow test' },
      { tag: '🇳🇱 мск' },
      { tag: '🇺🇸 New York' },
    ],
    templateOutbounds: [
      { tag: 'World', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config, 'World').outbounds, ['🇺🇸 New York'])
})

test('country tokens and ordinary regex can be mixed in 🔖', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖deu|Germany|🇳🇱|vless🌐🚫',
    proxies: [
      { tag: '🇩🇪 Berlin' },
      { tag: '🇳🇱 Amsterdam' },
      { tag: '🇺🇸 vless' },
      { tag: '🇫🇮 Helsinki' },
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config).outbounds, [
    '🇩🇪 Berlin',
    '🇳🇱 Amsterdam',
    '🇺🇸 vless',
  ])
})

test('one rule adds its matching nodes to every matching selector', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖vless🌐🚫',
    proxies: [
      { tag: '🇺🇸 vless' },
      { tag: '🇩🇪 other' },
    ],
    templateOutbounds: [
      { tag: 'Main A', type: 'selector', outbounds: [] },
      { tag: 'Main B', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config, 'Main A').outbounds, ['🇺🇸 vless'])
  assert.deepEqual(selector(config, 'Main B').outbounds, ['🇺🇸 vless'])
})

test('🔖🚫 disables ordinary node selection while 🌐 adds country groups and singletons', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖🚫🌐Germany|fi',
    proxies: [
      { tag: '🇩🇪 Berlin' },
      { tag: '🇩🇪 Frankfurt' },
      { tag: '🇫🇮 Helsinki' },
      { tag: '🇺🇸 New York' },
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config).outbounds, [
    '🇩🇪 Germany',
    '🇫🇮 Helsinki',
  ])
})

test('🌐🚫country excludes selected countries from otherwise allowed country items', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖🚫🌐🚫de|fi',
    proxies: [
      { tag: '🇩🇪 Berlin' },
      { tag: '🇫🇮 Helsinki' },
      { tag: '🇺🇸 New York' },
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config).outbounds, ['🇺🇸 New York'])
})

test('🌐 country groups are added to matching selectors, not urltest groups', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖🚫🌐🇩🇪',
    proxies: [
      { tag: '🇩🇪 Berlin' },
      { tag: '🇩🇪 Frankfurt' },
    ],
    templateOutbounds: [
      { tag: 'Main selector', type: 'selector', outbounds: [] },
      { tag: 'Main urltest', type: 'urltest', outbounds: [] },
    ],
  })

  const countryGroup = config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany')
  assert.ok(countryGroup)
  assert.deepEqual(selector(config, 'Main selector').outbounds, ['🇩🇪 Germany'])
  assert.ok(!selector(config, 'Main urltest').outbounds.includes('🇩🇪 Germany'))
})

test('disabling both filters keeps an otherwise empty selector non-empty', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖🚫🌐🚫',
    proxies: [{ tag: '🇩🇪 Berlin' }],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  const fallbackTag = selector(config).outbounds[0]
  assert.equal(config.outbounds.find(outbound => outbound.tag === fallbackTag).type, 'direct')
})
