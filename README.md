# H&M IPFire Firewall-Local

Release 1.7.1-ui 2026-06-12

A professional-grade modular firewall orchestration add-on for IPFire. Manages iptables/ipset rules via four Single Source of Truth (SST) master list files. Deployed as a Pakfire `.ipfire` package.

**[› Usage Guide with screenshots](USAGE.md)**

**[› Feature list explained](docs/FEATURE_LIST.md)**

---

> **Note — about this repository**
>
> This repository publishes **final package releases only**. The release assets
> (`.ipfire` + `.sha256`) attached to each GitHub release are everything you need to install
> the add-on via Pakfire.

---

## Requirements

- IPFire 2.x (tested on Core Update 185+, APU2D4 hardware)
- Pakfire package manager (bundled with IPFire)

---

## Installation

Install via utilities included in release assets:

```bash
# Download the latest release package from the Releases page, unpack it under /opt/pakfire/tmp then:
NAME=firewall-local bash update.sh   # or install.sh for a fresh install
```

See the [Usage Guide](USAGE.md) for full post-install configuration steps.

---

## What It Does

Firewall-local extends IPFire's native firewall with several independently manageable rule domains,
each backed by a plain-text master list file that the web UI reads and writes:

| Module | What it manages |
|--------|----------------|
| **ASN Block** | Drop or accept traffic by Autonomous System Number — blocks entire ISPs, hosting ranges, or cloud CDNs in one rule |
| **IP / CIDR Rules** | Fine-grained allow/deny rules by IP, subnet, protocol, and port — covers both inbound and forwarded traffic |
| **SMB Allow** | Selective SMB (Samba) forwarding exceptions — while DROPSAMBA is enforced for all the other machines |
| **Country Allowlist** | LOCATIONBLOCK whitelist — limits inbound access to a configured set of countries only (default is to block every inbound packet) |
| **Outgoing Location Block** | Blocks forwarded outbound traffic destined for specified countries (FORWARDFW + OUTGOINGFW) |

All modules are applied idempotently on every `firewall.local reload` so no manual iptables
management is needed after a rule change or reboot.

---

## Installed Layout

After installation the add-on places files at these paths on the IPFire system:

```
/etc/sysconfig/
  firewall.local                  # Main orchestrator — IPFire calls this on start/stop/reload

/var/ipfire/fw.local/             # Add-on root (nobody:nobody 755)
  fw-local.settings               # Module enabled/disabled state (nobody:nobody 644)
  lists/                          # Master lists (nobody:nobody 644)
    asn_master.list               # ASN-based rules
    ip_master.list                # IP/CIDR-based rules
    smb_master.list               # SMB host rules
    locationallow_master.list     # Country whitelist (CC=on/off,DESC)
  scripts/                        # Modular extension scripts (root:root 755)
    README                        # Naming convention and execution order
    *_start.sh                    # Sourced on firewall.local start and reload
    *_stop.sh                     # Sourced on firewall.local stop and reload

/usr/local/bin/
  firewall_functions              # Core function library (600 root:root)

/srv/web/ipfire/cgi-bin/
  firewall-local.cgi              # Module Dashboard
  location-allow.cgi              # Country Allowlist
  asn-block.cgi                   # ASN Rule Manager
  ip-rules.cgi                    # IP / CIDR Rule Manager
  smb-allow.cgi                   # SMB Exception Manager
  outgoing-location-block.cgi     # Outgoing Location Block

/var/ipfire/menu.d/
  EX-firewall-local.menu          # IPFire web UI navigation entry
```

---

## Master List Formats

All list files live at `/var/ipfire/fw.local/lists/` and are read/written by both the web UI and the firewall engine. Lines starting with `#` and blank lines are always skipped.

| File | Format | Notes |
|------|--------|-------|
| `asn_master.list` | `ASN;TABLE;ACTION;DIR;LOG;CHAINS` | CHAINS is space-separated |
| `ip_master.list` | `OBJECT;TABLE;ACTION;DIR;PROTO;PORT;CHAINS` | PORT can be `80,443` for multiport |
| `smb_master.list` | `Host_Fragment;ACTION;IP_DEST` | Resolves via `/var/ipfire/fwhosts/customhosts` |
| `locationallow_master.list` | `CC=STATE,DESC` | `on` = active, `off` = disabled but preserved in UI |

---

## Modular Scripts

Place custom iptables rules in `/var/ipfire/fw.local/scripts/` following the naming convention:

| File pattern | When sourced |
|---|---|
| `<name>_start.sh` | `firewall.local start` and `reload` — after all master lists are applied |
| `<name>_stop.sh` | `firewall.local stop` and `reload` — after all master lists are removed |

Scripts must be executable (`chmod 755`). They are sourced in alphabetical order within each phase. See `/var/ipfire/fw.local/scripts/README` on the installed system for details.

---

## Runtime Behaviour

### Country ipset lifecycle

**Location Allow** — each active country (`CC=on`) gets its own kernel ipset named `allow_cc_XX`
(e.g. `allow_cc_DE`). All active sets are collected into a parent `allow_zone_master` (`list:set`)
that the LOCATIONBLOCK chain matches against.

**Outgoing Location Block** — each country in the Custom Location Group gets a `block_cc_XX` ipset.
All are collected into `GL_BAD_COUNTRIES` (`list:set`) matched against the destination address on
FORWARDFW and OUTGOINGFW (REJECT). Both functions load country networks from IPFire's pre-generated
`/var/lib/location/ipset/${CC}v4.ipset` files — reducing 230-country load time from ~32 minutes
to ~35 seconds on APU2D4 hardware.

When a country is removed and Apply is clicked, `firewall.local reload` runs a stop → start cycle:

| Phase | What happens |
|---|---|
| **Stop** | `allow_cc_XX` is flushed. Destroy may fail if the set is still referenced — the empty shell stays in kernel memory. |
| **Start** | `allow_zone_master` is rebuilt from the current CC list. The removed country is not re-added; its empty set drops to `References: 0`. |
| **Next stop** | With `References: 0`, `ipset destroy` succeeds and the orphan is removed. |

The DEBUG log message `Set allow_cc_XX is locked by kernel. Flushed and left active for safety.`
is normal when removing a country. The empty set holds no entries and has no iptables references —
it is removed automatically on the next reload or stop.

```bash
# Verify state after removing a country:
ipset list allow_cc_XX   # expect: Number of entries: 0, References: 0
```

---

## License

MIT — see [LICENSE](LICENSE).
