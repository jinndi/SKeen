# sing-box channels and installation options

During SKeen installation, you can choose the official `sing-box`, a compatible build, or skip installation and provide your own binary. The `update.singbox.channel` setting in `skeen.json` selects the release source for SKeen's bundled core and is used by its installation, update, and update-check flows. Values in the table match the options offered by the SKeen installer.

| Channel value | Project / release repository | Options and notes |
| :--- | :--- | :--- |
| `official` | [SagerNet/sing-box](https://github.com/SagerNet/sing-box) | Official build. Stable and pre-release (alpha/beta/rc) versions are available. |
| `skb` | [jinndi/skeen-box](https://github.com/jinndi/skeen-box) | Build based on official sing-box without extra build tags, intended for routers. Stable and pre-release versions are available. |
| `skb-upx` | [jinndi/skeen-box](https://github.com/jinndi/skeen-box) | Same `skeen-box` core, compressed with UPX. Stable and pre-release versions are available. |
| `pdk` | [podkop-net/podkop-engine](https://github.com/podkop-net/podkop-engine) | Experimental build based on stable sing-box releases, basic package. Stable releases only. |
| `pdk-full` | [podkop-net/podkop-engine](https://github.com/podkop-net/podkop-engine) | Experimental build with the full package. Stable releases only. |
| `lx` | [Leadaxe/sing-box-lx](https://github.com/Leadaxe/sing-box-lx) | Experimental build based on stable sing-box releases. The installer offers stable and pre-release channels. |
| `lx-upx` | [Leadaxe/sing-box-lx](https://github.com/Leadaxe/sing-box-lx) | Same `sing-box-lx` core, UPX variant for supported architectures. The installer offers stable and pre-release channels. |
| — | Custom binary | You can skip installation of the bundled core and configure a custom binary via `singbox.external` in [`skeen.json`](CONFIGURATION.md). Installation and updates are managed by the user; SKeen's automatic channel does not apply. |

Pre-release versions are controlled separately by the `update.singbox.beta` setting. `podkop-engine` only provides stable releases. UPX and architecture support depend on the selected build and router model; `lx-upx` does not provide a UPX package for MIPS.
