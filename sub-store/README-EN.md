# Script Usage Guide

🇺🇸 **English** | [🇷🇺 На русском](./README.md)

## What the Script Does

The script distributes nodes from a subscription into groups within a sing-box configuration template according to the rules defined in the `outbound` parameter. It outputs a complete, ready-to-use sing-box configuration for SKeen clients as well as for any official sing-box GUI clients.

### Terminology

- **Node** — an incoming proxy node (`outbounds` or `endpoints`) from a subscription.
- **Group** — an object of type `selector` or `urltest` defined in the sing-box template.
- **Tag** — the value of the `tag` field of a node or group; used by the script for searching and filtering.
- **Country Group** — a dynamically created `urltest` group for nodes belonging to the same country.

## Sub-Store Installation

Choose one or more of the following options:

- [Sub-Store Docker](https://github.com/jinndi/Sub-Store-Docker) — Docker build for VPS / local deployment.
- [Sub-Store Desktop](https://github.com/jinndi/sub-store-gui) — Desktop version for subscription management.
- [Sub-Store Android](https://github.com/sionnx/SubCase) — Android app for mobile management.
- [Chinese VPS Guide](https://wiki.repcz.link/substore/install/) — VPS installation guide in Chinese.

Installing on a VPS via Docker is preferred. For this setup, access must be secured over HTTPS and a reverse proxy configuration is required. For more detailed information, see the links above.

Authentication is configured using the parameter specified in the `SUB_STORE_FRONTEND_BACKEND_PATH` environment variable.

## Adding Your First Subscription

After successfully logging into Sub-Store, add a subscription:

1. Go to the **Subscriptions** section and add one or more subscriptions.
2. Fill in at least the mandatory fields:
   - **Name (ID)**
   - **Source** (you can specify a URL, paste links locally into the input field, or both — in which case select either **Local First** or **Remote First** under **Merge Sources**).
3. If the subscription requires a `hwid`, retrieve the parameter for the URL via the `skeen headers` command.
4. Click **Save** at the bottom.

If you have multiple subscriptions, repeat the process for each. Afterward, create a subscription of type **Collection**: specify a **Name (ID)**, select the previously added subscriptions under **Select Included Subscriptions**, and click **Save**.

## Connecting the Template and Processing Script

To get a complete sing-box configuration, follow these steps:

1. Go to the **Files** section and click the add button (or the plus icon at the top).
2. Fill in the fields:
   - **Name (ID)**
   - **Source** — choose **Remote** or **Local**.

If you choose **Remote**, paste a link to a sing-box template. The following options are available in the `templates` folder:

- Base template for SKeen:

```text
https://raw.githubusercontent.com/jinndi/SKeen/main/sub-store/templates/skeen.json
```

- Lightweight template for SKeen (for mipsel routers and low-performance devices):

```text
https://raw.githubusercontent.com/jinndi/SKeen/main/sub-store/templates/skeen_lite.json
```

- Template for the official sing-box Android app (SFA):

```text
https://raw.githubusercontent.com/jinndi/SKeen/main/sub-store/templates/android.json
```

- Template for the official sing-box Linux app (SFL):

```text
https://raw.githubusercontent.com/jinndi/SKeen/main/sub-store/templates/linux.json
```

- Template for the official sing-box Windows app (SFW):

```text
https://raw.githubusercontent.com/jinndi/SKeen/main/sub-store/templates/windows.json
```

If you want to create a custom template, use these as a base. Content can be pasted locally and edited directly in the interface.

3. In the actions block, add a **Script Modifier (JS)**. Choose **Remote Link** or **Local Script**. Paste the link to the pre-made script:

```text
https://raw.githubusercontent.com/jinndi/SKeen/main/sub-store/template.js#name=YourSubscriptionNameId&type=Subscription&outbound=📂Proxy🔖🚫ru🌐🚫ru📂Runet🔖🇷🇺🌐ru📂Torrent🔖torrent|торрент|✅🌐ru📂Games🔖hysteria|hy2|tuic|🎮|🇷🇺|est|fin|lv🌐🚫📂AI🔖🚫🌐🚫ru📂Auto🔖🚫ru🌐🚫
```

4. Save changes.
5. Go to the **Share** tab and add a new entry: select your created file as the source, configure the expiration time / usage limit of the link, save, and copy the final link for your applications.

Next, review the parameter breakdown for the script URL and how to work with them.

## Script Parameters (`$arguments`)

| Parameter | Description |
|---|---|
| `outbound` | **Required.** Rule string for distributing nodes across groups; see details below. |
| `name` | Optional. Name of the Sub-Store subscription or collection to pull nodes from. |
| `url` | Optional. Subscription URL. It must be encoded using `encodeURIComponent`. For example, `http://a.com?token=123` is passed as `url=http%3A%2F%2Fa.com%3Ftoken%3D123`. |
| `fileName` | Optional. Name of a file from which to include nodes from the `outbounds` and `endpoints` keys of the sing-box object. |
| `type` | Optional. Subscription type (when `name` is specified). For collections, specify `type=col`, `type=кол`, or `type=1`. This parameter is not needed for a single subscription. |
| `includeUnsupportedProxy` | Optional. Enables protocols that are usually unsupported (e.g., SSR, Snell). Example: `&includeUnsupportedProxy=true`. |
| `countryUrltestTolerance` | Optional. Value for the [`tolerance`](https://sing-box.sagernet.org/configuration/outbound/urltest/#tolerance) parameter of country `urltest` groups, in milliseconds. Accepts an integer or an integer string from `10` to `500`; if omitted, invalid, or out of range, defaults to `75`. For example, `&countryUrltestTolerance=100`. |

> ⚠️ `name`, `url`, and `fileName` are each optional, but at least one of them must be specified so the script has something to process.

## `outbound` Rules

The parameter consists of one or more rules. Each rule starts with `📂`:

```text
📂<group_name>[🔖<node_tags>][🌐<countries>]
```

Markers control different aspects:

- `📂` defines a regular expression for the group name in the sing-box template.
- `🔖` filters incoming node tags: standard regex options, standalone flags, English country names, and ISO codes enable country recognition.
- `🌐` selects countries via a list (not regex). Country groups and single country nodes are added only to matching `selector` groups, not `urltest`.

The `🔖` and `🌐` filters are independent: `🔖` selects standard incoming nodes, while `🌐` separately allows country groups and single country nodes.

| Marker | If omitted | If filter specified | Explicitly disable |
|---|---|---|---|
| `🔖` | All nodes added | Filtered by tag regex or country recognition | `🔖🚫` |
| `🌐` | All discovered country groups & single country nodes allowed | Selects countries from list | `🌐🚫` |

`🔖🚫` disables standard node selection only: `🌐` can still add country elements. Conversely, `🌐🚫` disables country elements only, without affecting node selection via `🔖`.

List countries after `🌐` separated by `|` or commas. For each country, you can use a flag, English name, or [ISO 3166-1 alpha-2/alpha-3 code](https://en.wikipedia.org/wiki/ISO_3166-1):

```text
🌐🇩🇪|🇫🇮
🌐Germany|Finland
🌐de|fi
🌐deu,fin
```

Country names and codes after `🌐` must match exact full names/codes; this is not a regular expression. Comma list separators are supported only after `🌐`.

In `🔖`, a standalone top-level alternative consisting entirely of a flag, English country name, or ISO alpha-2/alpha-3 code uses country recognition. For example, `Germany` matches German nodes using the country pattern, even if the tag contains a flag, code, or city name. Case-insensitive matching applies. Other alternatives remain standard regex; `|` inside parentheses, e.g. `(game|premium)`, stays part of the regex group. The same rule applies after `🚫`. For the United Kingdom, use ISO codes `gb` or `gbr` (`uk` is not an ISO alpha-2/alpha-3 code and is treated as standard regex in `🔖`).

### Pattern Sources and When to Use Regex

| Input | Matching Method | When to Use |
|---|---|---|
| Standalone flag, English country name, or ISO code in `🔖` | Country pattern from array of [`COUNTRY_RULES` in `template.js`](template.js#L4): flags, codes, literal aliases from `patternAliases`, and special variants from `patternExtras`/`patternCodePatterns`. Aliases usually include country names in English and Russian, as well as capital and city names if included in the rule. | Default choice for standard country tags. E.g., `🔖de` finds German nodes with a flag, name, code, or known city in the tag. |
| Other text or regex in `🔖` | Regex evaluation against node tag. Unknown codes and localized names remain standard regex rather than special country keys. | For custom provider tags, non-standard abbreviations, or custom formats. |
| List after `🌐` | Exact match against recognized countries by flag, name, alias, or ISO code (not tag regex search). | To allow or exclude country groups and single country nodes. |

For most standard subscriptions, country recognition covers ~90% of cases. This is a practical estimate rather than a strict coverage measurement; the outcome depends on how a specific subscription formats its tags. Regex is also needed when searching or excluding non-country tag components such as provider, protocol, or plan (`vless`, `hetzner`, `premium`). For country searches, switch to regex only if the subscription tags use non-standard designations that are not included in the pattern for that country.

ISO codes and names can be cross-referenced with the [ISO 3166-1 code table on Wikipedia](https://en.wikipedia.org/wiki/ISO_3166-1). Check the columns **"Country name"**, **"Alpha-2 code"**, and **"Alpha-3 code"**.

The flag in the first column can be used as a reference; its two-letter code is shown in the **Alpha-2** column. For example, for Germany you can specify any single variant: flag `🇩🇪`, name `Germany`, alpha-2 code `de`, or alpha-3 code `deu` — you do not need to list them all.

### Examples: From Simple to Advanced

**1. Default: All nodes and all country elements**

```text
📂Main
```

Without `🔖`, all standard nodes are added; without `🌐`, all discovered countries are allowed. For countries with 2+ nodes, a `urltest` group is added; for a single unambiguously recognized node, the node itself is added.

**2. Only regex-selected nodes**

```text
📂Main🔖game🌐🚫
```

Adds nodes containing `game` in their tags. `🌐🚫` disables country groups and single country nodes.

Regex alternatives or groups can be used:

```text
📂Main🔖game|premium🌐🚫
📂Main🔖(game|premium)🌐🚫
```

Both select `game` or `premium` as regex. Parentheses preserve `|` inside the regex group.

**3. Country elements only, no standard node selection**

```text
📂Countries🔖🚫🌐🇩🇪|🇫🇮
```

Adds a group for Germany and Finland if 2+ nodes exist, or the single unambiguously recognized node. `🔖🚫` does not disable single country nodes allowed by `🌐`.

**4. Country search via `🔖`**

```text
📂Main🔖Germany|vless🌐🚫
```

`Germany` matches nodes using the German country pattern even if codes, flags, or cities are used in the tag; `vless` remains standard regex. Equivalent standalone country options are `Germany`, `🇩🇪`, `de`, and `deu`. `🌐🚫` prevents adding country groups on top of nodes.

**5. Independent combination of nodes and countries**

```text
📂Main🔖game🌐🇩🇪|🇫🇮
```

Adds nodes matching `game` and Germany/Finland country elements regardless of whether their tags contain `game`. If a node matches both conditions, it is not duplicated when adding a single country element; if 2+ nodes exist, the country is added as a group.

**6. Mixed country and regex conditions with exclusions**

```text
📂Europe🔖de|nl🚫hetzner|test|0\.5x🌐🚫
```

`de` and `nl` select nodes matching Germany and Netherlands patterns, then exclude nodes containing `hetzner`, `test`, or `0\.5x` in the tag. Exclusions do not add nodes from other countries. These are standard regex exclusions; `0\.5x` matches a literal dot. Country elements are disabled via `🌐🚫`.

**7. Country and regex exclusions**

```text
📂World🔖🚫ru|🇷🇺|moscow|мск🌐🚫
```

Adds all nodes except those recognized as Russian or containing `moscow` or `мск` in their tags. `ru` and `🇷🇺` use country recognition; `moscow` and `мск` remain regex. A positive `.*` pattern is not needed here: if there is no inclusion expression before `🚫`, all nodes match. Country elements are disabled.

**8. Including and excluding countries via `🌐`**

```text
📂Countries🔖🚫🌐de,fi
📂Other🔖🚫🌐🚫de|fi
```

The first rule adds only Germany and Finland country elements; the second adds all discovered countries except them. The list in `🌐` accepts `|` or commas, matching exact full names and codes.

**9. Disabling both addition types**

```text
📂Empty🔖🚫🌐🚫
```

Adds neither standard nodes nor country elements. If a `selector` group remains empty, the script inserts `🔌 DIRECT` (`direct`) so the group is not left empty.

### Multiple Rules in One Parameter

Rules can be chained together; each starts with `📂`. In the Sub-Store editor, they can be written across multiple lines. Paste only the value without `outbound=`:

```text
📂Manual🔖🚫🇷🇺|мос|мск|msk|санкт|spb🌐🇩🇪|🇳🇱
📂Runet🔖ru|🇷🇺|рос|мос|мск|msk|санкт|spb🌐🚫🇷🇺|🇹🇷
📂Torrent🔖torrent|торрент|✅🌐ru
📂Games🔖hys|hy2|tuic|🎮|🇷🇺🌐🚫
📂AI
```

`Manual` receives all standard nodes except Russian ones and enables DE/NL country elements. `Runet` selects Russian nodes but excludes RU/TR country elements. `Torrent` and `Games` filter standard nodes only. `AI` without filters receives all nodes and all discovered country elements.

If generating the URL manually, the `outbound` value must be encoded as a URL parameter.

### Breakdown of Proposed Templates

Single-line parameter entry:

```text
outbound=📂Proxy🔖🚫ru🌐🚫ru📂Runet🔖🇷🇺🌐ru📂Torrent🔖torrent|торрент|✅🌐ru📂Games🔖hysteria|hy2|tuic|🎮|🇷🇺|est|fin|lv🌐🚫📂AI🔖🚫🌐🚫ru📂Auto🔖🚫ru🌐🚫
```

Multi-line format for the Sub-Store editor (without the `outbound=` prefix):

```text
📂Proxy🔖🚫ru🌐🚫ru
📂Runet🔖🇷🇺🌐ru
📂Torrent🔖torrent|торрент|✅🌐ru
📂Games🔖hysteria|hy2|tuic|🎮|🇷🇺|est|fin|lv🌐🚫
📂AI🔖🚫🌐🚫ru
📂Auto🔖🚫ru🌐🚫
```

- `Proxy` adds all non-Russian nodes and all non-Russian country elements.
- `Runet` selects Russian nodes and allows Russian country elements.
- `Torrent` selects nodes matching `torrent`, `торрент`, or `✅`; separately allows Russian country elements.
- `Games` selects nodes matching regex `hysteria`, `hy2`, `tuic`, `🎮`, or country patterns for Russia (`🇷🇺`), Estonia (`est`), Finland (`fin`), and Latvia (`lv`). `🌐🚫` disables country group/node additions.
- `AI` disables standard node selection and allows country elements for all countries except Russia.
- `Auto` adds all non-Russian nodes without country elements.

## Country Group Creation

- The catalog contains all 249 ISO 3166-1 entries from the Wikipedia list. Each country includes a flag, ISO alpha-2 code, ISO alpha-3 code, and a pattern for matching node tags.
- A country `urltest` group is created when **two or more nodes** are found for a country allowed by the `outbound` rule. If exactly one node matches unambiguously to a single country, it is added directly to matching `selector` groups as a standard node without creating a country group. If the tag of that node matches patterns for multiple countries, the script does not assign it as a single node to any of them.
- The `urltest` check interval scales with the number of nodes: **3 minutes for two nodes**; nodes 3–10 add **3 seconds each**, and the step increases by **3 seconds** for each subsequent group of ten nodes. The interval is capped at **30 minutes**. `idle_timeout` equals the interval rounded up to a whole minute and uses the `Nm0s` format.

| Nodes | `interval` | `idle_timeout` |
|---:|---:|---:|
| 2 | 3m | 3m0s |
| 10 | 3m24s | 4m0s |
| 20 | 4m24s | 5m0s |
| 30 | 5m54s | 6m0s |
| 40 | 7m54s | 8m0s |
| 50 | 10m24s | 11m0s |
| 60 | 13m24s | 14m0s |
| 70 | 16m54s | 17m0s |
| 80 | 20m54s | 21m0s |
| 90 | 25m24s | 26m0s |
| 100+ | 30m | 30m0s |
- Nodes are recognized by flags, codes, and names. For some countries, common name variations and city names are also included in the patterns.
- In the [`COUNTRY_RULES` array in `template.js`](template.js#L4), literal aliases for country and city names are stored in `patternAliases` in lowercase separated by `|`. Add exact standalone variants (including common abbreviations) rather than truncated stems or demonyms, and avoid duplicating an alias across rules for different countries. When building the catalog, the script escapes aliases as plain text, adds a general Unicode word boundary, and sets the case-insensitive flag; word boundaries do not need to be repeated in each alias. Custom regular expressions for exclusions and codes are specified separately in `patternExtras` and `patternCodePatterns`.
- The country group tag format uses the flag and English country name, e.g., `🇩🇪 Germany`.
- For country groups or single nodes to be added by country, at least one `outbound` rule must allow that country. Without `🌐`, the rule allows all countries; `🌐🚫` disables all. The `🌐` filter determines which eligible `selector` groups receive the country group or single country node, operating independently of the node filter `🔖`.

## Node Order and Tag Uniqueness

- The order in a `selector` group is: elements defined in the template; country `urltest` groups sorted alphabetically by English country name; matching nodes from the `fileName` file (`outbounds` first, then `endpoints`); matching nodes from the subscription (`name` or `url`, `endpoints` first, then `outbounds`); then unique single country nodes not already present. Original order is preserved within each source.
- For example, given an empty group and the rule `📂Main🔖game🌐🇩🇪|🇫🇮`, the resulting list will be:

  ```text
  ["🇫🇮 Finland", "🇩🇪 Germany", "game-node-1", "game-node-2"]
  ```

- If the template already contained elements `["template-outbound-1", "template-outbound-2"]`, and `game-node-1` comes from `fileName`, the final order will be:

  ```text
  ["template-outbound-1", "template-outbound-2", "🇫🇮 Finland", "🇩🇪 Germany", "game-node-1", "game-node-2"]
  ```

- Group tags defined in the template are not modified. Incoming node tags and dynamically created country group tags are checked for collisions against each other and existing template tags. Upon collision, a numeric suffix is appended with a hyphen: `🇩🇪 Germany-1`, `🇩🇪 Germany-2`, and so on.
- If an incoming node tag is renamed, the script also updates references to it in the `detour` and `outbounds` fields of other incoming nodes.

## Key Notes

- Country groups are not defined in the template; they are created by the script.
- `selector` and `urltest` groups defined in the template are never deleted. If a group remains empty or has no matching `outbound` rule, `🔌 DIRECT` (`direct`) is inserted into it so it does not remain empty.

## Testing `outbound` Logic

Run the test suite from the repository root:

```sh
node --test sub-store/template.test.mjs
```

Tests run the template on mock data to verify default filters, mixing country and regex conditions, case-insensitive Cyrillic regex, groups, character classes, anchors, escaped `|`, exclusions, single nodes and country groups, `🔖🚫`/`🌐🚫`, adding country groups to `selector` only, and element ordering.

## Benchmarks

Run the benchmark from the repository root:

```sh
node sub-store/template.bench.mjs
```

The benchmark measures full template execution using mock subscriptions with 100, 500, and 1500 nodes across various `selector` configuration sizes. A dedicated scenario with 500 nodes and 10 groups compares simple `vless` matching against complex regex (groups, character classes, escaped `|`, anchors, and exclusions). Both variants select the same set of nodes. Benchmarking includes template initialization and country matching, excluding network fetch time. To run multiple measurement rounds, pass the environment variable, e.g., `BENCH_ROUNDS=10 node sub-store/template.bench.mjs`. Compare results on the same hardware and Node.js version.

Sample results (**10 rounds after a warmup run**) on Node.js `v24.20.0`:

| Scenario | Nodes | `selector` Groups | Median | Min |
|---|---:|---:|---:|---:|
| Small | 100 | 1 | 32.4 ms | 29.8 ms |
| Typical | 500 | 10 | 103.6 ms | 101.4 ms |
| Large | 1500 | 30 | 280.1 ms | 276.7 ms |
| Complex Regex | 500 | 10 | 102.6 ms | 100.3 ms |

These values are indicative; performance depends on the machine and Node.js runtime environment.

## Additional Resources

Refer to the [examples/sub-store](../examples/sub-store/) folder.
