# Changelog

## [5.1.5](https://github.com/jinndi/SKeen/compare/SKeen-v5.1.4...SKeen-v5.1.5) (2026-08-14)


### ⚡ Perf

* **firewall:** remove use_conntrack option (always apply TCP connection) and simplify rules ([3676843](https://github.com/jinndi/SKeen/commit/36768434c6a4d87d10e4b88ea640244fb54930a9))

## [5.1.4](https://github.com/jinndi/SKeen/compare/SKeen-v5.1.3...SKeen-v5.1.4) (2026-08-13)


### 🐛 Fix

* **iptables:** correct mark matching and chain variable references ([1eccc15](https://github.com/jinndi/SKeen/commit/1eccc15ed38d8e160a60476e12c296ebc93608c2))


### 🛠 Refactor

* **script:** replace get_curl_proxy_options with run_curl wrapper ([d105729](https://github.com/jinndi/SKeen/commit/d105729a8bf8dcade670e7d5e9b0d8f98b88645c))

## [5.1.3](https://github.com/jinndi/SKeen/compare/SKeen-v5.1.2...SKeen-v5.1.3) (2026-08-13)


### 🎨 Style

* **cli:** update help text and command descriptions ([ac322ac](https://github.com/jinndi/SKeen/commit/ac322ac571bbffdef74f8db7787fcc2c3315bfbc))
* **menu:** extract add_line helper for menu display formatting ([7f6d439](https://github.com/jinndi/SKeen/commit/7f6d4391aaa7e55614bdd3a14105fbae5afa6db7))
* **scripts:** consolidate local variable declarations and add default parameter syntax ([cca36e9](https://github.com/jinndi/SKeen/commit/cca36e9006033f001d7854a79949beaae7b5526e))


### 🛠 Refactor

* extract service management into check_should_run function ([5a833e1](https://github.com/jinndi/SKeen/commit/5a833e1842e1fb626cbdbaca03d928143212d817))

## [5.1.2](https://github.com/jinndi/SKeen/compare/SKeen-v5.1.1...SKeen-v5.1.2) (2026-08-12)


### 🐛 Fix

* **routing:** correct routing table IDs and improve error handling ([322d347](https://github.com/jinndi/SKeen/commit/322d347ddcb26b8dc95d40f3f5706103c955b771))


### 🛠 Refactor

* **iptables:** simplify connection marking logic ([ca4dee6](https://github.com/jinndi/SKeen/commit/ca4dee659e0c074164a345b65536b428b6b7088b))

## [5.1.1](https://github.com/jinndi/SKeen/compare/SKeen-v5.1.0...SKeen-v5.1.1) (2026-08-11)


### 🛠 Refactor

* improve architecture detection logic ([cb83749](https://github.com/jinndi/SKeen/commit/cb83749f7160764ea180ef5873f897c2eb4677f6))

## [5.1.0](https://github.com/jinndi/SKeen/compare/SKeen-v5.0.4...SKeen-v5.1.0) (2026-08-11)


### 🚀 Feat

* **firewall:** remove intercept.port configuration option ([c473b67](https://github.com/jinndi/SKeen/commit/c473b67616bb24dc29d9645a81a17c96ba4e5f4e))

## [5.0.4](https://github.com/jinndi/SKeen/compare/SKeen-v5.0.3...SKeen-v5.0.4) (2026-08-05)


### 🧰 Chore

* **config:** Remove resolve timeout from DNS routing rule and add template-s-ui.json ([63e3559](https://github.com/jinndi/SKeen/commit/63e3559af9c521b87512d3991b1fb4e9a3fdd8dc))

## [5.0.3](https://github.com/jinndi/SKeen/compare/SKeen-v5.0.2...SKeen-v5.0.3) (2026-08-01)


### 🛠 Refactor

* **config:** simplify DNS rules v1.13 and configuration in example configs ([561bb30](https://github.com/jinndi/SKeen/commit/561bb30b89f407323ddac1c633e43a7c7a9713ec))


### 🧰 Chore

* **shell:** bump SKeen version to 5.0.3 and streamline config sync logic ([ec12e82](https://github.com/jinndi/SKeen/commit/ec12e82b8a19a62750d2beaca46cedab78e58ec6))

## [5.0.2](https://github.com/jinndi/SKeen/compare/SKeen-v5.0.1...SKeen-v5.0.2) (2026-07-24)


### 🐛 Fix

* unquote URL variables in curl download commands ([b77b75a](https://github.com/jinndi/SKeen/commit/b77b75adb9537f5d522b6d7b3d5edd3f9aa9bdc0))

## [5.0.1](https://github.com/jinndi/SKeen/compare/SKeen-v5.0.0...SKeen-v5.0.1) (2026-07-24)


### 🐛 Fix

* **install:** add curl resolve workaround for GitHub release assets ([d0ee10f](https://github.com/jinndi/SKeen/commit/d0ee10f8777e6809b6e8a76c1e50db88a4ef3c21))
* **install:** use GitHub releases Atom feed for beta version detection ([a1dc67c](https://github.com/jinndi/SKeen/commit/a1dc67cf31315b73c5a6052778f7b87c1b6809ce))
* **uninstall:** prompt before removing sing-box binary during uninstall ([b11dd6c](https://github.com/jinndi/SKeen/commit/b11dd6c429bc89820ac63ae1dd88acbef5d42003))


### 🛠 Refactor

* **cli:** consolidate update commands into configuration-based workflow ([99c058c](https://github.com/jinndi/SKeen/commit/99c058cba3fe5a31c463e1cb47b030d7b4d80ca2))


### 🧰 Chore

* **config:** change default log level from debug to trace ([15c9acb](https://github.com/jinndi/SKeen/commit/15c9acbee106bcac65959c6282d1756d57becfa3))
* **readme:** document update configuration options ([5e8d1e0](https://github.com/jinndi/SKeen/commit/5e8d1e0c3952938fd4af246743d13333329066d7))

## [5.0.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.20.2...SKeen-v5.0.0) (2026-07-23)


### ⚠ BREAKING CHANGES

* **config:** Existing configuration files must be updated to use 'enabled' instead of 'enable' for all boolean flags.
* **firewall:** Existing configurations using policy.name are no longer supported. The policy.enable default changed from 1 to 0.

### 🚀 Feat

* **firewall:** replace policy-based routing with segment-based routing ([95ba0b7](https://github.com/jinndi/SKeen/commit/95ba0b7b5d6352fc56d0fcbef50086c262f7863b))


### 🛠 Refactor

* **config:** rename enable fields to enabled ([a6ce7ae](https://github.com/jinndi/SKeen/commit/a6ce7ae7794f119f8ed659fbf20df4527b09a399))
* **firewall:** replace rci ip/http call with iptables parsing for keendns port ([53287ea](https://github.com/jinndi/SKeen/commit/53287eae260eec9c2db6f5beb53f1afef77d5eb0))
* **firewall:** validate segment name format for policy routing ([46099be](https://github.com/jinndi/SKeen/commit/46099be7196e8010fa7d98e73d77715d5645ae76))
* **modules:** simplify xt_owner module loading logic ([ff8e407](https://github.com/jinndi/SKeen/commit/ff8e40777e865d444b6005e3b365e13f0caace61))
* **tun:** replace rci http calls with ndmc commands ([d952bc8](https://github.com/jinndi/SKeen/commit/d952bc87c6fb728caecd7fa0085a1bee667f1fb5))


### 🧰 Chore

* **docs:** update configuration examples and routing documentation ([cc37801](https://github.com/jinndi/SKeen/commit/cc378017c06d89943af3c43bad1a8baec64bfec8))

## [4.20.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.20.1...SKeen-v4.20.2) (2026-07-12)


### 🐛 Fix

* check xt_owner module existence for firmware &lt; 5 ([46bd38d](https://github.com/jinndi/SKeen/commit/46bd38d2d9106fe6c89092686759dbbd603d1926))
* **tun:** fixed firmware version check for executing skeen tun &lt;cmd&gt; commands ([292a24b](https://github.com/jinndi/SKeen/commit/292a24bf3e896c450f76b4a01265d0a1f51f9cc0))

## [4.20.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.20.0...SKeen-v4.20.1) (2026-07-10)


### ⚡ Perf

* refactor fakeip firewall list processing into a single awk pass ([f88efb2](https://github.com/jinndi/SKeen/commit/f88efb2ec628c41185189ffd9f69454f708e158e))


### 🧰 Chore

* **config:** update sing-box configuration template ([826c121](https://github.com/jinndi/SKeen/commit/826c1217047b424bb18e21cbc3754b032c0a12c9))

## [4.20.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.19.0...SKeen-v4.20.0) (2026-07-08)


### 🚀 Feat

* add source client filtering for FakeIP interception ([02f0c17](https://github.com/jinndi/SKeen/commit/02f0c17f134ab2d32b9807b05d3ccf9db7cbc82b))


### ⚡ Perf

* optimize fakeip client list processing with awk ([be44269](https://github.com/jinndi/SKeen/commit/be44269a9c6d7755de6a8a2313d733d7118a7e00))

## [4.19.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.18.0...SKeen-v4.19.0) (2026-07-07)


### 🚀 Feat

* **firewall:** add fakeip interception support ([cad2457](https://github.com/jinndi/SKeen/commit/cad245710d0022cb98ddd291d0d4dbeaac4bfb65))

## [4.18.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.17.2...SKeen-v4.18.0) (2026-07-03)


### 🚀 Feat

* **config:** move script to RAM for firewall hooks ([76c77e3](https://github.com/jinndi/SKeen/commit/76c77e3be2026ee73c3cc455c84bb82729aa31cf))
* **config:** move SKeen config to RAM and sync on startup/change ([9f17984](https://github.com/jinndi/SKeen/commit/9f1798411de89c3f7fd59fbe6fcc79e0b4a3e35c))


### 🐛 Fix

* skeen check command termination logic ([7afccf0](https://github.com/jinndi/SKeen/commit/7afccf0c309f13f8b9c18832e9cfd39d9c8578ce))


### 🧰 Chore

* remove port 123 from default exclusion list ([178410e](https://github.com/jinndi/SKeen/commit/178410ee23510ba97ba23246bff450f3b86741ee))

## [4.17.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.17.1...SKeen-v4.17.2) (2026-06-22)


### 🐛 Fix

* **en:** ensure port 443 is intercepted in firewall setup ([2a0e1bb](https://github.com/jinndi/SKeen/commit/2a0e1bb051dd4f5e51675314ac417bf5b45a4a3e))
* ensure port 443 is intercepted in firewall setup ([5ff0013](https://github.com/jinndi/SKeen/commit/5ff0013940f660d7de22e55d6cb7c0ff41c6251a))


### 🧰 Chore

* **config:** enable netfilter conntrack by default ([62505e8](https://github.com/jinndi/SKeen/commit/62505e8f897b275398ca29db0faf951ae89ee20b))

## [4.17.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.17.0...SKeen-v4.17.1) (2026-06-11)


### 🧰 Chore

* **dns:** add local DNS server and rules for KeenDNS access ([c1a78d7](https://github.com/jinndi/SKeen/commit/c1a78d72ffce15dd3fe68576cfa0f778b06974b2))

## [4.17.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.16.5...SKeen-v4.17.0) (2026-06-02)


### 🚀 Feat

* **core:** add beta command to install pre-release sing-box versions ([73d9975](https://github.com/jinndi/SKeen/commit/73d99752bc0a319af794ab6923a099a29eb35c49))

## [4.16.5](https://github.com/jinndi/SKeen/compare/SKeen-v4.16.4...SKeen-v4.16.5) (2026-05-24)


### 🐛 Fix

* **sync:** validate sync_url and address format in sync command ([4ae362e](https://github.com/jinndi/SKeen/commit/4ae362e5a9f940bea70872c6b1bf2db9c6fc3a82))

## [4.16.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.16.3...SKeen-v4.16.4) (2026-05-18)


### 🐛 Fix

* **iptables:** Fix iptables sub-chains reset when `use_conntrack` is enabled + update iptables chain handling to use -w flag and new helper functions ([bcec90e](https://github.com/jinndi/SKeen/commit/bcec90ea6f530f6f9b7deb19afaeda3706f776d3))

## [4.16.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.16.2...SKeen-v4.16.3) (2026-05-18)


### 🐛 Fix

* update iptables commands for chain existence checks ([ea0582d](https://github.com/jinndi/SKeen/commit/ea0582d84d5b8cb78255befbbcfd7b74eda67296))

## [4.16.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.16.1...SKeen-v4.16.2) (2026-05-17)


### 🐛 Fix

* enhance DNS interception condition in add_skeen_rules ([0238ef3](https://github.com/jinndi/SKeen/commit/0238ef38a2ff7b37eaf01463a7beea9acf27003d))
* update SKeen version to 4.16.2 and adjust rule addition in add_skeen_rules ([8f998ba](https://github.com/jinndi/SKeen/commit/8f998bad5260ad6ac1cbfde9b207c65aacb6f7ac))

## [4.16.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.16.0...SKeen-v4.16.1) (2026-05-17)


### 🐛 Fix

* always apply DNS_PRE chain in add_skeen_rules + reduce clean_chain duplication & tighten fw tests ([2e94edf](https://github.com/jinndi/SKeen/commit/2e94edf6a6ede404cecb038e869356afe10df7c6))

## [4.16.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.15.0...SKeen-v4.16.0) (2026-05-17)


### 🚀 Feat

* **core:** refactor add_skeen_rules() to use sub-chains with connmark enable ([d67fc17](https://github.com/jinndi/SKeen/commit/d67fc1796aa4464434818aa77621e38729a92840))


### 🧰 Chore

* cleanup chains & fw test patterns ([c4cbe7c](https://github.com/jinndi/SKeen/commit/c4cbe7c07c89583e6edb37c968553cd116076825))

## [4.15.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.14.0...SKeen-v4.15.0) (2026-05-15)


### 🚀 Feat

* **core:** add configurable sing-box binary and refactor config loading ([13ce21f](https://github.com/jinndi/SKeen/commit/13ce21f325885ed883bafb8b318b2ca8084eba02))


### 🧰 Chore

* **examples:** update sing-box configs and generated templates ([786b630](https://github.com/jinndi/SKeen/commit/786b630ad9d4e4a0a43139864be51aae0f09f643))

## [4.14.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.13.0...SKeen-v4.14.0) (2026-05-13)


### 🚀 Feat

* **firewall:** add configurable conntrack marking feature ([61e078f](https://github.com/jinndi/SKeen/commit/61e078f580de3c2d9f3698a9036d517ca4a654f4))
* migrate from ndmc to full RCI API for router communication (refactor `tun` commans + Available via Web CLI) ([92b3c38](https://github.com/jinndi/SKeen/commit/92b3c38b868661a36218f652036f7fce8241f2eb))
* **tproxy:** add socket-based traffic diversion with dedicated chain ([e8aa094](https://github.com/jinndi/SKeen/commit/e8aa094611103692586882afca989acf81ce43d8))


### 🛠 Refactor

* **scripts:** make configuration variables readonly for immutability ([3455ff9](https://github.com/jinndi/SKeen/commit/3455ff9089e6b45331d0a6bcfe31cf96cc1a0705))


### ⚡ Perf

* **firewall:** optimize with directional filtering and connection marking ([8fefd39](https://github.com/jinndi/SKeen/commit/8fefd39a22d1da25e415dfd89e5853a1556769b2))


### 🧰 Chore

* **test:** remove CONNMARK validation from chain tests ([a7ec9ed](https://github.com/jinndi/SKeen/commit/a7ec9edceb9a8b63b5b073bb7c8887369b384029))

## [4.13.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.12.4...SKeen-v4.13.0) (2026-05-12)


### 🚀 Feat

* add KeenDNS local access support for TProxy mode ([79ee414](https://github.com/jinndi/SKeen/commit/79ee4141417b947969bce7244eadadb9f04a7076))


### 🧰 Chore

* **test:** add KeenDNS accept rule verification in mangle INPUT chain ([8599100](https://github.com/jinndi/SKeen/commit/859910039c80d3890bef40d406cd3f9bce5c5d7a))

## [4.12.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.12.3...SKeen-v4.12.4) (2026-05-11)


### 🐛 Fix

* **update:** correct typo in latest_version variable references ([41badf9](https://github.com/jinndi/SKeen/commit/41badf973ff8cf5eb87e1bac42a937de597a0ffb))
* **update:** streamline update logic for service proxy handling ([afec1e1](https://github.com/jinndi/SKeen/commit/afec1e161597ac4a8dc3068b059a7c7e4aa3d242))


### 🧰 Chore

* **test:** add DNS handling in mangle chain for OUTPUT chain ([d2a8066](https://github.com/jinndi/SKeen/commit/d2a8066d00b6927a7c5b1cb856881c83d53818bc))

## [4.12.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.12.2...SKeen-v4.12.3) (2026-05-10)


### 🐛 Fix

* **config:** remove trailing comma from network check array [#163](https://github.com/jinndi/SKeen/issues/163) ([e8c1d33](https://github.com/jinndi/SKeen/commit/e8c1d33077ee89dba35e6bb3de4acba685eecd4a))
* **firewall:** handle multiple WAN IPs in exclusion sets ([97b5777](https://github.com/jinndi/SKeen/commit/97b577741917f94177f2ceaad28a443d3e6440b9))

## [4.12.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.12.1...SKeen-v4.12.2) (2026-05-08)


### 🐛 Fix

* **firewall:** correct DNS TProxy marking logic (OUTPUT chain) and refactor iptables rules ([27de934](https://github.com/jinndi/SKeen/commit/27de934e417f9183f2a593a4d2d4694a1343c6a1))

## [4.12.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.12.0...SKeen-v4.12.1) (2026-05-07)


### 🐛 Fix

* **en:** add ip_set_bitmap_port module to loading_modules function ([32ae011](https://github.com/jinndi/SKeen/commit/32ae011bdc7f3d3205b6002391aae5a858e31426))

## [4.12.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.11.5...SKeen-v4.12.0) (2026-05-07)


### 🚀 Feat

* **install:** add mirror support for installation ([ec763c2](https://github.com/jinndi/SKeen/commit/ec763c28098a2b131c033481a86834a6c452856d))


### 🤖 CI/CD

* add mirror-sb workflow for static branch synchronization ([df9bb8e](https://github.com/jinndi/SKeen/commit/df9bb8e46b3d6de2fda6cf1a07619a8a2bec3766))
* **mirror-sb:** filter OpenWrt packages by target architecture ([df1dab9](https://github.com/jinndi/SKeen/commit/df1dab9d3e0653d980bf90bdcfb4ac1ef2e6b939))
* **sync-static-branch:** preserve .git and sing-box directories during cleanup ([874bae7](https://github.com/jinndi/SKeen/commit/874bae7aaf318d2469c5481fe89abe42fb3ccb95))
* **sync-static-branch:** prevent README.md deletion during static branch sync ([243e85f](https://github.com/jinndi/SKeen/commit/243e85f4c4e0f7332ba6e820378bfab2efc0e555))
* update checkout action to v4 and add sync-static-branch workflow ([eb8ffca](https://github.com/jinndi/SKeen/commit/eb8ffca6343bf279d8409466fbb028215bd948b3))

## [4.11.5](https://github.com/jinndi/SKeen/compare/SKeen-v4.11.4...SKeen-v4.11.5) (2026-05-06)


### 🛠 Refactor

* **network:** optimize network stack and conntrack limits (if enable network.tuning) ([3a57427](https://github.com/jinndi/SKeen/commit/3a57427b94d980db7645163ac09647fc4faa8824))

## [4.11.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.11.3...SKeen-v4.11.4) (2026-05-04)


### 🐛 Fix

* **update:** streamline update logic for SKeen script ([dd5ab0e](https://github.com/jinndi/SKeen/commit/dd5ab0ecf86a6a1c898a323e2dc08e04a55e3923))

## [4.11.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.11.2...SKeen-v4.11.3) (2026-05-04)


### 🐛 Fix

* **update:** correct version variable scope and naming consistency ([d2c5cdc](https://github.com/jinndi/SKeen/commit/d2c5cdc27048a3c678e5e4eb4214cd148148ee1b))

## [4.11.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.11.1...SKeen-v4.11.2) (2026-05-03)


### 🐛 Fix

* **firewall:** improve DNS mode handling and iptables rule management ([aa4f19c](https://github.com/jinndi/SKeen/commit/aa4f19cc0c0b916c1ba9221a24bd4a48c2ae0eab))

## [4.11.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.11.0...SKeen-v4.11.1) (2026-05-03)


### 🐛 Fix

* **redirect_dns:** add conditional DNS acceptance rule based on SKEEN_REDIRECT_DNS_ENABLE flag ([bb985f1](https://github.com/jinndi/SKeen/commit/bb985f1495332e197e70523aaa46a34104c6ec85))
* **update:** extend service control logic to include FIREWALL_PROXY_ROUTER flag ([fcb7a36](https://github.com/jinndi/SKeen/commit/fcb7a3606b9eac73af702a554b62bed6c609cb64))


### 🛠 Refactor

* **firewall:** extract chain existence check into reusable function ([d240820](https://github.com/jinndi/SKeen/commit/d240820cf9b3114a09b1abbeb197af6828786b29))
* **firewall:** separate protocol parameter in DNS redirect rules ([74de9d2](https://github.com/jinndi/SKeen/commit/74de9d26c7d8f5cd25db4487dee534542881fff6))

## [4.11.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.10.0...SKeen-v4.11.0) (2026-05-02)


### 🚀 Feat

* **firewall:** implement protocol-aware rule generation ([91b16a1](https://github.com/jinndi/SKeen/commit/91b16a15800591e351299f65c7c62bfee985240d))
* **firewall:** use ipset for port lists ([1f4bde6](https://github.com/jinndi/SKeen/commit/1f4bde6894e3c3f4c479c214fadcd66511ca1c33))


### 🐛 Fix

* **firewall:** apply connmark rules unconditionally in PREROUTING chain ([91318a7](https://github.com/jinndi/SKeen/commit/91318a747a2f0fec6e9d7e8e7af1eeef2d12ee5a))
* **firewall:** apply socket MARK and ACCEPT rules only for TCP in SKEEN_TPROXY_NETWORK ([271367a](https://github.com/jinndi/SKeen/commit/271367a0e2e3c592d7560d196457a6bf953f564f))
* **firewall:** ensure TABLE_MARK filter only applies with active mark policy ([54f9c44](https://github.com/jinndi/SKeen/commit/54f9c44e26ee4577644e13c28201d25a3822f8d0))
* **firewall:** improve cleanup reliability with comment-based rule removal ([ebdecd9](https://github.com/jinndi/SKeen/commit/ebdecd9959c7d21ad13dad792a4ab19c788b06d0))
* **firewall:** use connmark instead of mark in PREROUTING router rule ([904d018](https://github.com/jinndi/SKeen/commit/904d0182d51be95746195fc1d16ea36119652444))


### 🛠 Refactor

* **firewall:** move mark and gid filters inside chains ([03e6f92](https://github.com/jinndi/SKeen/commit/03e6f9268513880e0f9d4c5f7f03947ae97d6ee5))
* **firewall:** simplify chain cleanup using rule command output ([8833333](https://github.com/jinndi/SKeen/commit/8833333705af1be19886eab9087ad5855c5eb3b8))


### 🧰 Chore

* **config:** update default excluded ports format and values ([b050b7a](https://github.com/jinndi/SKeen/commit/b050b7a95779fe96cd9be271955d5caf0956a718))
* **firewall:** add ACCEPT rule for marked TPROXY traffic in mangle table ([7bc8ea8](https://github.com/jinndi/SKeen/commit/7bc8ea80e4f06c0756e37b3a290ad8469dc7f308))

## [4.10.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.9.0...SKeen-v4.10.0) (2026-05-01)


### 🚀 Feat

* **firewall:** add proxy router option ([0d145a5](https://github.com/jinndi/SKeen/commit/0d145a5e51550fac9bf77aa29ea843aa0981086d))


### 🐛 Fix

* **firewall:** extend route rule bypass for tun and none modes ([3324b43](https://github.com/jinndi/SKeen/commit/3324b43a9007b741f7ad92d70c6ec456ea152d61)), closes [#151](https://github.com/jinndi/SKeen/issues/151)
* **firewall:** skip route rule set when firewall mode is redirect ([0dc1f6e](https://github.com/jinndi/SKeen/commit/0dc1f6e19b7e30e15a988bef77d932d5603cc616))


### 🛠 Refactor

* **firewall:** consolidate port rule logic with unified dispatch system ([466aabe](https://github.com/jinndi/SKeen/commit/466aabe5b16dbf393ce5ed1c4a22b568cb7d768e))
* simplify chain rule logic with case-based dispatch ([e31060e](https://github.com/jinndi/SKeen/commit/e31060e6c718c320c058bfdcf09f34d4807185ba))

## [4.9.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.8.4...SKeen-v4.9.0) (2026-04-30)


### 🚀 Feat

* **firewall:** add DNS redirect configuration and rule management ([5802050](https://github.com/jinndi/SKeen/commit/5802050c097da7c91306eb83692778011cbf5cee))


### 🐛 Fix

* **tproxy:** correct protocol selection logic for prerouting rules ([2a9fc31](https://github.com/jinndi/SKeen/commit/2a9fc315e5c86d39c793e4981c46e1417d24f6be))


### 🛠 Refactor

* **kernel:** optimize module loading and owner module detection ([11041b9](https://github.com/jinndi/SKeen/commit/11041b9ba69655c6fa69a09e5eecb7a41136b944))
* **tproxy:** restructure transparent proxy rule generation logic ([314ec63](https://github.com/jinndi/SKeen/commit/314ec63468fd9def616c8da7646ba70e91514983))


### 🧰 Chore

* **firewall:** remove unused case option from firewall preparation ([4ce8404](https://github.com/jinndi/SKeen/commit/4ce84049310cc5a2ea598f388bb776aa9d33728a))

## [4.8.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.8.3...SKeen-v4.8.4) (2026-04-29)


### 🛠 Refactor

* **menu:** restructure conditional logic for firewall status display ([b063699](https://github.com/jinndi/SKeen/commit/b0636999044a8192a71b80688aee9941665e5fef))


### 📦 Deps

* replace ip with ip-full package for enhanced network functionality ([f4ecfc1](https://github.com/jinndi/SKeen/commit/f4ecfc10673bc8f7e835f3d9b824852dd9cb50ea))

## [4.8.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.8.2...SKeen-v4.8.3) (2026-04-29)


### 🐛 Fix

* **iptables:** improve IPv6 detection logic for global addresses ([a53a774](https://github.com/jinndi/SKeen/commit/a53a774f11243822b1116496806e44c75b90c34d))


### 🎨 Style

* **i18n:** enhance test logging with iptables binary context ([1cc0be1](https://github.com/jinndi/SKeen/commit/1cc0be155aee85c34ac1176cc0f738dd0b143d3a))


### 🛠 Refactor

* **cli:** enhance network interface display with comprehensive system metrics (`iface` command) ([d7e2bc7](https://github.com/jinndi/SKeen/commit/d7e2bc7c4b81009fb56bd11d39d63f5656607740))

## [4.8.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.8.1...SKeen-v4.8.2) (2026-04-28)


### 🐛 Fix

* **iptables:** improve IPv6 detection logic ([1f84b40](https://github.com/jinndi/SKeen/commit/1f84b403ddc3fda04b03108d074ed5dbd756601f))

## [4.8.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.8.0...SKeen-v4.8.1) (2026-04-28)


### ⚡ Perf

* **tun:** configure txqueuelen for opkgtun devices ([534bdcf](https://github.com/jinndi/SKeen/commit/534bdcf4fef4ac1687c8a62fce12a7ab5647f631))


### 🧰 Chore

* **cli:** add iface command to display network interface table ([4abb671](https://github.com/jinndi/SKeen/commit/4abb6710d5a888f253e38a21940b1d80e4e45d4f))

## [4.8.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.7.5...SKeen-v4.8.0) (2026-04-28)


### 🚀 Feat

* **firewall:** implement tun chain and rules management ([d49d2eb](https://github.com/jinndi/SKeen/commit/d49d2eb6192b3a68395c6ea69079869c0c921eb6))
* **test:** restructure test logic for tun mode support and fix port exclusion check ([c125d6c](https://github.com/jinndi/SKeen/commit/c125d6c76f498d83e09387fa6793758048329e7b))


### 🎨 Style

* **menu:** add tun interface status display to menu output ([2e22a05](https://github.com/jinndi/SKeen/commit/2e22a057075d2befd2bc44f363749cb7e05e577d))
* **menu:** export and display SKEEN_POLICY_NAME consistently ([10ee81c](https://github.com/jinndi/SKeen/commit/10ee81cd37b1f4d036408f7795306ff855122400))

## [4.7.5](https://github.com/jinndi/SKeen/compare/SKeen-v4.7.4...SKeen-v4.7.5) (2026-04-27)


### 🧰 Chore

* v4.7.4 update supplement ([851df68](https://github.com/jinndi/SKeen/commit/851df68f97cf39d0dddee14f0303fb336434c474))

## [4.7.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.7.3...SKeen-v4.7.4) (2026-04-27)


### 🐛 Fix

* **tun:** implement iptables NAT masquerade and cleanup for tunnel interfaces ([98d2ce4](https://github.com/jinndi/SKeen/commit/98d2ce449a789589cbfcd2c13f071659562cf5c1))


### 🛠 Refactor

* **route:** simplify route rule logic and improve default route validation ([ec3a4c1](https://github.com/jinndi/SKeen/commit/ec3a4c1d6e02b9a4a8a0298631103f0c961c9c83))

## [4.7.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.7.2...SKeen-v4.7.3) (2026-04-27)


### 🐛 Fix

* **tun:** disable auto_route and improve route table validation logic ([6f3bcb4](https://github.com/jinndi/SKeen/commit/6f3bcb4e3aaf0a0a901cb0c17e935d487de6af36))

## [4.7.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.7.1...SKeen-v4.7.2) (2026-04-26)


### 🐛 Fix

* improve group file handling in get_free_gid function ([a3ac434](https://github.com/jinndi/SKeen/commit/a3ac4346ba997668f71a19daf8e0ef97841ace75))
* **policy:** synchronize policy mark extraction using parallel file descriptors ([0d0bbc6](https://github.com/jinndi/SKeen/commit/0d0bbc61a5821ef99e55cef729fce75978be6df3))
* **tun:** update TUN configuration comments and streamline OpkgTun ID generation ([04b55e2](https://github.com/jinndi/SKeen/commit/04b55e20a9d47078676fc9ee48577ed8002e86a8))


### ⚡ Perf

* **policy:** optimize mark retrieval with printf and conditional returns ([a54211d](https://github.com/jinndi/SKeen/commit/a54211ded27bb523fe0f2098368a4d6dc8ffda6f))

## [4.7.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.7.0...SKeen-v4.7.1) (2026-04-24)


### 🧰 Chore

* add disk space validation for install, update, and backup operations ([1e8009b](https://github.com/jinndi/SKeen/commit/1e8009b48ef9c2f1492bb0f778c46b9a11f99157))

## [4.7.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.6.4...SKeen-v4.7.0) (2026-04-24)


### 🚀 Feat

* **cli:** add clean cache command to clear sing-box cache file ([3bda72f](https://github.com/jinndi/SKeen/commit/3bda72f47abe0bd4d9f9a551c6d7bd03f83d3fd1))
* update rci function to support POST ([f87b2f7](https://github.com/jinndi/SKeen/commit/f87b2f72a37d17aeca3a6e52fdbd41cd64ca7ca2))

## [4.6.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.6.3...SKeen-v4.6.4) (2026-04-20)


### 🐛 Fix

* **cli:** improve config creation logic with force option and better messaging ([9dfc35d](https://github.com/jinndi/SKeen/commit/9dfc35d8a0bb0daf9bff49a4372c0319c1c897c7))

## [4.6.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.6.2...SKeen-v4.6.3) (2026-04-20)


### 🧰 Chore

* **cli:** improve output formatting ([ec17022](https://github.com/jinndi/SKeen/commit/ec17022f0c02e2424100b65cb47c156737eddd5e))

## [4.6.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.6.1...SKeen-v4.6.2) (2026-04-20)


### 🐛 Fix

* conditionally create config based on `sing_config` (update core) ([c996717](https://github.com/jinndi/SKeen/commit/c99671719537705ce921f5a292d57e62d6646a1f))
* download sing-box ([8e76eca](https://github.com/jinndi/SKeen/commit/8e76eca57ba8b5055cd48c8cd9e5b425eeb4cd6b))

## [4.6.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.6.0...SKeen-v4.6.1) (2026-04-19)


### 🐛 Fix

* improve messaging ([d78c905](https://github.com/jinndi/SKeen/commit/d78c905b694863d9947a3d0f5984ecc77d8eb8df))

## [4.6.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.5.6...SKeen-v4.6.0) (2026-04-19)


### 🚀 Feat

* **install:** separate installation scripts by language ([6f4f8e9](https://github.com/jinndi/SKeen/commit/6f4f8e98c05a51ffc1b80edd552d370feefbbeed))


### 🧰 Chore

* improve DNS rule handling in hybrid and tproxy modes ([1b5d41a](https://github.com/jinndi/SKeen/commit/1b5d41aa29aa2940decf599e376544f2b4ff7f14))

## [4.5.6](https://github.com/jinndi/SKeen/compare/SKeen-v4.5.5...SKeen-v4.5.6) (2026-04-18)


### ⚡ Perf

* add explicit rules for DNS traffic in hybrid and tproxy modes ([6086fcd](https://github.com/jinndi/SKeen/commit/6086fcde2bcd67fd8e74e0f7b8dff73195faba8b))

## [4.5.5](https://github.com/jinndi/SKeen/compare/SKeen-v4.5.4...SKeen-v4.5.5) (2026-04-18)


### 🐛 Fix

* **tproxy:** apply socket match only for TCP, drop UDP socket lookup ([ede731b](https://github.com/jinndi/SKeen/commit/ede731b92de26fa4559052fda7198b447d034413))


### ⚡ Perf

* update tproxy rules and kernel modules (socket) ([a811cc1](https://github.com/jinndi/SKeen/commit/a811cc1c2b57dafa712c38d61f6442eac826a6d9))

## [4.5.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.5.3...SKeen-v4.5.4) (2026-04-18)


### ⚡ Perf

* improve script robustness and shell efficiency ([c7a7d2f](https://github.com/jinndi/SKeen/commit/c7a7d2f599471ffa4f9f32246860befaa2156c53))
* simplify is_tty implementation ([17559f2](https://github.com/jinndi/SKeen/commit/17559f2fc712ff621e2af47fd771fc1e93154cb5))

## [4.5.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.5.2...SKeen-v4.5.3) (2026-04-18)


### 🧰 Chore

* update service stop logic ([65ba0b7](https://github.com/jinndi/SKeen/commit/65ba0b7cfbcd4ffd57f453ba70928bd0a8d345e2))

## [4.5.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.5.1...SKeen-v4.5.2) (2026-04-18)


### 🐛 Fix

* restore WEB CLI functionality ([8105409](https://github.com/jinndi/SKeen/commit/8105409184977d8001984896d6e134f52b6dc38e))


### 🛠 Refactor

* optimize curl proxy handling and script structure ([61f8fc2](https://github.com/jinndi/SKeen/commit/61f8fc28380c4af154bad6adb2e8bfcd7a7ed980))

## [4.5.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.5.0...SKeen-v4.5.1) (2026-04-17)


### 🐛 Fix

* **iptables:** correct include/exclude ports handling from skeen.json ([9a608c2](https://github.com/jinndi/SKeen/commit/9a608c244c834e9b93ae3ea9cf8d3e6def912af0))


### 🧰 Chore

* Fixes and improvements ([ed21f41](https://github.com/jinndi/SKeen/commit/ed21f41e7c49faa3ccb9bd14335beca725c7aebb))

## [4.5.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.7...SKeen-v4.5.0) (2026-04-17)


### 🚀 Feat

* simplify configuration (Remove the "firewall-only" ) ([84ef57b](https://github.com/jinndi/SKeen/commit/84ef57b5d27457bfaeb0f405dbbc12ee74e43f1c))

## [4.4.7](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.6...SKeen-v4.4.7) (2026-04-15)


### 🧰 Chore

* **config:** add mobile example and update configs ([eb97d18](https://github.com/jinndi/SKeen/commit/eb97d18631f032e2613deaaa31dbaf8ab6a98967))

## [4.4.6](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.5...SKeen-v4.4.6) (2026-04-09)


### 🐛 Fix

* **network:** keep IPv6 enabled on t2s* interfaces when disabling global IPv6 ([ae52adc](https://github.com/jinndi/SKeen/commit/ae52adc12f2b7e55bb586485377555eae8094b88))


### 🧰 Chore

* **help:** update command table formatting and help output ([db9b5b0](https://github.com/jinndi/SKeen/commit/db9b5b0451ae583af6d899bd20dabc9834e92692))

## [4.4.5](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.4...SKeen-v4.4.5) (2026-04-09)


### 🐛 Fix

* add check_tty to update routine ([ecbbb20](https://github.com/jinndi/SKeen/commit/ecbbb2031d4c4f6c6adae536251c1a609396939d))
* update command table and add firewall-only checks ([cdcd19b](https://github.com/jinndi/SKeen/commit/cdcd19bb52ed9dd5d5e05da3e7746251aba29cd5))

## [4.4.4](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.3...SKeen-v4.4.4) (2026-04-08)


### 🧰 Chore

* **example:** update config with dns hosts and logical routing rules ([9ec0b76](https://github.com/jinndi/SKeen/commit/9ec0b761f77b3483d33f025a2131b6bf48edefe4))

## [4.4.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.2...SKeen-v4.4.3) (2026-04-07)


### 🧰 Chore

* add optional `sync_url` for `sing_config` remote sync ([d798a11](https://github.com/jinndi/SKeen/commit/d798a1173b4b2abd869701f7db60d95a91df7d4e))
* Added `user` and `pass` fields to `service_proxy` for proxy auth, updated ([0326680](https://github.com/jinndi/SKeen/commit/0326680b2c5325f1773fc2d1d65eaed752290b19))

## [4.4.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.1...SKeen-v4.4.2) (2026-04-06)


### 🛠 Refactor

* refactor module loader ([3a56460](https://github.com/jinndi/SKeen/commit/3a564608387762a1d63140669b9614b13df848a4))
* simplify config sync path handling ([f4245e7](https://github.com/jinndi/SKeen/commit/f4245e7ab30ad1c2572e04707c319f6f228ad648))


### ↩️ Revert

* remove lock file handling ([8d5b555](https://github.com/jinndi/SKeen/commit/8d5b555c76a3c36929e7aa449a0482ff67b8eae1))

## [4.4.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.4.0...SKeen-v4.4.1) (2026-04-06)


### 🐛 Fix

* avoid duplicate netfilter runs via lock file ([09b9e96](https://github.com/jinndi/SKeen/commit/09b9e96ed048ed1da8afc0b79410559d6e96c252))
* previously referenced the literal string “CONFIG_DIR” instead of the $CONFIG_DIR variable ([ee0fcf8](https://github.com/jinndi/SKeen/commit/ee0fcf8fe4d4e6f6be5d7f66a205a12d3fa31eef))

## [4.4.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.3.2...SKeen-v4.4.0) (2026-04-03)


### 🚀 Feat

* add support for a local proxy for update and sync commands ([5f05adf](https://github.com/jinndi/SKeen/commit/5f05adf9c596a660c1fab52170a565a9062db65c))


### ⚡ Perf

* optimize opkg list execution in install_dependencies ([b63caa1](https://github.com/jinndi/SKeen/commit/b63caa1b4450cc492edef7a84e717338f89219d7))

## [4.3.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.3.1...SKeen-v4.3.2) (2026-04-02)


### 🐛 Fix

* detection of firewall mode and the presence of DNS settings when the `sing_config.enable` option is enabled ([9923b2f](https://github.com/jinndi/SKeen/commit/9923b2f02da6815f7d8824296e5f49defefc87d3))

## [4.3.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.3.0...SKeen-v4.3.1) (2026-04-02)


### 🐛 Fix

* function to get the version during an update (update command) could receive unnecessary text when the request failed ([9214a10](https://github.com/jinndi/SKeen/commit/9214a1062445f8431f74e0a7de21e2244f48048c))
* increase sing-box download timeout from 90 to 720 seconds ([067c7ca](https://github.com/jinndi/SKeen/commit/067c7caec7a6845521782b6d349f090af5345837))
* reset and restore config and update default sing-box configuration ([46b12e6](https://github.com/jinndi/SKeen/commit/46b12e692160bbf69a672cf6e88403a725113e06))

## [4.3.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.2.1...SKeen-v4.3.0) (2026-04-02)


### 🚀 Feat

* add process uptime tracking to status output ([ee9575d](https://github.com/jinndi/SKeen/commit/ee9575d8fae976eb37dd77f29fc0c14d0352a0a0))
* **backup:** add support for passing archive name as parameter to restore command ([500eda1](https://github.com/jinndi/SKeen/commit/500eda1fcd1a43013d5f355dec5c8d0428f39839))
* **sync:** add configuration synchronization command and update documentation ([6640744](https://github.com/jinndi/SKeen/commit/6640744790ca5b9c0a762fa2a627bdcd1d1049de))


### 🛠 Refactor

* optimize terminal detection and logging functions ([4fc82de](https://github.com/jinndi/SKeen/commit/4fc82ded02c59f183f83f9e2f00fe6d01b39fb8e))
* RCI functionality policy mark retrieval ([e80da73](https://github.com/jinndi/SKeen/commit/e80da73578cc6f3aca8f1bc8c30f182f04ba4024))

## [4.2.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.2.0...SKeen-v4.2.1) (2026-04-01)


### 🐛 Fix

* add setting of SINGBOX_ARGS during reload when the sing_config.enable parameter is enabled ([7f4276e](https://github.com/jinndi/SKeen/commit/7f4276e2675b758bc5a7b45ad4cfe8a8758919dd))


### 🧰 Chore

* add file descriptors count to status output ([9c8d1c7](https://github.com/jinndi/SKeen/commit/9c8d1c7d1859523a8e24d662e38166b2be8622aa))

## [4.2.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.1.0...SKeen-v4.2.0) (2026-03-31)


### 🚀 Feat

* **config:** add sing-box configuration support with enable and path options ([7874203](https://github.com/jinndi/SKeen/commit/78742036ec72b3732488b54fa6f18b96026fb5d3))


### 🧰 Chore

* **README:** update sing-box advantages and installation requirements + sync plugin link ([8d85237](https://github.com/jinndi/SKeen/commit/8d85237484d274e0a80380dfcbc7fc8dc0103a25))

## [4.1.0](https://github.com/jinndi/SKeen/compare/SKeen-v4.0.3...SKeen-v4.1.0) (2026-03-31)


### 🚀 Feat

* add `backups` command and refactor `test` command output logs ([bbb805f](https://github.com/jinndi/SKeen/commit/bbb805f1fc222e59b54186b896acb75db2978142))


### 🛠 Refactor

* replace direct FIREWALL_ONLY_ENABLE checks with is_fw_only function ([15fdafe](https://github.com/jinndi/SKeen/commit/15fdafed72c97f5ea7db085ec44e0d4207aea8fd))
* update logging format and test output styling ([5453ac0](https://github.com/jinndi/SKeen/commit/5453ac02d1c5f36f2a3b57fa049d970db078a4f3))

## [4.0.3](https://github.com/jinndi/SKeen/compare/SKeen-v4.0.2...SKeen-v4.0.3) (2026-02-15)


### 🧰 Chore

* add architecture detection for ELF binaries in install script ([2bc01e0](https://github.com/jinndi/SKeen/commit/2bc01e0547eea5b838e2280948a950ad6d21788b))

## [4.0.2](https://github.com/jinndi/SKeen/compare/SKeen-v4.0.1...SKeen-v4.0.2) (2026-02-14)


### 🧰 Chore

* Update dependencies and improve port occupancy check in installation script ([f3e7b77](https://github.com/jinndi/SKeen/commit/f3e7b77f891a7813d6742fed5e87e3ef91377a4b))

## [4.0.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.0.0...SKeen-v4.0.1) (2026-02-11)


### 🐛 Fix

* **singbox:** fix update loop and add missing checks ([5d7bf35](https://github.com/jinndi/SKeen/commit/5d7bf3501aa83f51b4e58c9d258932e78d6d7ead))

## [4.0.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.7...SKeen-v4.0.0) (2026-02-10)


### ⚠ BREAKING CHANGES

* **firewall:** add firewall-only mode. See 'firewall.only' in README

### 🚀 Feat

* **firewall:** add firewall-only mode. See 'firewall.only' in README ([ccf3bc9](https://github.com/jinndi/SKeen/commit/ccf3bc91dfc624dabb6d696bfdf8c10390c6f66d))


### 🛠 Refactor

* **firewall:** move port validation to prepare_firewall function ([fdd7401](https://github.com/jinndi/SKeen/commit/fdd74010ecc3068c87c1bd3942084fb8b45cca66))
* **start:** refactor group creation logic to use return codes for delimiter handling ([0f8eeac](https://github.com/jinndi/SKeen/commit/0f8eeac42d56b4f39cb8b876a57984305a33a489))

## [3.10.7](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.6...SKeen-v3.10.7) (2026-02-09)


### 📦 Deps

* **tproxy:** remove unused xt_socket module from loading ([80ee921](https://github.com/jinndi/SKeen/commit/80ee9217183959ac4304648d58879cf4e1c3b4f4))

## [3.10.6](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.5...SKeen-v3.10.6) (2026-02-09)


### 🛠 Refactor

* **tproxy:** simplify network rule handling with loop iteration ([12b3135](https://github.com/jinndi/SKeen/commit/12b31356c6bad5acb807daf8df11e9b9ae4fe109))

## [3.10.5](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.4...SKeen-v3.10.5) (2026-02-08)


### 🐛 Fix

* **tproxy:** Fix UDP handling and apply minor tweaks ([bc1a499](https://github.com/jinndi/SKeen/commit/bc1a499d3cba87d696dc36af51905fb945f09bee))

## [3.10.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.3...SKeen-v3.10.4) (2026-02-08)


### 🛠 Refactor

* extract TUN interface rules into dedicated function and mode ([a29e81a](https://github.com/jinndi/SKeen/commit/a29e81a46e92a1e10879c18da162074c67bb255c))

## [3.10.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.2...SKeen-v3.10.3) (2026-02-07)


### 🐛 Fix

* **tun:** add IP address conflict detection in tunnel creation ([d2a17cf](https://github.com/jinndi/SKeen/commit/d2a17cf2213841ae1108945c041b96e01df81ff8))

## [3.10.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.1...SKeen-v3.10.2) (2026-02-07)


### 🐛 Fix

* **tun:** add error handling with cleanup on tunnel creation failures ([8064b4e](https://github.com/jinndi/SKeen/commit/8064b4eea3af62100a9cf1146184303d23cc2554))

## [3.10.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.10.0...SKeen-v3.10.1) (2026-02-07)


### 🐛 Fix

* **tun:** replace IP validation with name validation in tun_create ([a13dde3](https://github.com/jinndi/SKeen/commit/a13dde34561acc684ab4fa682f5bf97ccbaeb23f))

## [3.10.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.9.5...SKeen-v3.10.0) (2026-02-07)


### 🚀 Feat

* **tun:** add OpkgTun manager commands for KeeneticOS v5+ ([006a0e0](https://github.com/jinndi/SKeen/commit/006a0e06fdcbc5468ee8a603cd09b2cc1aba2972))


### ⚙️ Config

* **examples:** update TUN interface example configuration ([2b11f45](https://github.com/jinndi/SKeen/commit/2b11f453b346dbe44c548e74ea3919cf987261c3))

## [3.9.5](https://github.com/jinndi/SKeen/compare/SKeen-v3.9.4...SKeen-v3.9.5) (2026-02-06)


### 🛠 Refactor

* **cli:** extract version display to named function ([ca6d135](https://github.com/jinndi/SKeen/commit/ca6d13550615aa75089010bb51b34fecc735b139))
* **show_menu:** refactor menu display to use accumulated output string ([a2b652e](https://github.com/jinndi/SKeen/commit/a2b652e26ae6a79af083f729c7ff9e859c733fb5))


### ⚙️ Config

* **examples:** add examples directory ([53f5d42](https://github.com/jinndi/SKeen/commit/53f5d426b5682c446ad5aa03c81337cbe4c21dcd))
* **examples:** add inbounds_tun example ([ce17484](https://github.com/jinndi/SKeen/commit/ce17484a047faf7dc82be69199703dc30709ce07))
* Reduce UDP timeout from 5m to 3m and remove tcp_multi_path option from redirect inbound configuration for improved connection handling efficiency. ([f465c23](https://github.com/jinndi/SKeen/commit/f465c23893df5406ae14955f1236899bb4e83ba2))
* remove udp_fragment option from tproxy inbound ([f58da4f](https://github.com/jinndi/SKeen/commit/f58da4f53fd9f3b38df1879e2f809651189cd05d))

## [3.9.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.9.3...SKeen-v3.9.4) (2026-02-05)


### 🛠 Refactor

* **menu:** move exit option from position 6 to 0 ([1ab1fc9](https://github.com/jinndi/SKeen/commit/1ab1fc9c466fd2f2f6e10c8b5321d0d13ccc00af))

## [3.9.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.9.2...SKeen-v3.9.3) (2026-02-04)


### ⚙️ Config

* The old SKeen configuration format is no longer used. A new JSON-format configuration file will be created alongside the old one. Additional settings have also been added - see the README for details. https://github.com/jinndi/SKeen?tab=readme-ov-file#%EF%B8%8F-settigs ([ac25950](https://github.com/jinndi/SKeen/commit/ac259500ea5e45c32abc09ad0f97ca9284608ba2))

## [3.9.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.9.1...SKeen-v3.9.2) (2026-02-04)


### 🐛 Fix

* do not reload user config on every menu invocation ([08e44e0](https://github.com/jinndi/SKeen/commit/08e44e008355ead3f635b6bf54300f2535d83660))


### ⚡ Perf

* added Skeen NETWORK_TUNING configuration option, see README ([3e4e5ab](https://github.com/jinndi/SKeen/commit/3e4e5ab77cfd641090a9ddf4ecc1e63cdcbc746a))


### 🧰 Chore

* extracted the file descriptor count retrieval into a separate function ([291ef38](https://github.com/jinndi/SKeen/commit/291ef38e2fe608a76077504f861da86db635e9b2))
* reworked the logic for loading skeen.conf configuration ([aa48913](https://github.com/jinndi/SKeen/commit/aa48913bc3333a80d36a228085615fa0e356e445))

## [3.9.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.9.0...SKeen-v3.9.1) (2026-02-03)


### 🐛 Fix

* typo in the error log message "Check your internet connection" ([88ae7b1](https://github.com/jinndi/SKeen/commit/88ae7b153e7be2c589c5ddba807f4d6e22ea6b7c))


### 🧰 Chore

* don't require port 443 to be free for TProxy/Mixed modes 1 ([679e4a6](https://github.com/jinndi/SKeen/commit/679e4a6535fde79ece60477c547ed6f6eb055d4b))
* **shell:** make setup_bypass_ipset safer and more reliable ([9a40b9b](https://github.com/jinndi/SKeen/commit/9a40b9b609d9bb33f03eb75986e28983b11977e8))

## [3.9.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.8.4...SKeen-v3.9.0) (2026-02-02)


### 🚀 Feat

* add port availability check before start ([284ce92](https://github.com/jinndi/SKeen/commit/284ce92b32bac7687ee26be7fa6e4ad8945a508a))
* add UDP conntrack timeout settings for TProxy mode ([70b217c](https://github.com/jinndi/SKeen/commit/70b217c22fc5f8dfef1d761b5ded4328c3267344))
* improve status command (Show memory in MB with peak value and thread count) ([893f687](https://github.com/jinndi/SKeen/commit/893f68719f6328f8e4fd5ab43cdfd5dd3035427f))
* optimize connection tracking settings ([008e25f](https://github.com/jinndi/SKeen/commit/008e25f8a385be569199b5dd4fbe4bfd0a257096))
* optimize network tuning for better proxy performance ([4b3de43](https://github.com/jinndi/SKeen/commit/4b3de437f866fbcb4af93c0ff6d908840bb1316e))
* Optimize TCP and socket buffers for VPN/Proxy ([509ad4d](https://github.com/jinndi/SKeen/commit/509ad4da01f8dec105683b1667c946d159e60bcb))


### 🐛 Fix

* improve backup restore logic in download_skeen_script ([fdfb39a](https://github.com/jinndi/SKeen/commit/fdfb39a0390db4cda20aa5455a84326677a701fd))

## [3.8.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.8.3...SKeen-v3.8.4) (2026-02-01)


### 🐛 Fix

* **config:** correct typo in ADDRESSES variable ([ea1bc35](https://github.com/jinndi/SKeen/commit/ea1bc35ed0f3113ddb2c2e70b51780a20c5f801f))

## [3.8.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.8.2...SKeen-v3.8.3) (2026-02-01)


### 🐛 Fix

* **iptables:** remove unused DNS rules ([c87dcad](https://github.com/jinndi/SKeen/commit/c87dcadcb3d32823e47a08c081d07dcb082aff5c))

## [3.8.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.8.1...SKeen-v3.8.2) (2026-02-01)


### 🐛 Fix

* ask_and_update func ([b2158a7](https://github.com/jinndi/SKeen/commit/b2158a78db244388a9a430b51dd0cffabc64c95b))

## [3.8.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.8.0...SKeen-v3.8.1) (2026-02-01)


### ⚡ Perf

* **dns:** Optimized mangle/nat rules for DNS handling in hybrid/tproxy modes ([ee814ec](https://github.com/jinndi/SKeen/commit/ee814ecc3e716f211251e6a8db5d45f70d2d2361))

## [3.8.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.7.5...SKeen-v3.8.0) (2026-01-31)


### 🚀 Feat

* **firewall:** migrate bypass networks to ipset ([135e37f](https://github.com/jinndi/SKeen/commit/135e37f7338abfc32a80f8865b74d3ec73f0b57a))


### ⚡ Perf

* **iptables:** optimize CONNMARK efficiency using conntrack state ([e880d73](https://github.com/jinndi/SKeen/commit/e880d7386070f67a9875ad825cd7a8689bf5cec3))

## [3.7.5](https://github.com/jinndi/SKeen/compare/SKeen-v3.7.4...SKeen-v3.7.5) (2026-01-30)


### 🐛 Fix

* path /etc/group ([6192f88](https://github.com/jinndi/SKeen/commit/6192f8804adc27d66fcff4bc5aa756b613a6d09d))

## [3.7.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.7.3...SKeen-v3.7.4) (2026-01-30)


### 🛠 Refactor

* replace SKeen user creation with group-only creation ([9995144](https://github.com/jinndi/SKeen/commit/999514474367cad6e0768380b331197b7922c7d3))
* simplify is_running implementation ([8e87525](https://github.com/jinndi/SKeen/commit/8e87525e49a49b4893e50ab8bab819cda0f39b50))
* unify update prompts and version checks ([d794d22](https://github.com/jinndi/SKeen/commit/d794d22bc247f7822d4b6751794bbd083c14ad7d))


### 🧰 Chore

* add check for skeen group existence before starting sing-box ([64a496d](https://github.com/jinndi/SKeen/commit/64a496db8532cada27970e8ca13d8dd5cbd6264e))

## [3.7.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.7.2...SKeen-v3.7.3) (2026-01-30)


### 🐛 Fix

* **network:** remove redundant 192.88.99.2/32 subnet ([7c5771b](https://github.com/jinndi/SKeen/commit/7c5771b9eac23b8050070ba94d68dea1a70e383c))


### 🛠 Refactor

* **network:** wrap sysctl commands in a block with &gt;/dev/null 2&gt;&1 ([ff5cc5a](https://github.com/jinndi/SKeen/commit/ff5cc5aef946bfef7a4ac9ed4990332eadf456c4))

## [3.7.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.7.1...SKeen-v3.7.2) (2026-01-30)


### ⚡ Perf

* **net:** add apply_sysctl_network_tuning() for network stack tuning ([9137bd6](https://github.com/jinndi/SKeen/commit/9137bd639d4f9f2dd6bbd0a743adf285cdbe2df2))

## [3.7.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.7.0...SKeen-v3.7.1) (2026-01-29)


### 🐛 Fix

* **iptables:** ensure socket --transparent MARK and TPROXY are applied after exclude rules ([1a7c776](https://github.com/jinndi/SKeen/commit/1a7c776a9caf5d85ea6bf1a945d876684053f115))
* port validation to collect invalid ports and log them as a single list + registration of ports for firewall hook to ensure proper interception + IP exclude validation to collect invalid addresses and log them once ([f82d117](https://github.com/jinndi/SKeen/commit/f82d1174e40f3219cbbda0b1a2be2627dd7faa58))


### 🧰 Chore

* add default ports to bypass NTP ([e4726a9](https://github.com/jinndi/SKeen/commit/e4726a97cfdd4d3ce3225897f53a320f5b0799b3))
* add default ports to bypass SMB traffic ([cf4a8fc](https://github.com/jinndi/SKeen/commit/cf4a8fce0581f0c2c6757468fe56eac798cf60cd))
* enable net.ipv4.ip_forward=1 after sing-box start ([221af7e](https://github.com/jinndi/SKeen/commit/221af7e56eea5ab2e709ae49cf03faa3b87ddb57))

## [3.7.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.10...SKeen-v3.7.0) (2026-01-29)


### 🚀 Feat

* now higher priority for module loading is given to modules located in the OS kernel ([90c0be6](https://github.com/jinndi/SKeen/commit/90c0be6130995bbab91abf1547acc02259b6e457))


### 🛠 Refactor

* simplified the style of the function that checks the owner module functionality ([74d239b](https://github.com/jinndi/SKeen/commit/74d239b0e31c16f4678c5ef27e573feb6f4ac0bb))


### 🧰 Chore

* check package availability before opkg install ([d7541ba](https://github.com/jinndi/SKeen/commit/d7541ba46d4dd30dee5eb66d1c7f75f80e622b39))
* do not trigger firewall rule application for the nat table in hybrid mode, since it will be applied via mangle as well ([fade749](https://github.com/jinndi/SKeen/commit/fade7494dbedcbbcc9ad0511f79c0f57bf74cc43))
* small improvements and fixes ([2009805](https://github.com/jinndi/SKeen/commit/20098052b9d0ef5ed4db18203b155aeabb6320fc))

## [3.6.10](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.9...SKeen-v3.6.10) (2026-01-28)


### 🧰 Chore

* make sing-box ulimit calculation safer on BusyBox ([a299327](https://github.com/jinndi/SKeen/commit/a29932710d6dcf7642d29dc64e9467155b5527f1))

## [3.6.9](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.8...SKeen-v3.6.9) (2026-01-28)


### 🐛 Fix

* check if port 443 is in use via telnet ([8bf24ac](https://github.com/jinndi/SKeen/commit/8bf24ac4c8ac1986fd62902de4917026351f0273))


### 🎨 Style

* do not display information about IP versions, network types, or DNS operations if the firewall mode is set to 'none' ([4e1fbfd](https://github.com/jinndi/SKeen/commit/4e1fbfd8a898d668a22d1317bf30f150698d54c7))

## [3.6.8](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.7...SKeen-v3.6.8) (2026-01-27)


### 🐛 Fix

* fixed loading of the xt_owner.ko module on firmware version 5.0.4 of the router ([ba9ed8d](https://github.com/jinndi/SKeen/commit/ba9ed8db7832d8a95b8fd47ed5c77b9511d74d3c))


### ↩️ Revert

* ca-bundle dependency rollback not needed ([f43cc85](https://github.com/jinndi/SKeen/commit/f43cc85c300cf4a36b510f3a098eadcb529aaa27))

## [3.6.7](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.6...SKeen-v3.6.7) (2026-01-26)


### 🐛 Fix

* ndm Opkg::Manager error: /opt/etc/ndm/netfilter.d/skeen_firewall.sh timed out. When the internet is inactive, the hook now simply skips applying firewall rules. ([aca67b4](https://github.com/jinndi/SKeen/commit/aca67b448650064b3b00459f5b9d47c0024cf639))

## [3.6.6](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.5...SKeen-v3.6.6) (2026-01-26)


### 📦 Deps

* add ca-bundle for TLS verification ([27c1891](https://github.com/jinndi/SKeen/commit/27c1891c95efe13a132b7e442db944b3f2c82de1))

## [3.6.5](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.4...SKeen-v3.6.5) (2026-01-25)


### 🧰 Chore

* adjust default sing-box configs (Clash mode rules, tag name selector) ([a7d2f23](https://github.com/jinndi/SKeen/commit/a7d2f23260807ffd2f60edd22689525867e3e357))

## [3.6.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.3...SKeen-v3.6.4) (2026-01-25)


### 🐛 Fix

* stop the script installation on the first missing dependency ([9fcf618](https://github.com/jinndi/SKeen/commit/9fcf61861aad2830d2d95fba58fb49ce379f1009))


### 🎨 Style

* organize CLI help output into categories for better readability ([50e919e](https://github.com/jinndi/SKeen/commit/50e919e5ab78c6c512c740402e04790f53553fef))

## [3.6.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.2...SKeen-v3.6.3) (2026-01-25)


### 🐛 Fix

* do not continue script execution when started from CLI if the configuration is invalid ([a2562e1](https://github.com/jinndi/SKeen/commit/a2562e12e4db257202f0860e8827e4bed5d10d2a))
* typo in sed command and INET_TEST_IPV ([551e28b](https://github.com/jinndi/SKeen/commit/551e28bc3d1977684b0425b989542953ad04e6fd))


### 🧰 Chore

* add `reload` CLI option to restart sing-box without touching firewall rules ([26f4e0c](https://github.com/jinndi/SKeen/commit/26f4e0cfee65e5bd15192d482aa43223f2a69fcb))
* improved behavior of the press_any_key_to_menu function and removed redundant code along with it ([f280242](https://github.com/jinndi/SKeen/commit/f2802424922c89dfea2cfb25102a8bbf6d66ce2d))
* remove firewall hook file and sing-box user on uninstall ([d3c4512](https://github.com/jinndi/SKeen/commit/d3c4512beed79542536b55f591b86df9bbcd5d21))

## [3.6.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.1...SKeen-v3.6.2) (2026-01-24)


### 🐛 Fix

* remove 24kc_24kf cpu from mips arch ([87c7e66](https://github.com/jinndi/SKeen/commit/87c7e6681ff1bb1c7120e7ab1a69ffaea3829155))

## [3.6.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.6.0...SKeen-v3.6.1) (2026-01-24)


### 🐛 Fix

* case remove mips64le ([60d8fd6](https://github.com/jinndi/SKeen/commit/60d8fd61cb0bf9c9f0b006b7b75fa40ca1751a36))
* detect mipsel/mipsle/mips  architecture + CPU ([550430b](https://github.com/jinndi/SKeen/commit/550430ba9f8fd1881ed7b2dd785ffbc0caff8366))

## [3.6.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.5.4...SKeen-v3.6.0) (2026-01-24)


### 🚀 Feat

* support 64-bit MIPS and CPU-specific PKG_ARCH detection ([e978afd](https://github.com/jinndi/SKeen/commit/e978afde70b00f6f9f3b6557bebb5af69aa20246))

## [3.5.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.5.3...SKeen-v3.5.4) (2026-01-23)


### 🐛 Fix

* fix config saving when formatting with built-in sing-box command ([6f49348](https://github.com/jinndi/SKeen/commit/6f49348ff43636b1d493b906fa78c557b89345da))

## [3.5.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.5.2...SKeen-v3.5.3) (2026-01-23)


### 🧰 Chore

* Fixes and improvements ([93f5b45](https://github.com/jinndi/SKeen/commit/93f5b450e80e445739389bec95cfc37f76bfc463))
* logging stdout ([40a27ac](https://github.com/jinndi/SKeen/commit/40a27ac8881a5cd258148a462d98fcb43221fca6))

## [3.5.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.5.1...SKeen-v3.5.2) (2026-01-23)


### 🐛 Fix

* improve SINGBOX start/stop handling and rename config variables ([d092eb3](https://github.com/jinndi/SKeen/commit/d092eb3d785272c0a45484bc9720b748ac8eeef6))

## [3.5.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.5.0...SKeen-v3.5.1) (2026-01-23)


### 🐛 Fix

* apply firewall rules after router reboot ([8edac10](https://github.com/jinndi/SKeen/commit/8edac10428ea081e2f0d63ba7e90b3bee585c3df))

## [3.5.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.7...SKeen-v3.5.0) (2026-01-22)


### 🚀 Feat

* **cli:** add check, format, help commands ([a16dc10](https://github.com/jinndi/SKeen/commit/a16dc100b7520a95f7ae13e5ef030231ed770df9))


### 🐛 Fix

* **menu:** prevent stuck cursor and repeated input after Ctrl+C ([1e17855](https://github.com/jinndi/SKeen/commit/1e178557b96232ea93b43c60974082448cfb8ab7))


### 🧰 Chore

* fix typos and grammatical errors ([3d5c33b](https://github.com/jinndi/SKeen/commit/3d5c33b98b41cbbfe040ad57917e097716f4f689))

## [3.4.7](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.6...SKeen-v3.4.7) (2026-01-22)


### 🐛 Fix

* **firewall:** do not reload config when applying firewall rules ([8f024a7](https://github.com/jinndi/SKeen/commit/8f024a729fb9be9040625f2e4d5259cdcce4ce97))
* load configuration on restart from menu ([3b89a53](https://github.com/jinndi/SKeen/commit/3b89a537da2e132fb3d8baae0eafaef46fec4d1e))
* restore terminal echo on script exit to prevent input visibility loss ([8064bd0](https://github.com/jinndi/SKeen/commit/8064bd0e58330e830fa560ef6afdd829c00ed3cf))
* **shell:** make script safe with set -e -u ([4ae7cf7](https://github.com/jinndi/SKeen/commit/4ae7cf77a2b3d073d34c5b403326b2d6a65751f6))
* **shell:** validate IPv4 and IPv6 addresses and subnets safely ([051a4ca](https://github.com/jinndi/SKeen/commit/051a4ca965bf3f6948bd403a31e6b3d5cde3c182))


### 🛠 Refactor

* deduplicate add_output_rules ([afb6f90](https://github.com/jinndi/SKeen/commit/afb6f9021b5a15a80cb417c6d457d7c879c52bd8))

## [3.4.6](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.5...SKeen-v3.4.6) (2026-01-22)


### 🐛 Fix

* bump version ([0c4332f](https://github.com/jinndi/SKeen/commit/0c4332f40e24399f821f15673415e684e99bf6b6))

## [3.4.5](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.4...SKeen-v3.4.5) (2026-01-22)


### 📦 Build

* add minified skeen to release assets ([dcf670d](https://github.com/jinndi/SKeen/commit/dcf670d30634c55100978a882e0c5de6866d1074))

## [3.4.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.3...SKeen-v3.4.4) (2026-01-22)


### 🛠 Refactor

* update SKeen script ([8ef978c](https://github.com/jinndi/SKeen/commit/8ef978cdb5505d8e47f2e2da02af29c5b9fc6623))

## [3.4.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.2...SKeen-v3.4.3) (2026-01-22)


### 🐛 Fix

* wait ipv6 default route ([b1ae597](https://github.com/jinndi/SKeen/commit/b1ae5979255210d2f2b416ef708a00075236eacf))

## [3.4.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.1...SKeen-v3.4.2) (2026-01-22)


### 🐛 Fix

* unpack ipk file sing-box ([1542dbe](https://github.com/jinndi/SKeen/commit/1542dbe418014fa88b2e4fe1bc90e457e77ca177))


### 🧰 Chore

* add IPv6 support for firewall tests ([bae3f43](https://github.com/jinndi/SKeen/commit/bae3f4352707864b568c53b8d8b9b33ef0a98279))

## [3.4.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.0...SKeen-v3.4.1) (2026-01-21)


### 🐛 Fix

* apply CONNMARK to TPROXY networks ([aec7cfe](https://github.com/jinndi/SKeen/commit/aec7cfe1914043dfaa14a9cf2db6d24321db0360))

## [3.4.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.3.4...SKeen-v3.4.0) (2026-01-21)


### 🚀 Feat

* **cli:** add update, backup, restore and reset options (see README) ([3f8b78c](https://github.com/jinndi/SKeen/commit/3f8b78c709ce93a15881ca57b8641f76c4a3ac4a))


### 🧰 Chore

* **sing-box:** update default DNS and routing configs ([00aa71d](https://github.com/jinndi/SKeen/commit/00aa71dd3b97796140c42a6ca27b99458ac50a74))

## [3.3.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.3.3...SKeen-v3.3.4) (2026-01-20)


### 🐛 Fix

* update dependencies only after script update when triggered from menu ([e146a5c](https://github.com/jinndi/SKeen/commit/e146a5c593c2173c20d9e519573561baac624b3c))


### 🧰 Chore

* update logo to a compact version ([7538dbf](https://github.com/jinndi/SKeen/commit/7538dbf7dcc7e4ca24014d21a2ee420a92c24b37))

## [3.3.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.3.2...SKeen-v3.3.3) (2026-01-20)


### 🐛 Fix

* diagnostic firewall ([7342c30](https://github.com/jinndi/SKeen/commit/7342c3021a7a854aec05122e250a028fc8bc70f4))

## [3.3.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.3.1...SKeen-v3.3.2) (2026-01-20)


### 🧰 Chore

* miscellaneous fixes and minor improvements ([34a25e9](https://github.com/jinndi/SKeen/commit/34a25e94bd8b0f8d7869417327b33192706cfe6a))

## [3.3.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.3.0...SKeen-v3.3.1) (2026-01-20)


### 🐛 Fix

* after update SKeen install deps ([b00a923](https://github.com/jinndi/SKeen/commit/b00a923ec53299cd14650b2826c4e83ca451c567))

## [3.3.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.2.3...SKeen-v3.3.0) (2026-01-20)


### 🚀 Feat

* add check_deps option to verify all dependencies and install missing ones ([1642448](https://github.com/jinndi/SKeen/commit/16424481a6783cc4525b6b6ad071c15d58e6535d))
* add diagnostic option to check iptables rules for current operating mode ([1313acc](https://github.com/jinndi/SKeen/commit/1313accb6fb38839163c3bec37d1e07cb376a878))

## [3.2.3](https://github.com/jinndi/SKeen/compare/SKeen-v3.2.2...SKeen-v3.2.3) (2026-01-20)


### 🐛 Fix

* **iptables:** corrected application of interception and port exclusion rules ([b4a1bf7](https://github.com/jinndi/SKeen/commit/b4a1bf70176de110be35b1d5f313f346323e6563))
* removed script exit after failed internet connectivity checks on autostart ([2d4339b](https://github.com/jinndi/SKeen/commit/2d4339baa6aae73128ef2da3cf0163a720b8f496))

## [3.2.2](https://github.com/jinndi/SKeen/compare/SKeen-v3.2.1...SKeen-v3.2.2) (2026-01-20)


### 🐛 Fix

* error applying DNS rules during router reboot ([0a42995](https://github.com/jinndi/SKeen/commit/0a429952bde34aa7f388ce658bef4ba0a446a5d4))

## [3.2.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.2.0...SKeen-v3.2.1) (2026-01-19)


### 🐛 Fix

* **firewall:** create OUTPUT chain to handle local TProxy traffic ([06ca4b2](https://github.com/jinndi/SKeen/commit/06ca4b2986f3dd7b76e3ee94650f886916f7b0e9))

## [3.2.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.1.1...SKeen-v3.2.0) (2026-01-18)


### 🚀 Feat

* **firewall:** check if iptables owner module is available ([000a447](https://github.com/jinndi/SKeen/commit/000a447c2435ea10085f32344d15e17b670398bc))
* **firewall:** safely clean custom chains and routes ([38f4de1](https://github.com/jinndi/SKeen/commit/38f4de1545ef3c6af4e63b83f1ef95edcd168ec5))
* **firewall:** validate and normalize ports list for prerouting rules (INTERCEPT_PORTS + EXCLUDE_PORTS) ([22c2723](https://github.com/jinndi/SKeen/commit/22c27239cd9a9ca94b6657c710f542b3f929e828))
* **firewall:** validate user-provided exclude addresses ([8c07808](https://github.com/jinndi/SKeen/commit/8c07808efe8c874096580236e49419888277b560))


### 🛠 Refactor

* create routes and verify default route ([644d0e4](https://github.com/jinndi/SKeen/commit/644d0e458f7c64d02032d1688c7a3aca6624a192))
* loading modules ([b93ec73](https://github.com/jinndi/SKeen/commit/b93ec73f552c5a3a5e150b61d2160653e333e48b))

## [3.1.1](https://github.com/jinndi/SKeen/compare/SKeen-v3.1.0...SKeen-v3.1.1) (2026-01-17)


### 🐛 Fix

* echomsg style ([392f4a3](https://github.com/jinndi/SKeen/commit/392f4a38d920fdb9a773277ab421e68a931ed529))
* import var from FIREWALL_HOOK_FILE ([b561b22](https://github.com/jinndi/SKeen/commit/b561b2255321f03a3ed90678f83a19c1ca02feef))
* printf ([73c495f](https://github.com/jinndi/SKeen/commit/73c495fddcc4d48ea666cc54c323c63da001203b))
* Removing auto-start script ([f9e128e](https://github.com/jinndi/SKeen/commit/f9e128e5bea739a589928680339528c59c21bd31))
* wait input ([598ae68](https://github.com/jinndi/SKeen/commit/598ae68892feeaf47c6257187cc6ac2756923671))
* wait_input /dev/tty ([ab7736b](https://github.com/jinndi/SKeen/commit/ab7736b4368a8993d2a76416b5eaa24dafebe471))

## [3.1.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.0.0...SKeen-v3.1.0) (2026-01-16)


### 🚀 Feat

* add checks for whether firewall rules need updating in the netfilter.d hook ([3b02938](https://github.com/jinndi/SKeen/commit/3b0293865b4c5fd10461c824922629814ed79c10))


### 🐛 Fix

* create FIREWALL_HOOK_FILE ([9bc535e](https://github.com/jinndi/SKeen/commit/9bc535e92133c05d694d9c10c2d9dd70428f828f))
* exclude ipv6 DNS remove ([fad7751](https://github.com/jinndi/SKeen/commit/fad775177aa906cf83501b211330b3c316fa1af1))
* shellcheck warn ([09ea603](https://github.com/jinndi/SKeen/commit/09ea6036ce4cfa45d9af0c1c99788ab4d56f5dff))


### ⚙️ Config

* remove creating socks Proxy interface ([aca3bd3](https://github.com/jinndi/SKeen/commit/aca3bd37432f047ca58a742e143680070394f8aa))


### 🧰 Chore

* add fake-ip DNS to template configs ([02d6d5e](https://github.com/jinndi/SKeen/commit/02d6d5ed7cc9b6ae255e92327b6d7debb7a2734b))
* add menu info firewall + log styles ([59094fc](https://github.com/jinndi/SKeen/commit/59094fc525db25bfbc2f83f64226bbe72fe1891a))

## [3.0.0](https://github.com/jinndi/SKeen/compare/SKeen-v2.1.5...SKeen-v3.0.0) (2026-01-15)


### ⚠ BREAKING CHANGES

* implement firewall modes: tproxy, redirect, hybrid

### 🚀 Feat

* implement firewall modes: tproxy, redirect, hybrid ([4411bee](https://github.com/jinndi/SKeen/commit/4411bee1402ec133b8c75dc511603765d1326e99))


### 🐛 Fix

* start (CALLER) ([7f888c0](https://github.com/jinndi/SKeen/commit/7f888c0093e12b773ffba94ba16ec44b2223cdd1))


### 🧰 Chore

* preparing for redirect mode and TProxy ([e8b2838](https://github.com/jinndi/SKeen/commit/e8b283829d140c056654d36befaf2f36c4f45a02))

## [2.1.5](https://github.com/jinndi/SKeen/compare/SKeen-v2.1.4...SKeen-v2.1.5) (2026-01-11)


### 🐛 Fix

* commands if not installed script ([ca9b112](https://github.com/jinndi/SKeen/commit/ca9b11236a887228750c5ed6ad332aed3e152978))

## [2.1.4](https://github.com/jinndi/SKeen/compare/SKeen-v2.1.3...SKeen-v2.1.4) (2026-01-11)


### 🐛 Fix

* start/stop use start-stop-daemon ([6ce75df](https://github.com/jinndi/SKeen/commit/6ce75df813fa1988b5536c7bea5bcbb59304310e))


### 🛠 Refactor

* var names ([2e7b024](https://github.com/jinndi/SKeen/commit/2e7b02447ec0e6c1ca5f80367cdc8dcb1fffef9c))

## [2.1.3](https://github.com/jinndi/SKeen/compare/SKeen-v2.1.2...SKeen-v2.1.3) (2026-01-10)


### 🐛 Fix

* exit ([20ed12c](https://github.com/jinndi/SKeen/commit/20ed12cb07b081f83dc32b47b35967dcd716dc00))


### 🧰 Chore

* refactor autostart/start/stop/restart, added settings.conf file and commands info in README ([2917b93](https://github.com/jinndi/SKeen/commit/2917b934c190a98fe2918f37a0d8eeeb8b6bae2b))

## [2.1.2](https://github.com/jinndi/SKeen/compare/SKeen-v2.1.1...SKeen-v2.1.2) (2026-01-09)


### 🐛 Fix

* prevent script hanging in background and high CPU usage ([a3f1dcc](https://github.com/jinndi/SKeen/commit/a3f1dcce8f5cc12102e90bbeb354befcf4cba1c7))

## [2.1.1](https://github.com/jinndi/SKeen/compare/SKeen-v2.1.0...SKeen-v2.1.1) (2026-01-09)


### 🐛 Fix

* update version SKeen ([f8cbf28](https://github.com/jinndi/SKeen/commit/f8cbf28f06930f94c02add001b42d33d868f20c3))

## [2.1.0](https://github.com/jinndi/SKeen/compare/SKeen-v2.0.1...SKeen-v2.1.0) (2026-01-09)


### 🚀 Feat

* update SKeen script, check config before starting/restarting sing-box, and other improvements ([15a81dd](https://github.com/jinndi/SKeen/commit/15a81dd385d603196fb87952b808119cedf9ffed))


### 🐛 Fix

* color printf ([40659bd](https://github.com/jinndi/SKeen/commit/40659bd7b1a41d990daa7a339a287a46a98486e1))


### 🧰 Chore

* **fix:** exit on get_latest_version, rename sing-box bin file and run directory ([d22b754](https://github.com/jinndi/SKeen/commit/d22b754d652f643f02798f13ca0ea19c42abc75b))

## [2.0.1](https://github.com/jinndi/SKeen/compare/SKeen-v2.0.0...SKeen-v2.0.1) (2026-01-08)


### 🐛 Fix

* path INIT_SCRIPT_DISABLE ([00e0472](https://github.com/jinndi/SKeen/commit/00e0472332eddce18510f85b35c2cbef6a8f78fb))
* skeen paths on example_config.json ([662a9b1](https://github.com/jinndi/SKeen/commit/662a9b1bc50369519c2b187ac0a7490afa5661ab))
* uninstall SKeen dir ([b34c2cd](https://github.com/jinndi/SKeen/commit/b34c2cdbf7f2627c440c2eb80780df97121bf420))
