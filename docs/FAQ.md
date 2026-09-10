# FAQ

<details>
  <summary>FakeIP?</summary>
<br>

The following are intentionally **excluded** from the bypass list (local network exceptions):

1.  **Subnet `198.18.0.0/15`**
    In the script, the `198.18.0.0/15` line is commented out. This means traffic to Sing-Box FakeIP addresses will be intercepted and processed by the kernel as intended. This is a deliberate design choice for proper routing.

2.  **Subnet `fc00::/18`**
    The IPv6 segment `fc00::/18` (Sing-Box Fake-IP range for IPv6) is also excluded from the bypass list for the same reason.

</details>

<details>
<summary>ADGuard Home & DNS?</summary>
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
  <summary>Installation to internal memory?</summary>
<br>

This is highly discouraged. From a manufacturer's perspective, this is a sure way to wear out your device's memory faster, forcing an early replacement. This option will never be added to SKeen; however, nothing stops you from skipping the **sing-box** installation and using your own binary.

</details>

<details>
  <summary>Multi-WAN Mode?</summary>
<br>

When Multi-WAN is enabled, sing-box's own outbound traffic may "hop" between different providers. Since most proxy protocols (VLESS, VMess, Shadowsocks) are highly sensitive to client IP changes within a single session, the connection becomes extremely unstable. For proper operation, you must strictly bind sing-box to a single internet channel.

An example of how to bind a connection to a specific interface can be found in the `examples/basic/` folder, in the `multi-interface-routing.json` file.

> **Note:** Selecting a provider in the SKeen policy has no effect by default without setting a policy mark in the routing or within the **outbounds** of the **sing-box** configuration. You can select any connection, but be aware: by default, the internet gateway specified in the default policy will be used, unless you have bound all or selected connections (**outbound**) to a specific interface.

**Question:** Why is the option to choose a provider missing from the router policies?

**Answer:** Routing is managed solely within the sing-box configuration. In the event that the primary provider fails, failover to the backup channel is disabled. This is intentional for your security to guarantee entirely predictable behavior.
</details>

<details>
  <summary>KeenDNS in TProxy mode?</summary>
<br>

If you have disabled internet access to your subdomain in the "Domain Name" section of the control panel, then to access **KeenDNS** from the local network in **TProxy** mode, you need to configure a `hosts` or `local` type DNS server in the sing-box configuration (see configuration examples in the `examples/basic/keendns-tproxy-local-access.json file`). If internet access is allowed, no additional.

**Note:** Freeing up port 443 is absolutely not required for TProxy to work.

> **Note:** Changing the HTTPS port in the web interface takes effect only after a subsequent router reboot. This is unrelated to SKeen and is a known bug in the firmware itself.

</details>

<details>
  <summary>Routing by DSCP?</summary>
<br>

**This feature is not and will not be available in SKeen.**

Reasons why:

* **Breaks HW NAT:** Checking DSCP tags in iptables forces the router to inspect every single packet on the CPU. This completely disables hardware acceleration (PPE/HNAT) for all of the client's connections, tanking your overall internet speed.
* **Windows Quirks:** The Windows network stack regularly resets DSCP tags after OS updates or network profile changes (via NLA).
* **Incompatibility:** It is technically impossible to configure application-level DSCP tagging on mobile devices (iOS/Android) or Smart TVs.
* **ISPs Strip Tags:** Attempting to send packets with DSCP tags to your ISP can lead to unpredictable latency, packet loss, and traffic deprioritization on their end.

**Q:** What should I do instead?

**A:** Learn how to build routing using Sing-box rules, and use FakeIP to filter traffic.
</details>

