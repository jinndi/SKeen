# Changelog

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
