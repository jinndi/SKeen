# Configuration

### Settings

> [!NOTE]
> After making changes to the file, a restart via `skeen restart` or through the menu is required

The file `/opt/etc/skeen/skeen.json` has the following settings:

```jsonc
{
  "auto_start": {      //// Automatic startup configuration for SKeen including Sing-box.
    "enabled": 1,      // SKeen autostart on router reboot (0 = disabled)
    "delay": 0         // Auto-start delay in seconds (default: 0)
  },
  "policy": {          //// Access policy configuration for the specified network segment.
    "enabled": 0,      // Enable routing based on segment policy (1 - enable, 0 - disable)
    "segment": "br1"   // Name of the segment interface (Bridge) whose policy will be used;
                       // starts with "br" followed by a number starting from 0.
                       // The number can be found in the URL under the "Segments" section,
                       // e.g., http://192.168.1.1/segments/Bridge1 corresponds to "br1".
                       // Alternatively, use the command: skeen iface
  },
  "network": {         //// Network configuration
    "ipv6": 1,         // Enable IPv6 support (0 = disabled)
    "tuning": 0,       // Enable sysctl network optimization (1 = on).
                       // If disabled, sysctl settings reset after reboot.
    "check": [
      "1.1.1.1",
      "77.88.8.8",
      "223.5.5.5"
    ]                  // Domains or IPs V4 for connectivity tests (max 3)
  },
  "singbox": {         //// Sing-box configuration
    "config": {        // + Configuration file
      "path": "",      // Absolute path or relative to the working directory /opt/etc/skeen
                       // to a local file or Sing-box configuration directory.
                       // By default, the file at /opt/etc/skeen/config.json is used.
      "url": "",       // URL (http:// or https://) for syncing configuration
                       // via `skeen sync` by default (optional)
      "split": 1       // If 1, the synced config via link (skeen sync) will be split
                       // into files named after the top-level Sing-box configuration keys.
                       // Available only if path points to a directory.
    },
    "api": {           // + sing-box API settings for commands via the intermediary layer (skeen api)
                       // sing-box version 1.14.beta.15 or higher is required
      "url": "",       // URL to the sing-box API service; default http://127.0.0.1:9999
      "secret": ""     // API secret key; specify this if it is set in the sing-box configuration.
    },
    "external": {      // + External Sing-box usage
      "enabled": 0,    // If set to 1, an external Sing-box binary is used;
                       // its installation, updates, and removal are managed manually.
      "path": "",      // Full path to binary (default: /opt/bin/sing-box).
      "config": {      // Configuration file for external Sing-box (optional)
        "path": "",    // Similar to the singbox.config object above;
        "url": "",     // its data will be used if left blank here.
        "split": 1
      },
      "api": {         // Parameters for accessing the sing-box API (optional)
        "url": "",     // Similar to the singbox.api object above,
        "secret": ""   // its data will be used if not specified here.
      }
    }
  },
  "services": {        //// Additional services configuration
    "proxy": {         // + Local proxy service for update and sync commands
      "enabled": 0,    // If set to 1, a local proxy (127.0.0.1) is used
      "port": "",      // Local proxy port (SOCKS5 or mixed)
      "user": "",      // Username for authentication (optional)
      "pass": ""       // Password for authentication (required if username is provided)
    }
  },
  "firewall": {        /// SKeen firewall configuration (iptables chains/rules)
    "intercept": {     // + Interception rules to the Sing-box core
      "dns": 1,        // Intercept DNS queries in TProxy/Hybrid modes (0 = disabled),
                       // ignored if redirect_dns is configured (see below)

      "fakeip": {      // Interception based on Sing-box FakeIP DNS
        "enabled": 0,  // If set to 1, includes the FakeIP pool in Redirect/TProxy interception;
                       // all other traffic goes directly, bypassing sing-box:
                       // - Requires firewall.intercept.dns or firewall.redirect_dns to be enabled,
                       //   along with sing-box DNS configuration.
                       // - The exclude.port/cidr exceptions will function as normal.
        "include": "", // Full path to the file containing a list of IP/CIDR resources (both v4 and v6):
                       // - Allows comments after #, empty lines, and leading/trailing whitespaces.
                       // - Intended for resources that initially didn't have a domain and therefore
                       //   didn't receive a FakeIP, but still need to be proxied.
                       // - Default value, if not specified, is /opt/etc/skeen/pure_cidr.list
        "clients": []  // Clients (IP addresses or CIDRs) that need FakeIP interception applied
                       // Example: [ "192.168.2.10", "192.168.2.11" ], if [] - all are used.
                       // For stable operation, a static IP address must be assigned to these clients;
                       // this is done in the Keenetic/Netcraze WebUI under the "Client Lists" tab
      }
    },
    "exclude": {       // + Exclude rules from Sing-box core interception
      "port": [
        "137:139",     // Ports excluded from Redirect/TProxy
        445, 1900      // (80 and 443 won't be added, exclude only the necessary system ones.)
      ],
      "ipv4_cidr": [], // Excluded IPv4 subnets from Redirect/TProxy
                       // Example: [ "192.87.1.0/24", "192.12.1.1" ]

      "ipv6_cidr": []  // Excluded IPv6 subnets from Redirect/TProxy
                       // Example: [ "2001:db8::/32", "2001:db8::1" ]
    },
    "redirect_dns": {  // + DNS query redirection (as an alternative to interception)
      "enabled": 0,    // Set to 1 to enable DNS redirection before system rules
      "to_port": "",   // The port to which DNS requests will be redirected
      "use_policy": 1  // Use defined policy if configured (0 = disabled)
    },
    "proxy_router": 0, // If set to 1, all router services will be proxied.
                       // Available in redirect, tproxy, and hybrid modes;
                       // subnet exclusions, as well as port bypass and interception rules, are respected.
  },
  "update": {          /// Update settings (skeen update)
    "singbox": {       // Sing-box updates (does not work with singbox.external.enabled=1)
      "enabled": 1,    // Enable Sing-box update check (0 = disabled)
      "beta": 0        // If set to 1, enables checking for pre-release versions (alpha, beta, rc)
    },
    "skeen": {
      "enabled": 1     // Enable SKeen update check (0 = disabled)
    }
  }
}

```

**Additional configuration notes:**

**`policy.segment`** - if you change the policy in the specified segment while SKeen is running, restart it to apply the changes. If the internet traffic rules are set to «Default policy» or «No internet access», SKeen will process traffic for the entire device.

**`network.ipv6`** - will not enable if the provider has not provided an IPv6 address for internet access.

**`network.tuning`** - when this option is enabled, the script applies a set of Linux kernel parameters (sysctl) adapted for the operation of high-performance proxy services (sing-box) on Keenetic routers.

<details>
  <summary>More details</summary>

| Category | Change | Result |
| :--- | :--- | :--- |
| **Network Capacity** | Increases connection limits (`conntrack`) by 1.5x | Allows the router to handle more simultaneous sessions without table overflows. |
| **Session Retention** | Increased timeouts for TCP (1200s → 1800s) and UDP (30s → 60s) | Prevents active connection drops during brief periods of traffic inactivity. |
| **Tunnel Reliability** | TCP Keep-Alive interval set to 60 seconds | Faster detection of "dead" proxy tunnels and immediate reconnections. |
| **TCP Speed** | Disabled `slow_start_after_idle` | Maintains maximum transfer speeds even after short bursts of inactivity. |
| **Responsiveness** | Enabled TCP Fast Open, SACK, and Timestamps | Accelerates connection handshakes and reduces overall latency. |
| **Data Throughput** | Enabled MTU Probing (`tcp_mtu_probing=1`) | Automatically detects optimal packet size, preventing sites from hanging or "freezing". |
| **Packet Queues** | Increased system queues (`backlog`, `somaxconn`) | Prevents packet loss during sudden traffic spikes or heavy loads. |
| **Security** | Enabled SYN Cookies and port reuse | Enhances network security and improves ephemeral port allocation. |
| **ARM Buffers** | Optimized `rmem`/`wmem` buffers (ARM Only) | Boosts peak throughput for high-end models like Giga, Ultra, and Hero. |

</details>

To reset the settings to their defaults, simply set `network.tuning` to `0` and reboot your router.

**`network.check`** - specify only those IP addresses or domain names that are guaranteed to be reachable (pingable) in your network to ensure the script can verify the connection and start services successfully after a router reboot.

**`firewall.intercept.fakeip`** - this feature relies on the sing-box DNS module, meaning it must be engaged via `firewall.intercept.dns` or `firewall.redirect_dns` and configured correctly (see examples in the `examples` folder). Everything flagged as FakeIP will always be routed through sing-box via Redirect and/or TProxy, while everything else will bypass it at the Linux kernel level. This can be highly beneficial if you primarily use domestic services and want to offload your aging mips(el) router, as FakeIP is meant to be used mainly for the foreign segment.

<details>
  <summary>Advantages over GeoIP IPset Country-Based Filtering</summary>

* **Minimal RAM Consumption:** The `geoipset` method requires loading tens of thousands of Russian subnets into the router's RAM just to exclude them. FakeIP does not store massive IP address databases at all. It operates dynamically and "on the fly" within a single small local subnet, freeing up precious memory for system needs.

* **Low CPU Load (Crucial for mips/mipsel):** Instead of a heavy IP address lookup across the complex hash tables of a massive GeoIP database for *every single* network packet, the Linux kernel under FakeIP performs a single, instantaneous bitwise check: does the IP belong to the fake subnet (e.g., `198.18.0.0/15`). All direct IP-based connections (messengers, games, P2P) that didn't initiate a DNS request will, by default, immediately route directly, completely bypassing any CPU-heavy checks. Only resources that received a FakeIP via domain resolution, or specific IP/CIDR ranges you explicitly added to the `include` list, will hit the proxy. This maximizes CPU cycles, preventing internet speed drops and ping spikes under load.

* **Autonomy and Independence from Updates:** GeoIP databases constantly become outdated, causing websites to mistakenly route through the proxy (or vice versa). FakeIP operates on domains right here and now; it doesn't require regular updates since sing-box handles everything for you natively.

* **Precise Traffic Filtering:** The FakeIP method routes **only the specific target resources** from your sing-box DNS routing list into the proxy, saving both traffic and server resources.

* **Built-in DNS Leak Protection:** FakeIP is inherently tied to the sing-box DNS module, meaning flagged websites physically cannot expose your real IP address through a provider's DNS query.

* **Clean Architecture Without Third-Party Software:** To make GeoIP work alongside domains, alternative solutions require installing AdGuard Home or similar tools, linking them to ipset, and managing a mess of configuration files. Keep in mind that AdGuard Home is a heavyweight application that can rival the proxy core itself in terms of RAM usage and CPU load. Running such a "zoo" of services on a weak router makes little sense. In SKeen, the entire FakeIP functionality works right out of the box within a single compact sing-box binary, completely free of extra software or kludgy workarounds.
</details>

This is an excellent solution, but use it with the understanding that you will need to manually configure the list of IP addresses for services that use direct IP connections (do not have a domain) but still need to be proxied. Such services include:

* **Messenger IP pools** - many connections go directly to data centers via IP;
* **Discord voice channels** - WebRTC traffic often bypasses DNS;
* **P2P networks and torrent clients** - metadata downloads and seeding via trackers or direct peers;
* **Game launchers and online games** - the traffic of the game sessions themselves often goes to direct addresses, though there are exceptions;
* **IP pools of certain mobile apps** - addresses that are hardcoded into the application's source code.

The addresses of such connections can be analyzed beforehand (there is no point for P2P, etc.) in the web panel, under the “Connections” or “Sessions” tab (the “Host” column, target address) - the raw IP will be shown instead of a domain name. Next, find up-to-date lists of the required IP/CIDR ranges online and add them to the file at the path specified in the `firewall.intercept.fakeip.include` parameter (changes will take effect after restarting SKeen using the `skeen restart` command).

Is this solution right for you? Everyone decides for themselves based on current constraints and personal requirements for network performance and security.

**`firewall.proxy_router`** - Note that enabling this feature will force the use of sing-box DNS (if it is configured and enabled). Additionally, if you have not added the IP addresses or subnets (`ipv4_cidr` / `ipv6_cidr`) of your built-in router VPN servers to `firewall.exclude`, traffic to them will also route through sing-box, creating unnecessary overhead.

