# FAQ

<details>
  <summary>1. Why sing-box?</summary>
<br>

**sing-box** is an open-source universal proxy engine written in Go. It is focused on maximum performance, low resource consumption, and support for the most modern protocols

**Comparison: Proxy Engines for Routers & Embedded**

|Feature                 |sing-box         |Xray              |mihomo          |
|------------------------|-----------------|------------------|----------------|
|Resource Usage (RAM/CPU)|✅ Minimal        |⚠️ Moderate       |❌ High          |
|Protocol Support        |✅ Advanced       |⚠️ Limited        |✅ Extensive     |
|Multiplexing            |✅ Superior       |⚠️ Legacy         |✅ Good          |
|DNS Logic               |🥇 Native (+Fake-IP)|🥉 Sniffing (+FakeDNS)|🥈 Fake-IP (+Real)|
|TUN efficiency          |✅ High           |⚠️ Basic          |⚠️ Basic         |
|L7 Sniffing (Protocols) |✅ Leader         |⚠️ Mid-tier       |❌ Domain-only   |
|Routing                 |✅ Flexible       |⚠️ Basic          |✅ (but heavier) |
|Rule Management         |✅ Rule-sets (bin)|⚠️ Geo-files (dat)|✅ Rule-providers|
|Independent Project     |✅ Yes            |❌ (V2Ray fork)    |❌ (Clash fork)  |
|Learning Curve          |🔴 High          |🟡 Moderate       |🟢 Low          |

Notes:

> sing-box excels due to its modularity and clean-slate architecture: its DNS stack enables complex configurations with minimal RAM overhead. In contrast, mihomo (Clash) prioritizes automation at the cost of high resource usage, while Xray is hindered by legacy networking code and heavy .dat geo-files.

> Sniffing Differences: sing-box and Xray utilize full DPI (Deep Packet Inspection), which allows them to identify the protocol type (e.g., BitTorrent) based on packet content. In contrast, mihomo is limited to metadata extraction (domains) from TLS/HTTP headers, making protocol-based routing impossible.

> The high learning curve of sing-box stems from its strict JSON schema and lack of "magic" defaults. This is a trade-off for granular control and peak performance on low-end hardware.
</details>

<details>
  <summary>2. Web UI?</summary>
<br>

💡 For flexible manual configuration, automation, and synchronization, use [Sub-Store-Docker](https://github.com/jinndi/Sub-Store-Docker) in a Docker container on a VPS or local host, or [Sub-Store-GUI](https://github.com/jinndi/sub-store-gui) on your PC.

A [synchronization plugin](https://github.com/jinndi/sync-profile-to-skeen) is also available, allowing you to import profiles via [GUI.for.SingBox](https://github.com/GUI-for-Cores/GUI.for.SingBox), although **Sub-Store is the preferred option**.

The project intentionally does not include a dedicated management panel. This approach offers several advantages for your router:

* **Resource Efficiency**: Not having a separate management panel saves RAM and reduces CPU overhead, leaving more resources for traffic routing.
* **Integration**: Management and monitoring are available through the sing-box API and router tools, without duplicating their functions in a separate panel.
* **Security and Stability**: Fewer continuously running services and components mean fewer potential points of failure and conflicts within the system.
* **Full Control**: Directly editing the configuration provides access to sing-box features without the limitations of simplified graphical interfaces. Implementing all these features as buttons requires developers to continually update and promptly maintain the panel.
- **Configuration Sync Priority**: Full sing-box configuration synchronization with support for advanced external tools such as Sub-Store.
* **No Constant Need**: In general, a separate management panel is not required: a correctly configured setup is created for specific tasks and usually does not need regular changes.
* **Focus on the Main Task**: SKeen is designed for transparent traffic forwarding and routing. For a network tool of this kind, a separate heavy management panel would generally be excessive.
</details>

<details>
  <summary>3. Architecture?</summary>
<br>

The description is provided in the [Architecture](docs/ARCHITECTURE.md) document.
</details>

<details>
<summary>4. ADGuard Home & DNS?</summary>
<br>

The DNS module in Sing-box is a core part of how it operates. It is used for:

- preventing DNS leaks;
- hiding DNS queries from your ISP;
- bypassing DNS-level blocking;
- flexible routing by rules.

Does ADGuard Home solve these problems?
Short answer - no.

ADGuard Home is primarily designed for filtering (ads, trackers).

Does Sing-box cover the functionality of ADGuard Home?
Yes - Sing-box also supports DNS filtering and can fully replace ADGuard Home.

What about deploying your own AdGuard Home on a VPS?

Domain blocking and resolution inside Sing-box are objectively better: requests are intercepted right on the router, never leaving for the external network or wasting time on it. Take Fake-IP alone-with it, everything works even faster: Sing-box processes such requests locally, bypassing external DNS resolution entirely.

The Sing-box + web interface stack fully covers all needs for speed, analytics, and routing-level blocking. Adding AdGuard Home on a VPS to this chain is an unnecessary complication of the infrastructure and a potential single point of failure.

**Why Encrypted DNS (DoH/DoT) Inside a Proxy Tunnel is Essential**

Even if the proxy server sees the destination IP address when establishing a connection, routing encrypted DNS (DoH/DoT) inside an encrypted proxy tunnel remains a fundamental security requirement. It ensures strict separation of duties, data integrity, and protection against traffic analysis—regardless of the underlying proxy protocol.

1. Protection Against Tampering (Data Integrity)

When using plain, unencrypted DNS (Plain UDP/53), the hosting provider or any transit node between the proxy server and the DNS resolver can intercept and forge DNS responses (**DNS Spoofing / MITM**).
* **Risk:** You request a banking website IP, and an intermediary node spoofs the response, directing your traffic to a phishing server.
* **DoH/DoT Solution:** Encryption is established directly from the local client to the public resolver (Cloudflare, Google, AdGuard) with TLS certificate verification. The proxy server and intermediate networks are physically unable to modify the returned IP address.

2. Concealment Behind Shared IPs & CDNs (Privacy)

Modern web infrastructure relies heavily on CDN networks (Cloudflare, Fastly, Akamai). A single IP address often serves tens of thousands of independent websites simultaneously.
* **Without DoH:** The proxy server sees the destination IP and the plain-text DNS query (`target-site.com`). The server knows precisely which domain you are visiting.
* **With DoH:** The DNS query is fully encrypted. The proxy server only observes a connection attempt to an anonymized IP address (e.g., `104.21.32.1`). It cannot determine which specific site behind that IP is being accessed.

3. Zero-Trust Architecture

Remote server infrastructure should not be trusted with the ability to inspect, log, or filter your DNS activity.
* **Outcome:** Wrapping DoH/DoT inside the tunnel reduces the proxy server to a **"dumb L4 pipe."** The server merely relays encrypted packets, leaving it with zero technical capability to log visited domain names or manipulate the resolution process.

So, we've established that configuring DNS inside Sing-box is essential for safe and stable operation (provided it is set up correctly). But what about the DNS settings on the router itself?

My recommendations are as follows: the main rule is to use 100% working servers in your country (for example, Yandex DNS for Russia) and specify no more than two addresses. Beyond that, it doesn't matter whether it's DoH or DoT-this task should be handled by Sing-box itself, so even a standard DNS from your ISP will do fine. It also doesn't matter if "DNS Transit" is enabled-it literally changes nothing at all.
</details>

<details>
  <summary>5. FakeIP?</summary>
<br>

The following are intentionally **excluded** from the bypass list (local network exceptions):

1.  **Subnet `198.18.0.0/15`**
    In the script, the `198.18.0.0/15` line is commented out. This means traffic to Sing-Box FakeIP addresses will be intercepted and processed by the kernel as intended. This is a deliberate design choice for proper routing.

2.  **Subnet `fc00::/18`**
    The IPv6 segment `fc00::/18` (Sing-Box Fake-IP range for IPv6) is also excluded from the bypass list for the same reason.

</details>

<details>
  <summary>6. Installation to internal memory?</summary>
<br>

This is highly discouraged. From a manufacturer's perspective, this is a sure way to wear out your device's memory faster, forcing an early replacement. This option will never be added to SKeen; however, nothing stops you from skipping the **sing-box** installation and using your own binary.

</details>

<details>
  <summary>7. Multi-WAN Mode?</summary>
<br>

When Multi-WAN is enabled, sing-box's own outbound traffic may "hop" between different providers. Since most proxy protocols (VLESS, VMess, Shadowsocks) are highly sensitive to client IP changes within a single session, the connection becomes extremely unstable. For proper operation, you must strictly bind sing-box to a single internet channel.

An example of how to bind a connection to a specific interface can be found in the `examples/basic/` folder, in the `multi-interface-routing.json` file.

> **Note:** Selecting a provider in the SKeen policy has no effect by default without setting a policy mark in the routing or within the **outbounds** of the **sing-box** configuration. You can select any connection, but be aware: by default, the internet gateway specified in the default policy will be used, unless you have bound all or selected connections (**outbound**) to a specific interface.

**Question:** Why is the option to choose a provider missing from the router policies?

**Answer:** Routing is managed solely within the sing-box configuration. In the event that the primary provider fails, failover to the backup channel is disabled. This is intentional for your security to guarantee entirely predictable behavior.
</details>

<details>
  <summary>8. KeenDNS in TProxy mode?</summary>
<br>

If you have disabled internet access to your subdomain in the "Domain Name" section of the control panel, then to access **KeenDNS** from the local network in **TProxy** mode, you need to configure a `hosts` or `local` type DNS server in the sing-box configuration (see configuration examples in the `examples/basic/keendns-tproxy-local-access.json file`). If internet access is allowed, no additional.

**Note:** Freeing up port 443 is absolutely not required for TProxy to work.

> **Note:** Changing the HTTPS port in the web interface takes effect only after a subsequent router reboot. This is unrelated to SKeen and is a known bug in the firmware itself.

</details>

<details>
  <summary>9. Routing by DSCP?</summary>
<br>

**This feature is not and will not be available in SKeen.**

Reasons why:

* **Breaks HW NAT:** Checking DSCP tags in iptables forces the router to inspect every single packet on the CPU. This completely disables hardware acceleration (PPE/HNAT) for all of the client's connections, tanking your overall internet speed.
* **Windows Quirks:** The Windows network stack regularly resets DSCP tags after OS updates or network profile changes (via NLA).
* **Incompatibility:** It is technically impossible to configure application-level DSCP tagging on mobile devices (iOS/Android) or Smart TVs.
* **ISPs Strip Tags:** Attempting to send packets with DSCP tags to your ISP can lead to unpredictable latency, packet loss, and traffic deprioritization on their end.

**Q:** What should I do instead?

**A:**

1. Learn how to build routing using Sing-box rules, and use FakeIP to filter traffic.
2. Install a graphical sing-box client for Windows (SFW) or Linux (SFL) and configure full routing with process-based rules using the [base template for Sub-Store](../examples/sub-store/templates/desktop.json).
</details>

<details>
  <summary>10. Memory Usage?</summary>
<br>

If using protocols like VLESS or Trojan in TPROXY mode with 60 active connections and standard routing templates (over 200,000 domains for DNS and routing), Zashboard shows the following metrics:

<img width="541" height="196" alt="5656" src="https://github.com/user-attachments/assets/74d196db-baf7-4f13-b104-ba47d308a56f" />

Meaning around 30–40 MB.

P.S. sing-box 1.15.0-alpha.6
</details>

<details>
  <summary>11. I see ads - what should I do?</summary>
<br>

There's no escaping ads entirely. DNS filtering alone won't get rid of them because it only blocks domain requests, leaving direct IP requests and embedded JS scripts in HTML pages untouched.

The best approach to eliminate ads (use these together):

1. Use specialized software or extensions for client devices, such as [uBlock Origin](https://github.com/gorhill/uBlock#ublock-origin) for your browser.
2. Configure domain-based blocklists in sing-box DNS routing. This is mainly needed for applications and devices where extensions or modifications aren't available. While it doesn't guarantee a 100% success rate, it will filter out thousands of unnecessary requests at the routing stage (doing this on the server is highly inefficient).

This allows you to use global DNS providers like Google DNS and Cloudflare, which is the proper approach (and proxying them through a tunnel is best left unmentioned).
</details>

<details>
  <summary>12. Compatibility with other “tools”?</summary>
<br>

If you've decided to install SKeen, then there's no point in using other similar solutions.

Compatibility with other so-called “tools” has not been tested and will not be tested. If you need to, test them yourself, but don't ask SKeen to accommodate anything else.
</details>

<details>
  <summary>13. Why can't I get my full internet connection speed?</summary>
<br>

If your speed exceeds 20 Mbps, you've already crossed the threshold and are free. But the price of this freedom and security is a loss of megabits. Appreciate it.
</details>

<details>
  <summary>14. Which self-hosted panel should I use?</summary>
  <br>

For personal use, if you don't need traffic usage monitoring, it's better to skip the panel and deploy the required protocols using Docker - [examples](../examples/server-client/Server-sing-box.md).

If you need a web interface, consider [S-UI](https://github.com/alireza0/s-ui).

For commercial use, consider [Nexora](https://docs.nexora-panel.org/use/).

Xray-based panels are not the best choice, especially if you need a modern, flexible stack with broad client compatibility. Mihomo-based panels are even less suitable for server-side use: Mihomo is primarily designed for proxy clients, not for managing server infrastructure.
</details>

<details>
  <summary>15. Why doesn't the "🧲 Torrent" selector work?</summary>
<br>

Refer to the [sing-box configuration documentation](../examples/configs/stable/config-commented.jsonc).
</details>

<details>
  <summary>16. Which storage device is best for Entware?</summary>
<br>

For this purpose, a good old HDD is the best choice over a USB flash drive, SSD, or NVMe drive. With proper use, it can easily last more than 15 years.
</details>

<details>
  <summary>17. Is Gemini not working?</summary>
<br>

Change your IP address or proxy provider, or use [edgetunnel](../examples/server-client/Example-5.md).
</details>
