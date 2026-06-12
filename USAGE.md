# Firewall Local — Usage Guide

Version 1.7.1-ui

---

## Navigation

After installation, open the IPFire web interface and go to **IPFire › FW Local**
(`cgi-bin/firewall-local.cgi`). That entry is always present and leads to the
**Module Dashboard** — your control panel for all five add-on modules.

Each module has its own page reachable from **Firewall › \<Module Name\>** once activated.

---

## Module Dashboard

![Module Dashboard](docs/2026-06-05_Firewall%20Local%20%E2%80%94%20Module%20Dashboard.1.7.0.png)

The dashboard lists all five modules with their current state and an activate/deactivate toggle.

| Module | Purpose |
|--------|---------|
| **Location Allow** | Country-based allowlist. Replaces IPFire's default Location Block UI with a whitelist dashboard — only traffic from listed countries passes through. |
| **ASN Block** | Block or allow traffic by Autonomous System Number. Useful for dropping entire cloud providers, CDNs, or known bad networks. |
| **IP / CIDR Rules** | Precise allow/block rules for individual IPs, subnets, or named IPsets. Supports multiport, multiple chains, and NAT PREROUTING. |
| **SMB Allow** | Whitelist specific BLUE-network (WiFi) hosts to reach a Samba/NAS server. Only meaningful when IPFire's *Drop SMB* option is active. |
| **Outgoing Location Block** | Block forwarded and outbound traffic to countries defined in IPFire's Custom Location Groups. Converts per-CIDR rule chains into two O(1) ipset lookups on FORWARDFW and OUTGOINGFW. |

**Activating a module** adds it to the Firewall menu immediately — no firewall reload required.
**Deactivating** removes the menu entry. The module's rule list is preserved; rules take effect again on next activation + Apply.

---

## Location Allow

![Country Allowlist](docs/2026-06-03_Firewall%20Local%20-%20Country%20Allowlist_1.6.0.png)

**How it works:** This module takes over IPFire's `LOCATIONBLOCK` chain. Instead of the
default block-by-country, it enforces a default-drop posture — all countries are blocked
unless explicitly added to the allowlist.

**Firewall-Local Settings** — the master enable/disable switch. When disabled, the
LOCATIONBLOCK engine is released back to IPFire's native control.

**Add Country** — enter a two-letter ISO country code (e.g. `DE`) and an optional
description, then click **add**.

**Country Whitelist table** — each row has an Active checkbox. Uncheck a country to
suspend it without deleting it. Click **save** to persist checkbox state, then **Apply**
(appears in a notice banner) to push the changes to the running firewall.

> The Apply step performs a full stop → start cycle on the location engine. Country ipsets
> are rebuilt atomically — no packet drops during the swap.

---

## ASN Block

![ASN Rules](docs/2026-06-03_Firewall%20Local%20-%20ASN%20Rules_1.6.0.png)

Manages `asn_master.list`. Each rule maps an ASN to one iptables chain.

**Add ASN Rule** fields:

| Field | Values | Notes |
|-------|--------|-------|
| **ASN** | numeric (e.g. `15169`) | No `AS` prefix needed |
| **Table** | `filter` / `nat` | Almost always `filter` |
| **Action** | `DROP` `REJECT` `ACCEPT` `RETURN` | DROP = silent; REJECT = ICMP error back |
| **Dir** | `src` / `dst` | Match on source or destination ASN |
| **Log** | `true` / `false` | Log matching packets to syslog |
| **Chains** | checkboxes | Select one or more chains from the list |

Hover over any field label for a tooltip explaining valid values.

**ASN Rules table** — the Status checkbox enables/disables a rule row. Uncheck and **save**
to suspend a rule without deleting it. **Delete** removes it permanently (with confirmation).

> ASN resolution uses the IPFire `location` binary. Each ASN is expanded to its CIDR list
> and loaded into a kernel ipset (`hash:net`). Rules reference the ipset — O(1) lookup
> regardless of how many CIDRs the ASN covers.

---

## IP / CIDR Rules

![IP CIDR Rules](docs/2026-06-03_Firewall%20Local%20-%20IP%20_%20CIDR%20Rules_1.6.0.png)

Manages `ip_master.list`. More flexible than ASN rules — accepts individual IPs, subnets,
IPset names, or `0.0.0.0/0` for any.

**Add IP / CIDR Rule** fields:

| Field | Values | Notes |
|-------|--------|-------|
| **Object** | IP, CIDR, `0.0.0.0/0`, IPset name | Hover for tooltip |
| **Table** | `filter` / `nat` | Use `nat` + `CUSTOMPREROUTING` for Squid bypass |
| **Action** | `DROP` `REJECT` `ACCEPT` `RETURN` | |
| **Dir** | `src` / `dst` | Source or destination match |
| **Proto** | `tcp` `udp` `icmp` `all` | |
| **Port** | single (`443`), multiport (`80,443,853`), `all` | Ignored when Proto is `all` or `icmp` |
| **Chains** | checkboxes | Select one or more target chains |

**Key chain selection guide:**

| Chain | Use when… |
|-------|-----------|
| `BLOCKLISTIN` | Aggressively blocking inbound — runs early (pos 4), before OpenVPN |
| `FORWARDFW` | Blocking forwarded traffic (LAN↔WAN) |
| `CUSTOMFORWARD` | Allowing specific LAN-to-destination traffic; runs before wirelessctrl |
| `CUSTOMPREROUTING` (nat) | Bypassing Squid transparent proxy for matching src/dst |
| `OUTGOINGFW` | Controlling outbound traffic from LAN clients |
| `CUSTOMOUTPUT` | Rules for traffic originating from the IPFire box itself |

---

## SMB Allow

![SMB Allow](docs/2026-06-03_Firewall%20Local%20-%20SMB%20Allow_1.6.0.png)

Manages `smb_master.list`. Controls which BLUE-network (WiFi) clients may reach a
Samba or NAS server on the GREEN (wired) network.

**Prerequisite:** IPFire's *Drop SMB* option must be active (`Firewall › Options`).
Without it, all SMB traffic is allowed by default and these rules have no effect.
A warning banner is shown when this condition is not met.

**Add SMB Exception** fields:

| Field | Notes |
|-------|-------|
| **Host Fragment** | Part of a hostname registered in IPFire. Searched in: `fwhosts/customhosts` (ip type → direct IP), `fwhosts/customhosts` (mac type → DHCP fixleases bridge → IP), then `main/hosts`. Alphanumeric, underscore, hyphen. |
| **Action** | `ACCEPT` allow SMB · `DROP` silently block · `REJECT` block + ICMP error · `RETURN` skip remaining SMB rules |
| **Dest IP** | IPv4 of the Samba/NAS server the host is allowed to reach |

The fragment is resolved to an IP at firewall apply time. If a host is registered in
IPFire as a MAC address (common for WiFi devices), the resolver bridges via DHCP fixleases
to find the assigned IP automatically — no manual IP entry needed in IPFire hosts.

**SMB Exceptions table** — same Status checkbox + Delete convention as the other modules.

---

## Outgoing Location Block

![Outgoing Location Block](docs/2026-06-05_Firewall%20Local%20-%20Outgoing%20Location%20Block.1.7.0.png)

Manages the block list for forwarded and outbound traffic using IPFire's Custom Location
Groups (`Firewall › Firewall Groups › Location Groups`).

**How it works:** The module reads the Custom Location Groups defined in IPFire's native UI
and builds a single `GL_BAD_COUNTRIES` ipset (`list:set`) containing one `block_cc_XX` child
set per country. Two REJECT rules — one on FORWARDFW, one on OUTGOINGFW — match on the
destination address. The entire country block list resolves in a single O(1) kernel lookup.

Country networks are loaded from IPFire's pre-generated `/var/lib/location/ipset/` files
(the same files used by IPFire's native firewall engine internally) — not from live
`location` binary queries. This keeps reload time in the range of seconds regardless of
how many countries are in the block list.

**Prerequisite:** At least one Custom Location Group must exist (`Firewall › Firewall Groups
› Location Groups`). The group membership is managed entirely there —
this module's CGI is read-only.

**Rule overlap check:** If you already have native IPFire rules that reference a Custom
Location Group — on FORWARDFW, OUTGOINGFW, or any other chain — enabling this module
creates overlap with those rules. Double-blocking on the same traffic is functionally
harmless but wastes rule traversal time on every packet. Before enabling, review your
existing firewall rules (`Firewall › Firewall Rules` and `Outgoing Rules`) and decide
whether to keep, adjust, or remove overlapping entries. The
[firewall chain diagram](docs/ipfire_pcb_firewall_core200_v1.5.1_TB.png) shows exactly
where FORWARDFW and OUTGOINGFW sit in the packet flow relative to all other chains —
useful for reasoning about what fires before and after this module's two REJECT rules.

**Enable/Disable toggle** — writes `OUTGOING_BLOCK_ENABLED=on/off` to `fw-local.settings`.
A pending-apply banner appears after toggling. Click **Apply** to push the change to the
running firewall.

> The Apply operation runs a full stop → start cycle. All 230 block_cc_XX ipsets are
> rebuilt atomically from pre-generated files — reload completes in ~35 seconds on APU2D4
> and faster on more capable hardware.

---

## Applying Changes

Each module page shows a **Pending Changes** banner after any add, delete, or save
operation. Click **Apply** in that banner to push the updated rule list to the running
firewall. Until Apply is clicked, the on-disk list and the live iptables state are out
of sync.

The Apply operation calls `firewall.local reload`, which does a full stop → start cycle
for that module's rules. All operations are idempotent — reloading twice is safe.

---

## Chain Position Reference

If you need to know exactly where `BLOCKLISTIN`, `CUSTOMFORWARD`, `CUSTOMPREROUTING`
and the others sit relative to GeoIP, OpenVPN, WireGuard, and the default FORWARD policy,
see **[diagraph-ipfire](https://github.com/horace-michael/diagraph-ipfire)** — it reads
the live iptables state from your IPFire box over SSH and produces a full chain-map diagram.
