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
  assert.deepEqual(
    config.outbounds
      .filter(outbound => outbound.type === 'urltest')
      .map(outbound => outbound.tag),
    ['🇩🇪 Germany'],
  )
})

test('country groups stay alphabetically ordered when a selector matches multiple rules', async () => {
  const config = await runTemplate({
    outbound: '📂Main🔖🚫🌐🇿🇼📂Main🔖🚫🌐🇦🇺',
    proxies: [
      { tag: '🇿🇼 Harare 1' },
      { tag: '🇿🇼 Harare 2' },
      { tag: '🇦🇺 Sydney 1' },
      { tag: '🇦🇺 Sydney 2' },
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  assert.deepEqual(selector(config).outbounds, ['🇦🇺 Australia', '🇿🇼 Zimbabwe'])
})

test('country urltest interval increases its per-node step every 10 nodes and is capped at 30 minutes', async () => {
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
      ...Array.from({ length: 10 }, (_, index) => ({ tag: `🇨🇦 Canada ${index + 1}` })),
      ...Array.from({ length: 20 }, (_, index) => ({ tag: `🇳🇱 Netherlands ${index + 1}` })),
      ...Array.from({ length: 30 }, (_, index) => ({ tag: `🇦🇺 Australia ${index + 1}` })),
      ...Array.from({ length: 40 }, (_, index) => ({ tag: `🇧🇷 Brazil ${index + 1}` })),
      ...Array.from({ length: 50 }, (_, index) => ({ tag: `🇯🇵 Japan ${index + 1}` })),
      ...Array.from({ length: 60 }, (_, index) => ({ tag: `🇰🇷 South Korea ${index + 1}` })),
      ...Array.from({ length: 120 }, (_, index) => ({ tag: `🇺🇸 USA ${index + 1}` })),
    ],
    templateOutbounds: [
      { tag: 'Main', type: 'selector', outbounds: [] },
    ],
  })

  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').interval, '3m')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').tolerance, 75)
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇩🇪 Germany').idle_timeout, '3m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇸🇪 Sweden').interval, '3m3s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇸🇪 Sweden').idle_timeout, '4m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇫🇮 Finland').interval, '3m6s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇫🇮 Finland').idle_timeout, '4m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇨🇦 Canada').interval, '3m24s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇨🇦 Canada').idle_timeout, '4m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇳🇱 Netherlands').interval, '4m24s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇳🇱 Netherlands').idle_timeout, '5m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇦🇺 Australia').interval, '5m54s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇦🇺 Australia').idle_timeout, '6m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇧🇷 Brazil').interval, '7m54s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇧🇷 Brazil').idle_timeout, '8m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇯🇵 Japan').interval, '10m24s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇯🇵 Japan').idle_timeout, '11m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇰🇷 South Korea').interval, '13m24s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇰🇷 South Korea').idle_timeout, '14m0s')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇺🇸 United States').interval, '30m')
  assert.equal(config.outbounds.find(outbound => outbound.tag === '🇺🇸 United States').idle_timeout, '30m0s')
  assert.deepEqual(
    config.outbounds
      .filter(outbound => outbound.type === 'urltest')
      .map(outbound => outbound.tag),
    [
      '🇦🇺 Australia',
      '🇧🇷 Brazil',
      '🇨🇦 Canada',
      '🇫🇮 Finland',
      '🇩🇪 Germany',
      '🇯🇵 Japan',
      '🇳🇱 Netherlands',
      '🇰🇷 South Korea',
      '🇸🇪 Sweden',
      '🇺🇸 United States',
    ],
  )
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
