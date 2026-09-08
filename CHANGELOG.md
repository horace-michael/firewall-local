# CHANGELOG — Firewall-Local

---

## [1.8.0-ui] - 2026-06-14

**Company Block module.** Block all networks belonging to named companies by resolving
company name → ASN → CIDRs via libloc at firewall start. Two O(1) REJECT rules on
CUSTOMFORWARD and CUSTOMOUTPUT (dst match). Managed via new `company-block.cgi` with
add/enable/disable/delete/edit per company. Concept: Shellshock (IPFire forum); libloc
integration: ummeegge; firewall-local adaptation: H&M.

**UI aligned with native IPFire icons + Edit function across all CGIs.** All five module
CGIs (ip-rules, asn-block, smb-allow, company-block, location-allow) now use native IPFire
icons: per-row on.gif/off.gif toggle, edit.gif, delete.gif, addblue.gif (Add), floppy.gif
(Update). Edit pre-fills the Add form in-place and preserves entry state; description-only
edits skip firewall reload. Location Allow menu label corrected ("Location Block" → "Location Allow").

**ASN Rules table: Organisation column.** `asn-block.cgi` now shows the registered
organisation name alongside each AS number. A single batch `location get-as` call resolves
all ASNs on page load — no per-row subprocesses. Gracefully blank when libloc is absent.

**Company Block module — key field design and constraints.** The **Company Key** field is
passed verbatim to `location search-as <key>` at firewall start. It must be a substring of
the organisation name as libloc knows it (case-insensitive). Allowed characters: letters,
digits, spaces, hyphens (max 20). Special characters (`&`, `@`, `.` etc.) are stripped at
input because the key also forms the ipset name (`comp_<key>_net` with spaces converted to
hyphens) — ipset names cannot contain those characters. Consequence: for companies whose
names contain `&` (e.g. "AT&T"), the key must omit the special character (e.g. `att`).
Risk of false positives: `location search-as` returns every ASN whose name contains the
key as a substring — short or common keys may match unrelated organisations.
Verify with `location search-as <key>` on the IPFire shell before adding.
Large companies (Hetzner, Google, Amazon) may have thousands of CIDRs; load time and memory
use scale with CIDR count — test with `location list-networks-by-as --family=ipv4 <asn> | wc -l`
before enabling on low-memory hardware such as APU2.

**Bug fix: ASN bypass rules in LOCATIONBLOCK landed after the terminal DROP.**
`process_asn_master_list()` used `iptables -A` (append), so RETURN rules were added after
the DROP that `location_allow()` inserts — making them unreachable. Fixed to `iptables -I`
(insert at position 1). LOG+ACTION insertion order corrected so LOG fires before the
terminal action with `-I` semantics.

**Bug fix: `fw-chains-user.conf` erased on every package update.** The file was seeded
on first install but absent from the IPFire backup includes, so `extract_files` overwrote
it on every `update.sh` run — silently destroying any custom chain entries the operator
had added. Fixed by adding it to `generate_backup_includes()` in `make-package.sh` so the
pakfire backup/restore cycle preserves it across updates.

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
