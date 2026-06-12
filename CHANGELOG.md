# CHANGELOG — Firewall-Local

---

## [1.7.1-ui] - 2026-06-09

Maintenance: corrected navigation path in Outgoing Location Block CGI and USAGE.md
(`Firewall › Firewall Groups › Location Groups`); updated ASN Rules screenshot.
Code hygiene pass on `firewall_functions` and `firewall.local` (comment translations,
typo fixes, version bump).

---

## [1.7.0-ui] - 2026-06-05

**Outgoing Location Block module.** Replaces IPFire's native per-CIDR location group
rule expansion with two O(1) ipset REJECT lookups on FORWARDFW and OUTGOINGFW.
Country networks loaded from pre-generated `/var/lib/location/ipset/` files — same
source used by IPFire's own `rules.pl`. Reload time: 230 countries in ~35 seconds
(was ~32 minutes with live `location` queries).

Also rewrote `location_allow()` to use the same pre-generated ipset files.

---

## [1.6.0-ui] - 2026-06-02

**Full web UI.** Master Module Dashboard + three new per-module CGIs (ASN Block,
IP/CIDR Rules, SMB Allow). Shared chain configuration system (`fw-chains.conf` +
`fw-chains-user.conf`) so operators can add iptables chains without a package update.
New `fw-menu-ctrl` setuid helper for dynamic Firewall menu injection/removal.

---

## [1.5.0-ui] - 2026-05-27

**Country Allowlist CGI.** First web interface release. Storage path migration to
`/var/ipfire/fw.local/lists/` (nobody:nobody). `fw-local-ctrl` setuid helper for
CGI privilege delegation. `locationallow_master.list` format changed to `CC=on/off,DESC`.

---

## [1.4.3-S] - 2026-05-26

Dynamic network readiness guard (`check_network_readiness()`). Boot delay reduced
from ~6 minutes to ~90 seconds on APU2 hardware.

---

## [1.4.2-S] - 2026-05-25

O(1) ipset matrix engine (`hash:net` collections). Zero-downtime atomic swap via
`ipset swap`/`rename`. Native Bash parameter expansion replacing sed/awk/cut subshells
(~75% logic-layer speedup).

---

## [1.4.0] - 2026-05-21

Default-drop whitelist posture. `list:set` matrix aggregator. LOCATIONBLOCK
consolidated from 150+ linear rules to a single O(1) rule.

---

## [1.3.3] - 2026-05-16

Teardown performance: removed slow `iptables -C` loops during `remove` phase.
Boot guardrail: dynamically provisions missing chains instead of skipping. Build
artifacts isolated to `build/`.

---

## [1.3.2] - 2026-03-16

Input validation (`validate_network_object`, `validate_fw_chain`). IFS delimiter
migrated from `,` to `;` to support multi-port strings.

---

## [1.3.1] - 2026-03-15

Dynamic directory discovery in build system. Strict numeric ASN validation.
Isolated STDOUT for value-returning functions.

---

## [1.3.0] - 2026-03-13

Atomic ipset swap logic. SST orchestration (Master Lists before modular scripts).
Syslog audit trail.

---

## [1.2.0] - 2026-03-06

`ip_master.list` and `smb_master.list` architecture introduced.

---

## [1.1.0] - 2026-03-06

Polymorphic ipset engine: multi-table, multi-chain, dynamic directionality.

---

## [1.0.0] - 2026-03-05

Initial modular library. Dual-output logging. Orchestrator refactor.

---

## [0.5.2] - 2026-02-09

Initial modular firewall loader with `*_start.sh` / `*_stop.sh` support.
