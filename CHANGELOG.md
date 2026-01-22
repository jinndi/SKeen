# Changelog

## [4.0.1](https://github.com/jinndi/SKeen/compare/SKeen-v4.0.0...SKeen-v4.0.1) (2026-01-22)


### 🐛 Fix

* test ([e3810bf](https://github.com/jinndi/SKeen/commit/e3810bf38c272088ff308c5242460363de3f0165))

## [4.0.0](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.4...SKeen-v4.0.0) (2026-01-22)


### ⚠ BREAKING CHANGES

* implement firewall modes: tproxy, redirect, hybrid
* change repo name

### 🚀 Feat

* add check_deps option to verify all dependencies and install missing ones ([1642448](https://github.com/jinndi/SKeen/commit/16424481a6783cc4525b6b6ad071c15d58e6535d))
* add checks for whether firewall rules need updating in the netfilter.d hook ([3b02938](https://github.com/jinndi/SKeen/commit/3b0293865b4c5fd10461c824922629814ed79c10))
* add diagnostic option to check iptables rules for current operating mode ([1313acc](https://github.com/jinndi/SKeen/commit/1313accb6fb38839163c3bec37d1e07cb376a878))
* add function start, stop, restart singbox ([48df16b](https://github.com/jinndi/SKeen/commit/48df16b62de7e966e50c168cb0f825a259150f4c))
* check ndmc & skip create_sb_config ([4383d32](https://github.com/jinndi/SKeen/commit/4383d3287d2f69528490be75d0eb842f9af273bc))
* checking for updates option ([b14c14d](https://github.com/jinndi/SKeen/commit/b14c14dc555ff394a2b992fb4d3693002b41e06e))
* **cli:** add update, backup, restore and reset options (see README) ([3f8b78c](https://github.com/jinndi/SKeen/commit/3f8b78c709ce93a15881ca57b8641f76c4a3ac4a))
* Enabling/disabling autostart together with starting and stopping sing-box from the control script. ([80955ef](https://github.com/jinndi/SKeen/commit/80955ef6eed6da239cd2aee643574370327ee99a))
* **firewall:** check if iptables owner module is available ([000a447](https://github.com/jinndi/SKeen/commit/000a447c2435ea10085f32344d15e17b670398bc))
* **firewall:** safely clean custom chains and routes ([38f4de1](https://github.com/jinndi/SKeen/commit/38f4de1545ef3c6af4e63b83f1ef95edcd168ec5))
* **firewall:** validate and normalize ports list for prerouting rules (INTERCEPT_PORTS + EXCLUDE_PORTS) ([22c2723](https://github.com/jinndi/SKeen/commit/22c27239cd9a9ca94b6657c710f542b3f929e828))
* **firewall:** validate user-provided exclude addresses ([8c07808](https://github.com/jinndi/SKeen/commit/8c07808efe8c874096580236e49419888277b560))
* implement firewall modes: tproxy, redirect, hybrid ([4411bee](https://github.com/jinndi/SKeen/commit/4411bee1402ec133b8c75dc511603765d1326e99))
* update SKeen script, check config before starting/restarting sing-box, and other improvements ([15a81dd](https://github.com/jinndi/SKeen/commit/15a81dd385d603196fb87952b808119cedf9ffed))


### 🐛 Fix

* "$INIT_SCRIPT" start | restart ([d7d7422](https://github.com/jinndi/SKeen/commit/d7d74220e0e3626434be77182690d3c4456008bf))
* after update SKeen install deps ([b00a923](https://github.com/jinndi/SKeen/commit/b00a923ec53299cd14650b2826c4e83ca451c567))
* apply CONNMARK to TPROXY networks ([aec7cfe](https://github.com/jinndi/SKeen/commit/aec7cfe1914043dfaa14a9cf2db6d24321db0360))
* color printf ([40659bd](https://github.com/jinndi/SKeen/commit/40659bd7b1a41d990daa7a339a287a46a98486e1))
* commands if not installed script ([ca9b112](https://github.com/jinndi/SKeen/commit/ca9b11236a887228750c5ed6ad332aed3e152978))
* CPU model detection ([f35464f](https://github.com/jinndi/SKeen/commit/f35464f2597003799fa1ed52117f381bddcd7c7b))
* create FIREWALL_HOOK_FILE ([9bc535e](https://github.com/jinndi/SKeen/commit/9bc535e92133c05d694d9c10c2d9dd70428f828f))
* diagnostic firewall ([7342c30](https://github.com/jinndi/SKeen/commit/7342c3021a7a854aec05122e250a028fc8bc70f4))
* drop armv6/armv7 support, improve MIPS endian detection ([0140dfc](https://github.com/jinndi/SKeen/commit/0140dfc8987b3dc7c1c7a1201f9fa8158b7c05ff))
* echomsg style ([392f4a3](https://github.com/jinndi/SKeen/commit/392f4a38d920fdb9a773277ab421e68a931ed529))
* error applying DNS rules during router reboot ([0a42995](https://github.com/jinndi/SKeen/commit/0a429952bde34aa7f388ce658bef4ba0a446a5d4))
* exclude ipv6 DNS remove ([fad7751](https://github.com/jinndi/SKeen/commit/fad775177aa906cf83501b211330b3c316fa1af1))
* exit ([20ed12c](https://github.com/jinndi/SKeen/commit/20ed12cb07b081f83dc32b47b35967dcd716dc00))
* **firewall:** create OUTPUT chain to handle local TProxy traffic ([06ca4b2](https://github.com/jinndi/SKeen/commit/06ca4b2986f3dd7b76e3ee94650f886916f7b0e9))
* import var from FIREWALL_HOOK_FILE ([b561b22](https://github.com/jinndi/SKeen/commit/b561b2255321f03a3ed90678f83a19c1ca02feef))
* **iptables:** corrected application of interception and port exclusion rules ([b4a1bf7](https://github.com/jinndi/SKeen/commit/b4a1bf70176de110be35b1d5f313f346323e6563))
* path INIT_SCRIPT_DISABLE ([00e0472](https://github.com/jinndi/SKeen/commit/00e0472332eddce18510f85b35c2cbef6a8f78fb))
* Press any key to start installation ([8e7bdb0](https://github.com/jinndi/SKeen/commit/8e7bdb0c5572a1efd09a81ee659e5d56428f0b09))
* prevent script hanging in background and high CPU usage ([a3f1dcc](https://github.com/jinndi/SKeen/commit/a3f1dcce8f5cc12102e90bbeb354befcf4cba1c7))
* printf ([73c495f](https://github.com/jinndi/SKeen/commit/73c495fddcc4d48ea666cc54c323c63da001203b))
* printf ([50f8ef2](https://github.com/jinndi/SKeen/commit/50f8ef202e3b3cebef90701f33bccdc90b61913d))
* printf ([c324265](https://github.com/jinndi/SKeen/commit/c32426572bf38ad864f3ac5aa48ba6ace979d5fb))
* printf ([ba3e443](https://github.com/jinndi/SKeen/commit/ba3e443b02ff4742dbdb1ab82cbc00eedf9c4f57))
* read option ([535b65d](https://github.com/jinndi/SKeen/commit/535b65dd35f81e46f6c2c32110332c9a63b4e816))
* release-please-action ([22a95c6](https://github.com/jinndi/SKeen/commit/22a95c6d246118699076f22c82dc29e6dd9a6116))
* removed script exit after failed internet connectivity checks on autostart ([2d4339b](https://github.com/jinndi/SKeen/commit/2d4339baa6aae73128ef2da3cf0163a720b8f496))
* Removing auto-start script ([f9e128e](https://github.com/jinndi/SKeen/commit/f9e128e5bea739a589928680339528c59c21bd31))
* shellcheck warn ([09ea603](https://github.com/jinndi/SKeen/commit/09ea6036ce4cfa45d9af0c1c99788ab4d56f5dff))
* skeen paths on example_config.json ([662a9b1](https://github.com/jinndi/SKeen/commit/662a9b1bc50369519c2b187ac0a7490afa5661ab))
* start (CALLER) ([7f888c0](https://github.com/jinndi/SKeen/commit/7f888c0093e12b773ffba94ba16ec44b2223cdd1))
* start_singbox & restart_singbox ([6273eb0](https://github.com/jinndi/SKeen/commit/6273eb0db4b70adbfa5baad387e06639b98d27e7))
* start/stop use start-stop-daemon ([6ce75df](https://github.com/jinndi/SKeen/commit/6ce75df813fa1988b5536c7bea5bcbb59304310e))
* trap - INT QUIT HUP on exit error ([4dcab65](https://github.com/jinndi/SKeen/commit/4dcab65f638232a7e4351ed1bca69701c708a34d))
* trap & Removing proxy interface Proxy0 ([d6adaa5](https://github.com/jinndi/SKeen/commit/d6adaa544cbd005819db5dfb0c4d9f2d8c38dc01))
* uninstall function ([8a2ba02](https://github.com/jinndi/SKeen/commit/8a2ba023355f118721acdce85e10fa6c96a18494))
* uninstall SKeen dir ([b34c2cd](https://github.com/jinndi/SKeen/commit/b34c2cdbf7f2627c440c2eb80780df97121bf420))
* uninstall stop_singbox ([4bdea58](https://github.com/jinndi/SKeen/commit/4bdea580723da63be87c7920c3063c8a6a3f954d))
* unpack ipk file sing-box ([1542dbe](https://github.com/jinndi/SKeen/commit/1542dbe418014fa88b2e4fe1bc90e457e77ca177))
* update dependencies only after script update when triggered from menu ([e146a5c](https://github.com/jinndi/SKeen/commit/e146a5c593c2173c20d9e519573561baac624b3c))
* update version SKeen ([f8cbf28](https://github.com/jinndi/SKeen/commit/f8cbf28f06930f94c02add001b42d33d868f20c3))
* wait input ([598ae68](https://github.com/jinndi/SKeen/commit/598ae68892feeaf47c6257187cc6ac2756923671))
* wait ipv6 default route ([b1ae597](https://github.com/jinndi/SKeen/commit/b1ae5979255210d2f2b416ef708a00075236eacf))
* wait_input /dev/tty ([ab7736b](https://github.com/jinndi/SKeen/commit/ab7736b4368a8993d2a76416b5eaa24dafebe471))


### 🛠 Refactor

* change repo name ([6789079](https://github.com/jinndi/SKeen/commit/67890791c42b7bb97645972d3204e6a44a7d236a))
* create routes and verify default route ([644d0e4](https://github.com/jinndi/SKeen/commit/644d0e458f7c64d02032d1688c7a3aca6624a192))
* loading modules ([b93ec73](https://github.com/jinndi/SKeen/commit/b93ec73f552c5a3a5e150b61d2160653e333e48b))
* start, stop, restart ([96f2f74](https://github.com/jinndi/SKeen/commit/96f2f74269d049d7c616533c9c3944e3daf6d7ac))
* update SKeen script ([b16d592](https://github.com/jinndi/SKeen/commit/b16d5921ed3b9fa2ca39c3c94ff7fb62a286738f))
* var names ([2e7b024](https://github.com/jinndi/SKeen/commit/2e7b02447ec0e6c1ca5f80367cdc8dcb1fffef9c))
* while function ([623b080](https://github.com/jinndi/SKeen/commit/623b0809ac5ba760ffc52bc9d37ee31d8699258f))


### 📦 Deps

* + release-please-action ([2835da1](https://github.com/jinndi/SKeen/commit/2835da15f0e2dc9d45c0d37b813da190a26c713d))


### ⚙️ Config

* remove creating socks Proxy interface ([aca3bd3](https://github.com/jinndi/SKeen/commit/aca3bd37432f047ca58a742e143680070394f8aa))


### 🧪 Test

* read -rp ([c528b5e](https://github.com/jinndi/SKeen/commit/c528b5e6d546578255b1f05ac6940059141f6177))
* test ([e3fb522](https://github.com/jinndi/SKeen/commit/e3fb5220d66a9bd71f8d0fb739ca6d3017b4135d))


### 🧰 Chore

* add fake-ip DNS to template configs ([02d6d5e](https://github.com/jinndi/SKeen/commit/02d6d5ed7cc9b6ae255e92327b6d7debb7a2734b))
* add IPv6 support for firewall tests ([bae3f43](https://github.com/jinndi/SKeen/commit/bae3f4352707864b568c53b8d8b9b33ef0a98279))
* add menu info firewall + log styles ([59094fc](https://github.com/jinndi/SKeen/commit/59094fc525db25bfbc2f83f64226bbe72fe1891a))
* curl connect timeout 10s ([0da64f2](https://github.com/jinndi/SKeen/commit/0da64f297fed4d0710d669e6561670f0407a3f71))
* **fix:** exit on get_latest_version, rename sing-box bin file and run directory ([d22b754](https://github.com/jinndi/SKeen/commit/d22b754d652f643f02798f13ca0ea19c42abc75b))
* **main:** release sing-box-keenetic 1.1.0 ([39843d1](https://github.com/jinndi/SKeen/commit/39843d10dfeca2d41ea37216f80c3728e906eef6))
* **main:** release sing-box-keenetic 1.1.0 ([bdf5c7e](https://github.com/jinndi/SKeen/commit/bdf5c7efb855a7ca9ce860411c1c7834f17f3338))
* **main:** release sing-box-keenetic 1.1.1 ([e173e53](https://github.com/jinndi/SKeen/commit/e173e535fcf195c76bb0576d766aec544f22d2bb))
* **main:** release sing-box-keenetic 1.1.1 ([9fbb9ff](https://github.com/jinndi/SKeen/commit/9fbb9ff8d6370881c70b11e810926b6c4467b638))
* **main:** release sing-box-keenetic 1.2.0 ([98e1130](https://github.com/jinndi/SKeen/commit/98e1130c6df3f09db651aabd17f4289d7d852254))
* **main:** release sing-box-keenetic 1.2.0 ([076cfc4](https://github.com/jinndi/SKeen/commit/076cfc48f02d9a98a49122b36d5c743b07a484de))
* **main:** release SKeen 2.0.0 ([b355b68](https://github.com/jinndi/SKeen/commit/b355b6882728d17ac94686a1b321d39600a49527))
* **main:** release SKeen 2.0.0 ([666ad4a](https://github.com/jinndi/SKeen/commit/666ad4a821d21f7ba4b25787541c59e5f2ae8dea))
* **main:** release SKeen 2.0.1 ([a8cc3e9](https://github.com/jinndi/SKeen/commit/a8cc3e90d7aec1a8e6cb6d42f0fd684943620722))
* **main:** release SKeen 2.0.1 ([9d4e4d5](https://github.com/jinndi/SKeen/commit/9d4e4d57798e1e8660278212e66ac071c67b403d))
* **main:** release SKeen 2.1.0 ([7c7e001](https://github.com/jinndi/SKeen/commit/7c7e00138695568d50605f8d146cbbebcd40d0c9))
* **main:** release SKeen 2.1.0 ([e8d3533](https://github.com/jinndi/SKeen/commit/e8d353395a64a09ec060fda1963761e6efcfb796))
* **main:** release SKeen 2.1.1 ([3941d0a](https://github.com/jinndi/SKeen/commit/3941d0a59c493d147fc868d1ecc4e197fbb8edec))
* **main:** release SKeen 2.1.1 ([31a0daa](https://github.com/jinndi/SKeen/commit/31a0daa96468aed4405ce4121e7d5f4daff2d17c))
* **main:** release SKeen 2.1.2 ([a661877](https://github.com/jinndi/SKeen/commit/a6618774bee968ab4abfa5adb799704456c8ede3))
* **main:** release SKeen 2.1.2 ([bad1ad4](https://github.com/jinndi/SKeen/commit/bad1ad44c88f47cf967710e3449e72580fdef79b))
* **main:** release SKeen 2.1.3 ([82a6192](https://github.com/jinndi/SKeen/commit/82a61929c383537c8116d195b3cd18de7ec2d18c))
* **main:** release SKeen 2.1.3 ([a623426](https://github.com/jinndi/SKeen/commit/a6234266bc65cbc635f2dd000244cf2fe6719a78))
* **main:** release SKeen 2.1.4 ([6d10031](https://github.com/jinndi/SKeen/commit/6d10031d1df1a58731a0255689514b7856e748ec))
* **main:** release SKeen 2.1.4 ([e913017](https://github.com/jinndi/SKeen/commit/e913017852f43fc8219e5d2500dba35fcb244c9c))
* **main:** release SKeen 2.1.5 ([7bb199e](https://github.com/jinndi/SKeen/commit/7bb199e87103ab6b6c0992b4ae0fe645bd14be35))
* **main:** release SKeen 2.1.5 ([1f995e1](https://github.com/jinndi/SKeen/commit/1f995e1d62c67980d2e5fa49759d6fc8fa8d744f))
* **main:** release SKeen 3.0.0 ([83444a6](https://github.com/jinndi/SKeen/commit/83444a69621c7a9151ecfa707a51950b51e1fd08))
* **main:** release SKeen 3.0.0 ([bb57455](https://github.com/jinndi/SKeen/commit/bb574550c904a320c6b0226d0037ff5e35c1cc89))
* **main:** release SKeen 3.1.0 ([17845a0](https://github.com/jinndi/SKeen/commit/17845a0e5cde071c988abea341b5e4b36c296563))
* **main:** release SKeen 3.1.0 ([7d5b21f](https://github.com/jinndi/SKeen/commit/7d5b21f49afe157f9dc8cb56458cf23e1d5a7bfc))
* **main:** release SKeen 3.1.1 ([7298245](https://github.com/jinndi/SKeen/commit/7298245706ad0ef5fec4b1664386d693c41c8fad))
* **main:** release SKeen 3.1.1 ([862f156](https://github.com/jinndi/SKeen/commit/862f156b259b08839b27cdb5bbba6f465737fa5a))
* **main:** release SKeen 3.2.0 ([8224f30](https://github.com/jinndi/SKeen/commit/8224f304f2dcf2244170d5210567594b68c4a056))
* **main:** release SKeen 3.2.0 ([2c21fdd](https://github.com/jinndi/SKeen/commit/2c21fdd7d0dc233a24248f56140640da12e5dc84))
* **main:** release SKeen 3.2.1 ([46b96c7](https://github.com/jinndi/SKeen/commit/46b96c74733dc8a9711d287d8bd3bd17c5e3a000))
* **main:** release SKeen 3.2.1 ([1857da9](https://github.com/jinndi/SKeen/commit/1857da9fdcefb82999bbadd23cff0769ce927f99))
* **main:** release SKeen 3.2.2 ([b711935](https://github.com/jinndi/SKeen/commit/b711935d48487d5120afc280f9ea48923a600001))
* **main:** release SKeen 3.2.2 ([c5df706](https://github.com/jinndi/SKeen/commit/c5df7060c9c3496015ec8cd02b0132ef002e3506))
* **main:** release SKeen 3.2.3 ([b3033c5](https://github.com/jinndi/SKeen/commit/b3033c5a92351aafdd01473989559244411f7ba7))
* **main:** release SKeen 3.2.3 ([ccd51d0](https://github.com/jinndi/SKeen/commit/ccd51d07314187802ce93bd89666ca821b287b22))
* **main:** release SKeen 3.3.0 ([b957f23](https://github.com/jinndi/SKeen/commit/b957f23c1c53e8f10164b1253eff8adac5c4aa1c))
* **main:** release SKeen 3.3.0 ([6cfcb27](https://github.com/jinndi/SKeen/commit/6cfcb2766616c43aa85c42ed8874b3f05971609e))
* **main:** release SKeen 3.3.1 ([089180f](https://github.com/jinndi/SKeen/commit/089180f8d7b64699f7e5310bc3d6a886b71100f4))
* **main:** release SKeen 3.3.1 ([68af806](https://github.com/jinndi/SKeen/commit/68af8063412aa50723595ec107e04af2cf8f4fb1))
* **main:** release SKeen 3.3.2 ([3b3cc2c](https://github.com/jinndi/SKeen/commit/3b3cc2c39b7cf5e24b7b476a83044648a0bca2eb))
* **main:** release SKeen 3.3.2 ([74fbbb8](https://github.com/jinndi/SKeen/commit/74fbbb81f91fe691ab43687490d6c41a9889b457))
* **main:** release SKeen 3.3.3 ([23c0f71](https://github.com/jinndi/SKeen/commit/23c0f7164f836a829193f796d81e43648d599d43))
* **main:** release SKeen 3.3.3 ([5d37094](https://github.com/jinndi/SKeen/commit/5d370946ab851081c0edf5c4b61bd353341a75e2))
* **main:** release SKeen 3.3.4 ([cb990e9](https://github.com/jinndi/SKeen/commit/cb990e9523221e224937b9e541a2d7d5807c7811))
* **main:** release SKeen 3.3.4 ([76ae5ef](https://github.com/jinndi/SKeen/commit/76ae5ef2f3934b54172cb6b9cffaf298d5c6b3d6))
* **main:** release SKeen 3.4.0 ([3918e8d](https://github.com/jinndi/SKeen/commit/3918e8d1d810a2727861cd3711d3f7542bde9d7e))
* **main:** release SKeen 3.4.0 ([65d57cb](https://github.com/jinndi/SKeen/commit/65d57cb1ef493463d522b6fca11dedc066134706))
* **main:** release SKeen 3.4.1 ([cb4797d](https://github.com/jinndi/SKeen/commit/cb4797d6f9636c81f12c07fd2a81e7456fe5d9a7))
* **main:** release SKeen 3.4.1 ([de935d5](https://github.com/jinndi/SKeen/commit/de935d5a5918b0f04085c8fc59c5279e5f5473fd))
* **main:** release SKeen 3.4.2 ([0ada532](https://github.com/jinndi/SKeen/commit/0ada5322a45c2d8d761c487e707d5490513e7481))
* **main:** release SKeen 3.4.2 ([a4ebeda](https://github.com/jinndi/SKeen/commit/a4ebedadd390659d0632e77295debefedcf99c39))
* **main:** release SKeen 3.4.3 ([2e35b7f](https://github.com/jinndi/SKeen/commit/2e35b7fda9423bf3287b8e4dd1aab19c7c7e531d))
* **main:** release SKeen 3.4.3 ([983911b](https://github.com/jinndi/SKeen/commit/983911b1594829f4d481a651d19b95e2aef64d3b))
* **main:** release SKeen 3.4.4 ([2475346](https://github.com/jinndi/SKeen/commit/2475346d296e8ea9981749cb42a743c684612a06))
* **main:** release SKeen 3.4.4 ([b5f9adc](https://github.com/jinndi/SKeen/commit/b5f9adc6a66c24959b188e7b79dc5bdc526ae37e))
* miscellaneous fixes and minor improvements ([34a25e9](https://github.com/jinndi/SKeen/commit/34a25e94bd8b0f8d7869417327b33192706cfe6a))
* preparing for redirect mode and TProxy ([e8b2838](https://github.com/jinndi/SKeen/commit/e8b283829d140c056654d36befaf2f36c4f45a02))
* refactor autostart/start/stop/restart, added settings.conf file and commands info in README ([2917b93](https://github.com/jinndi/SKeen/commit/2917b934c190a98fe2918f37a0d8eeeb8b6bae2b))
* remove return ([ec43f60](https://github.com/jinndi/SKeen/commit/ec43f608e13ba46fe41c3491111476c99262ca72))
* **sing-box:** update default DNS and routing configs ([00aa71d](https://github.com/jinndi/SKeen/commit/00aa71dd3b97796140c42a6ca27b99458ac50a74))
* update logo to a compact version ([7538dbf](https://github.com/jinndi/SKeen/commit/7538dbf7dcc7e4ca24014d21a2ee420a92c24b37))

## [3.4.4](https://github.com/jinndi/SKeen/compare/SKeen-v3.4.3...SKeen-v3.4.4) (2026-01-22)


### 🛠 Refactor

* update SKeen script ([b16d592](https://github.com/jinndi/SKeen/commit/b16d5921ed3b9fa2ca39c3c94ff7fb62a286738f))

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
