# Changelog

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

## [2.0.0](https://github.com/jinndi/sing-box-keenetic/compare/SKeen-v1.2.0...SKeen-v2.0.0) (2026-01-08)


### ⚠ BREAKING CHANGES

* change repo name

### 🚀 Feat

* add function start, stop, restart singbox ([48df16b](https://github.com/jinndi/sing-box-keenetic/commit/48df16b62de7e966e50c168cb0f825a259150f4c))
* check ndmc & skip create_sb_config ([4383d32](https://github.com/jinndi/sing-box-keenetic/commit/4383d3287d2f69528490be75d0eb842f9af273bc))
* checking for updates option ([b14c14d](https://github.com/jinndi/sing-box-keenetic/commit/b14c14dc555ff394a2b992fb4d3693002b41e06e))
* Enabling/disabling autostart together with starting and stopping sing-box from the control script. ([80955ef](https://github.com/jinndi/sing-box-keenetic/commit/80955ef6eed6da239cd2aee643574370327ee99a))


### 🐛 Fix

* "$INIT_SCRIPT" start | restart ([d7d7422](https://github.com/jinndi/sing-box-keenetic/commit/d7d74220e0e3626434be77182690d3c4456008bf))
* CPU model detection ([f35464f](https://github.com/jinndi/sing-box-keenetic/commit/f35464f2597003799fa1ed52117f381bddcd7c7b))
* drop armv6/armv7 support, improve MIPS endian detection ([0140dfc](https://github.com/jinndi/sing-box-keenetic/commit/0140dfc8987b3dc7c1c7a1201f9fa8158b7c05ff))
* Press any key to start installation ([8e7bdb0](https://github.com/jinndi/sing-box-keenetic/commit/8e7bdb0c5572a1efd09a81ee659e5d56428f0b09))
* printf ([50f8ef2](https://github.com/jinndi/sing-box-keenetic/commit/50f8ef202e3b3cebef90701f33bccdc90b61913d))
* printf ([c324265](https://github.com/jinndi/sing-box-keenetic/commit/c32426572bf38ad864f3ac5aa48ba6ace979d5fb))
* printf ([ba3e443](https://github.com/jinndi/sing-box-keenetic/commit/ba3e443b02ff4742dbdb1ab82cbc00eedf9c4f57))
* read option ([535b65d](https://github.com/jinndi/sing-box-keenetic/commit/535b65dd35f81e46f6c2c32110332c9a63b4e816))
* release-please-action ([22a95c6](https://github.com/jinndi/sing-box-keenetic/commit/22a95c6d246118699076f22c82dc29e6dd9a6116))
* start_singbox & restart_singbox ([6273eb0](https://github.com/jinndi/sing-box-keenetic/commit/6273eb0db4b70adbfa5baad387e06639b98d27e7))
* trap - INT QUIT HUP on exit error ([4dcab65](https://github.com/jinndi/sing-box-keenetic/commit/4dcab65f638232a7e4351ed1bca69701c708a34d))
* trap & Removing proxy interface Proxy0 ([d6adaa5](https://github.com/jinndi/sing-box-keenetic/commit/d6adaa544cbd005819db5dfb0c4d9f2d8c38dc01))
* uninstall function ([8a2ba02](https://github.com/jinndi/sing-box-keenetic/commit/8a2ba023355f118721acdce85e10fa6c96a18494))
* uninstall stop_singbox ([4bdea58](https://github.com/jinndi/sing-box-keenetic/commit/4bdea580723da63be87c7920c3063c8a6a3f954d))


### 🛠 Refactor

* change repo name ([6789079](https://github.com/jinndi/sing-box-keenetic/commit/67890791c42b7bb97645972d3204e6a44a7d236a))
* start, stop, restart ([96f2f74](https://github.com/jinndi/sing-box-keenetic/commit/96f2f74269d049d7c616533c9c3944e3daf6d7ac))
* while function ([623b080](https://github.com/jinndi/sing-box-keenetic/commit/623b0809ac5ba760ffc52bc9d37ee31d8699258f))


### 📦 Deps

* + release-please-action ([2835da1](https://github.com/jinndi/sing-box-keenetic/commit/2835da15f0e2dc9d45c0d37b813da190a26c713d))


### 🧪 Test

* read -rp ([c528b5e](https://github.com/jinndi/sing-box-keenetic/commit/c528b5e6d546578255b1f05ac6940059141f6177))


### 🧰 Chore

* curl connect timeout 10s ([0da64f2](https://github.com/jinndi/sing-box-keenetic/commit/0da64f297fed4d0710d669e6561670f0407a3f71))
* **main:** release sing-box-keenetic 1.1.0 ([39843d1](https://github.com/jinndi/sing-box-keenetic/commit/39843d10dfeca2d41ea37216f80c3728e906eef6))
* **main:** release sing-box-keenetic 1.1.0 ([bdf5c7e](https://github.com/jinndi/sing-box-keenetic/commit/bdf5c7efb855a7ca9ce860411c1c7834f17f3338))
* **main:** release sing-box-keenetic 1.1.1 ([e173e53](https://github.com/jinndi/sing-box-keenetic/commit/e173e535fcf195c76bb0576d766aec544f22d2bb))
* **main:** release sing-box-keenetic 1.1.1 ([9fbb9ff](https://github.com/jinndi/sing-box-keenetic/commit/9fbb9ff8d6370881c70b11e810926b6c4467b638))
* **main:** release sing-box-keenetic 1.2.0 ([98e1130](https://github.com/jinndi/sing-box-keenetic/commit/98e1130c6df3f09db651aabd17f4289d7d852254))
* **main:** release sing-box-keenetic 1.2.0 ([076cfc4](https://github.com/jinndi/sing-box-keenetic/commit/076cfc48f02d9a98a49122b36d5c743b07a484de))
* remove return ([ec43f60](https://github.com/jinndi/sing-box-keenetic/commit/ec43f608e13ba46fe41c3491111476c99262ca72))

## [1.2.0](https://github.com/jinndi/sing-box-keenetic/compare/sing-box-keenetic-v1.1.1...sing-box-keenetic-v1.2.0) (2026-01-08)


### 🚀 Feat

* checking for updates option ([b14c14d](https://github.com/jinndi/sing-box-keenetic/commit/b14c14dc555ff394a2b992fb4d3693002b41e06e))


### 🐛 Fix

* CPU model detection ([f35464f](https://github.com/jinndi/sing-box-keenetic/commit/f35464f2597003799fa1ed52117f381bddcd7c7b))
* trap - INT QUIT HUP on exit error ([4dcab65](https://github.com/jinndi/sing-box-keenetic/commit/4dcab65f638232a7e4351ed1bca69701c708a34d))


### 🧰 Chore

* curl connect timeout 10s ([0da64f2](https://github.com/jinndi/sing-box-keenetic/commit/0da64f297fed4d0710d669e6561670f0407a3f71))

## [1.1.1](https://github.com/jinndi/sing-box-keenetic/compare/sing-box-keenetic-v1.1.0...sing-box-keenetic-v1.1.1) (2026-01-08)


### 🐛 Fix

* drop armv6/armv7 support, improve MIPS endian detection ([0140dfc](https://github.com/jinndi/sing-box-keenetic/commit/0140dfc8987b3dc7c1c7a1201f9fa8158b7c05ff))

## [1.1.0](https://github.com/jinndi/sing-box-keenetic/compare/sing-box-keenetic-v1.0.0...sing-box-keenetic-v1.1.0) (2026-01-07)


### 🚀 Feat
* Enabling/disabling autostart together with starting and stopping sing-box from the control script. ([80955ef](https://github.com/jinndi/sing-box-keenetic/commit/80955ef6eed6da239cd2aee643574370327ee99a))

### 📦 Deps

* + release-please-action ([2835da1](https://github.com/jinndi/sing-box-keenetic/commit/2835da15f0e2dc9d45c0d37b813da190a26c713d))
