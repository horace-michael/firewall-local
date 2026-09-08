# Firewall Local — Usage Guide

Version 1.8.0-ui

---

## Navigation

After installation, open the IPFire web interface and go to **Extras › Location Allow**.
That entry is always present and leads to the **Module Dashboard** — your control panel for
all four add-on modules.

Each module has its own page reachable from **Firewall › \<Module Name\>** once activated.

---

## Module Dashboard

![Module Dashboard](docs/2026-06-05_Firewall%20Local%20%E2%80%94%20Module%20Dashboard.1.7.0.png)

The dashboard lists all four modules with their current state and an activate/deactivate toggle.

| Module | Purpose |
|--------|---------|
| **Location Allow** | Country-based allowlist. Replaces IPFire's default Location Block UI with a whitelist dashboard — only traffic from listed countries passes through. |
| **ASN Block** | Block or allow traffic by Autonomous System Number. Useful for dropping entire cloud providers, CDNs, or known bad networks. |
| **IP / CIDR Rules** | Precise allow/block rules for individual IPs, subnets, or named IPsets. Supports multiport, multiple chains, and NAT PREROUTING. |
| **SMB Allow** | Whitelist specific BLUE-network (WiFi) hosts to reach a Samba/NAS server. Only meaningful when IPFire's *Drop SMB* option is active. |
| **Outgoing Location Block** | Block forwarded and outbound traffic to countries defined in IPFire's Custom Location Groups. Converts per-CIDR rule chains into two O(1) ipset lookups on FORWARDFW and OUTGOINGFW. |
| **Company Block** | Block all forwarded and outbound traffic to networks owned by named companies. libloc resolves company name → ASNs → CIDRs at firewall start. Two O(1) REJECT rules on CUSTOMFORWARD and CUSTOMOUTPUT (dst). |

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

**Before enabling:** Delete the two native IPFire rules that block the same Custom Location
Group on FORWARDFW and OUTGOINGFW (Firewall → Firewall Rules / Outgoing Rules). Leaving
those rules in place alongside this module results in double-blocking — functionally harmless
but wastes rule traversal time.

**Enable/Disable toggle** — writes `OUTGOING_BLOCK_ENABLED=on/off` to `fw-local.settings`.
A pending-apply banner appears after toggling. Click **Apply** to push the change to the
running firewall.

> The Apply operation runs a full stop → start cycle. All 230 block_cc_XX ipsets are
> rebuilt atomically from pre-generated files — reload completes in ~35 seconds on APU2D4
> and faster on more capable hardware.

---

## Company Block

![Company Block](docs/2026-06-15_Firewall%20Local%20-%20Company%20Block.png)

Manages `company_master.list`. Blocks all IPv4 traffic forwarded or outbound to networks
owned by named companies. At firewall start, libloc resolves each company key →
ASN list → CIDRs and builds a per-company `hash:net` ipset. All per-company sets are
aggregated into `comp_master` (`list:set`). Two REJECT rules — one on CUSTOMFORWARD,
one on CUSTOMOUTPUT — match on the destination address.

**Enable/Disable toggle** — writes `COMPANY_BLOCK_ENABLED=on/off` to `fw-local.settings`.

**Add Company** fields:

| Field | Notes |
|-------|-------|
| **Company Key** | Passed verbatim to `location search-as <key>`. Letters, digits, spaces, hyphens only (max 20 chars). No special characters (`&` `@` `.` etc.). |
| **Description** | Free-text label shown in the table. May contain any characters including `&`. |

**Company List table** — each row has a toggle icon (enable/disable), an edit icon, and a
delete icon. Toggle takes effect immediately (no Save step needed). Edit pre-fills the Add
form in-place; description-only edits do not require an Apply.

**Apply** — rebuilds all company ipsets atomically and re-injects the two REJECT rules.

---

### Key field constraints and limitations

The Company Key is a **libloc search term**, not the full company name. It must be a
substring of the organisation name as libloc knows it (case-insensitive match).

**Why `&` and other special characters are not allowed:** the key also forms the ipset
name — `comp_<key>_net` (spaces converted to hyphens). Kernel ipset names cannot contain
`&`, `@`, `/`, or spaces-after-hyphenation conflicts, so these characters are stripped at
input.

**What to use instead:**

| Company name in libloc | Correct key |
|---|---|
| Google LLC | `google` |
| Datacamp Limited | `datacamp limited` |
| AT&T | `att` |
| Private Layer INC | `private layer inc` |

**Verify before adding** — always run this on the IPFire shell first:

```bash
location search-as "your key here"
```

**False positive risk.** libloc returns every ASN whose name contains the key as a
substring — short or common keys can match unrelated organisations. All matched ASNs
have their CIDRs loaded into the block set. Choose the most specific substring that
uniquely identifies the target company.

---

### Scale warning (low-memory hardware)

Large companies can have thousands of CIDRs across many ASNs. Each CIDR is one `ipset add`
call — on APU2D4 hardware with a spinning disk, a company with 5 000+ CIDRs can take
several minutes to load and may exhaust available memory.

Before adding a large company, check its CIDR volume on the IPFire shell:

```bash
# Step 1 — list all matching ASNs
location search-as "hetzner online gmbh"

# Step 2 — count CIDRs for each ASN returned
location list-networks-by-as --family=ipv4 24940 | wc -l
```

If the total across all ASNs exceeds ~1 000 CIDRs, consider whether the target hardware
can handle the load. For APU2D4, prefer companies with a single ASN and fewer than
500 CIDRs (e.g. `private layer inc` → AS51852 → ~60 CIDRs).

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
