# Architecture

> **Note:** The architecture is inspired by a [Chinese article](https://lhy.life/20231012-sing-box-tproxy/) on configuring a transparent proxy (TProxy).

## Redirect

Utilized in `redirect` (TCP) and `hybrid` (TCP) modes, as well as for router-level proxying.

The **skeen** `goto` chain is used in `PREROUTING` of the `nat` table. If the policy is enabled, entry into it is handled via `connmark match`.

Workflow Algorithm:

**Directional Filtering (REPLY optimization)**
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**Excluded Ports**
  * `match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied, traffic is either sent directly or continues for further checks.

**Address Bypass**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Excluded FakeIP**
  * `! match-set skeen_fakeip_set4 dst ACCEPT`
  * If the Sing-box DNS module is configured and enabled, this allows building routing based on it within the `PREROUTING` chain.
  * **Essence:** We bypass the Sing-box core and allow traffic directly to FakeIP addresses (`198.18.0.0/15` and `fc00::/18`), as well as those specified in the file defined by the `firewall.intercept.fakeip.include` path, to speed up routing.

**Connection Marking**
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x12` mark is applied only to new connections (`NEW`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.

**TCP Redirect Hijack**
  * `connmark match 0x12 REDIRECT`
  * **Essence:** Final stretch. All remaining TCP traffic is forcibly redirected to the local Sing-Box port. Unlike TProxy, this uses classic NAT-based port redirection.

## TProxy

Utilized in `tproxy` (TCP & UDP) and `hybrid` (UDP) modes, as well as for router-level proxying.

The **skeen** `goto` chain is used in `PREROUTING` of the `mangle` table. If the policy is enabled, entry into it is handled via `connmark match`.

Workflow Algorithm:

**Socket Fast Path (TCP)**
  * `match socket --transparent` -> `MARK set 0x12 + ACCEPT`
  * **Essence:** Speed-up magic. If the system already has an open transparent socket for the packet, we simply apply a mark and pass it directly to the socket, bypassing heavy checks.

**Directional Filtering (REPLY optimization)**
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**DNS TProxy**
  * `tcp/udp dpt:53 TPROXY`
  * **Essence:** Intercept DNS requests on the fly and send them directly to the Sing-Box TProxy port. Works if `firewall.redirect_dns` is not enabled in the `skeen.json` config; otherwise just `ACCEPT` to let packets continue through the tables.

**Excluded Ports**
  * `tcp/udp match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied, traffic is either sent directly or continues for further checks.

**Address Bypass**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Excluded FakeIP**
  * `! match-set skeen_fakeip_set4 dst ACCEPT`
  * If the Sing-box DNS module is configured and enabled, this allows building routing based on it within the `PREROUTING` chain.
  * **Essence:** We bypass the Sing-box core and allow traffic directly to FakeIP addresses (`198.18.0.0/15` and `fc00::/18`), as well as those specified in the file defined by the `firewall.intercept.fakeip.include` path, to speed up routing.

**Connection Marking**
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x12` mark is applied only to new connections (`NEW`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.

**Final TProxy Hijack**
  * `connmark match 0x12 TPROXY / TPROXY`
  * **Essence:** Final stage. All remaining TCP/UDP traffic that did not match any exclusions is forcibly redirected to the Sing-Box TProxy port.

> **Note:** Local subnets (listed in the source code) are already excluded from proxying. However, if you need to exclude specific, you must specify them manually in `skeen.json` or within the `sing-box` configuration itself.

## Hybrid

Utilizes combined rules for router proxying: `redirect` (TCP) and `tproxy` (UDP).

## Router Proxying

`OUTPUT` chains named **skeen_mask** are created in both `nat` and `mangle` tables, depending on the firewall mode and router proxying settings.

> Please note that the chain unconditionally affects all outgoing traffic generated by the router itself, except for `sing-box`. This means you should take this into account when using this feature alongside other proxy tools.

Instead of filtering by router policies, it filters processes that do not belong to the `skeen` group (to prevent routing loops). The rules are applied in the following order:

1. `redirect` mode, `nat` table in `OUTPUT` named `skeen_mask`: mirrors the logic of the Redirect **skeen** chain.
2. `tproxy` mode, `mangle` table in `OUTPUT` named `skeen_mask`. Logic flow:

**Anti-Loop (GID skeen)**
  * `owner GID match skeen ACCEPT`
  * **Core Logic:** If the packet was generated by `sing-box` itself, it is bypassed and sent directly to the WAN. Without this rule, the router would fall into an infinite routing loop.

**Directional Filtering (REPLY optimization)**
  * `ctdir REPLY ACCEPT` - Instantly bypasses all incoming response traffic. This ensures maximum download speeds and minimal latency by focusing only on outgoing requests.

**DNS Hijack (Port 53)**
  * `tcp/udp dpt:53 MARK set 0x12` + `ACCEPT`
  * **Core Logic:** If the router itself attempts a DNS resolution, we apply the `0x12` mark. This triggers a kernel "reroute check" to send the request to Sing-Box. Note: the mark is applied only if `firewall.redirect_dns` is not set in `skeen.json`; otherwise, it performs a simple `ACCEPT` without marking.

**Excluded Ports**
  * `tcp/udp match-set skeen_exclude_port dst ACCEPT`
  * **Essence:** If ports are specified in `skeen.json` that should not be proxied, traffic is either sent directly or continues for further checks.

**Address Bypass**
  * `match-set skeen_exclude_net4 dst ACCEPT`
  * **Essence:** Ignore the router’s local network, reserved subnets, and the user-defined IP whitelist. Packets to these resources bypass the proxy.

**Connection Marking**
  * Instead of analyzing every single packet, SKeen "remembers" the decision for the entire session:
  * **TCP:** The `0x12` mark is applied only to new connections (`NEW`). This saves CPU resources because the kernel does not have to re-evaluate rules for every packet within an established stream.

**Catch-all (MARK)**
  * `connmark match 0x12 MARK / MARK` - Marks everything that didn't match the lists above.
  * **Outcome:** All other router-generated traffic (updates, utilities, scripts) is diverted to routing table 12, and subsequently to TProxy.

> **How it works internally:**
> When a packet receives `MARK 0x12` in `OUTPUT`, the kernel performs a **Reroute Check**. It sees the `ip rule from all fwmark 0x12 lookup 12` rule and routes the packet to the loopback interface (`lo`). In `PREROUTING`, the **skeen** chain is already waiting for it with a `mark match 0x12` entry rule, which applies the final `TPROXY` to the Sing-Box port. `REDIRECT` occurs directly within the **skeen_mask** `OUTPUT` chain; there is no separate chain for it in `PREROUTING`.

3. `hybrid` mode utilizes combined rules for router proxying: `redirect` (TCP) and `tproxy` (UDP).
4. In other modes, the `service_proxy` option can be configured in `skeen.json`, specifically for Sing-Box updates, SKeen script, and configuration synchronization via `skeen sync`.
