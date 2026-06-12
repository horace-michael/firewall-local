# FEATURE_LIST.md — What Firewall-Local Lets You Do

```
Repository path:  docs/FEATURE_LIST.md
Version:          1.0.0  2026-06-05
Author:           H&M
License:          MIT
```

---

## How to read this file

| # | The edge case (when you reach for it) | Feature |
|---|---|---|
| 1 | A cloud/hosting IP keeps probing your OpenVPN port | Pre-VPN network block (FL_BLOCK) |
| 2 | Only 3–5 countries should ever reach the box | Country allow-list (whitelist mode) |
| 3 | One trusted WiFi laptop needs the NAS, SMB stays locked for the rest | Per-host SMB grant |
| 4 | A media box / one host must skip the proxy | Selective proxy bypass |
| 5 | A useful server lives inside a country you block | Per-destination GeoIP exception |
| 6 | You need to WHOIS an attacker while GeoIP block is heavy | WHOIS / RIR keep-open |
| 7 | Your DoT resolver sits in an otherwise-blocked range | DoT keep-reachable |
| 8 | You want a record of every WireGuard handshake attempt | Persistent WG handshake log |
| 9 | Browsers fail cert checks behind the proxy | OCSP keep-reachable |
| 10 | A bad ASN must be stopped both ways (in and out) | Two-direction ASN control |
| 11 | You block 200+ countries outbound and reloads take forever | Outgoing Location Block at scale |

Helping documentation:
**[› Usage Guide with screenshots](../USAGE.md)**

<!-- VERIFY: confirm this PNG is actually tracked in docs/ and pushed public. Several
     sections below ("before OpenVPN", "before the country block") rest their *why* on
     this diagram's chain order — if it's missing, those become bare assertions. -->
**[› IPFire Firewall Diagram](ipfire_pcb_firewall_core200_v1.5.1_TB.png)**

---

## 1. Pre-VPN network block (FL_BLOCK)

**The edge case.** A specific hosting provider's address range keeps knocking on
your OpenVPN UDP port. You add a block rule the normal way, and the knocking
continues — because OpenVPN accepts the connection earlier in the packet's
journey than where a normal rule lives.

**The feature.** Add the ASN or CIDR to the **ASN Block** or **IP / CIDR Rules**
module and target the `BLOCKLISTIN` chain. Firewall-Local loads it as a kernel
ipset that fires very early — before any service (OpenVPN included) gets a chance
to answer. The hostile range is gone before it reaches anything that listens.

> Same machinery IPFire's own threat feeds (CIARMY, DSHIELD) use — you are just
> adding your own list to it.

---

## 2. Country allow-list (whitelist mode)

**The edge case.** Your box should answer **only** a small set of countries — say
three to five — and silently ignore the other ~225. IPFire's native model is the
inverse: allow everyone, then block the countries you pick. Building a near-total
block that way means ticking ~225 boxes.

**The feature.** The **Location Allow** module flips the model. Default posture is
*drop everything*; you add the few countries you trust. Each trusted country becomes
its own kernel set (`allow_cc_XX`), all gathered into one parent set the firewall
matches against. Add a country, click Apply — done. Removing one is a single
checkbox.

**Why this pays off on small boxes (Raspberry Pi / SD-card storage).** Whitelisting
is the lightest posture there is: you load a few country sets and reject
everything else. Almost all unsolicited inbound — the bulk of which originates
outside your country — is dropped in-kernel before it reaches any service, log, or
SD-card write. Low resident memory, low CPU, low write wear, and far less for
heavier layers (Suricata, DNS blocklist) to chew on if you can't afford to run them.

**What it does *not* do.** This narrows the surface; it is not a scanner shield.
Mass scanners (like Shodan) run nodes inside major clouds and ISPs in many countries
— including the one you allow. Whitelisting your own country to admit your ISPs also
admits any scanner hosted there. If your goal is to admit only *named* networks —
your mobile carrier, your workplace ISP, the consumer ISP behind the venues you visit
— that's an ASN allowlist, which belongs in the **ASN Block** or **IP / CIDR Rules**
module, not this one.

---

## 3. Per-host SMB grant

**Prerequisite:** Firewall options for the BLUE interface — *Drop all Microsoft
ports 135,137,138,139,445,1025* = ON.

**The edge case.** *Drop SMB* is on, isolating your WiFi (Blue) clients from the
file server — exactly what you want for every device except one trusted laptop
that genuinely needs the NAS.

**The feature.** The **SMB Allow** module lets you name that one host (by hostname
fragment) and the file server it may reach. The grant is placed in a chain that runs
*before* the blanket SMB drop, so that single device gets through while every
other Blue client stays blocked. If the host is registered by MAC (typical for
WiFi), the resolver finds its current IP automatically through DHCP leases — no
manual IP entry.

---

## 4. Selective proxy bypass

**The edge case.** Most web traffic should go through the transparent proxy
(Squid). A few things must not:
- **Secure Web Gateway Connector** — it reaches its nearest cloud edge via HTTP,
 and the Cloud Edge sets the nearest entry point dynamically based on your local
 Client and Exit IP. Being caught by the transparent proxy breaks the dynamic
 election performed by the cloud.
- **A media box** (e.g. an OSMC / KodiTV) that breaks when its traffic is cached.
- **OCSP certificate checks** (see #9).

**The feature.** In **IP / CIDR Rules**, add the host (or its ASN) with table `nat`
and chain `CUSTOMPREROUTING`, action `ACCEPT`. That rule lets the chosen traffic
exit the NAT stage cleanly, so the proxy never touches it (SQUID CHAIN bypassed)
— while everything else still gets proxied normally.

---

## 5. Per-destination GeoIP exception

**The edge case.** You block a whole country for outbound safety — but one server
inside it is something you actually use. Examples seen in production: SDCard.org
(Japan), Korean TV/phone update servers (LG).

**The feature.** Add that exact destination IP or CIDR in **IP / CIDR Rules** with
action `ACCEPT` on `CUSTOMFORWARD`. It runs before the country block, so your
outbound connection to that one server goes through while the rest of the country
stays blocked. The block stays whole; you punch one clean hole.

---

## 6. WHOIS / RIR keep-open

**The edge case.** You are mid-investigation on an attacker IP. The first thing
you want to do is look up who owns it — but your own aggressive GeoIP outbound
blocking now sits between you and the registries (ARIN, RIPE, APNIC, LACNIC,
AFRINIC), some of which live in ranges you are blocking.

<!-- VERIFY: AFRINIC (Africa) added here for completeness — there are FIVE RIRs, not
     four. Confirm the actual RETURN rule set keeps AFRINIC's WHOIS (TCP 43) and portal
     open too, or this text overstates the feature. -->
**The feature.** A small set of `RETURN` rules keeps WHOIS (TCP 43) and the five
RIR web portals reachable regardless of country blocks. Your investigation tools
keep working even with the strictest GeoIP outbound posture switched on.

---

## 7. DoT keep-reachable

**The edge case.** Your DNS-over-TLS resolver (e.g. Applied Privacy, Austria, port
853) happens to sit in a range that overlaps blocked European hosting — and the
proxy cannot pass TLS-on-853 anyway.

**The feature.** A `RETURN` rule for that exact CIDR on ports 80/443/853 keeps the
resolver reachable and proxy-free. Encrypted DNS keeps resolving; the surrounding
range stays blocked.

---

## 8. Persistent WireGuard handshake log

**The edge case.** You want a syslog line every time someone *attempts* a WireGuard
handshake on your port — for monitoring. The trouble is the WireGuard service wipes
its own chain on every start, reload, and peer change, so a hand-added log rule
disappears with every WG restart/reboot.

**The feature.** Firewall-Local re-installs the log rule from two places — at boot
(rc.local) and on every firewall reload — using a check-before-insert pattern so it never
duplicates. The handshake log survives reboots, firewall reloads.

---

## 9. OCSP keep-reachable

This is a very old case: OCSP is being retired industry-wide in favour of CRLs;
[Ending OCSP Support in August 2025](https://letsencrypt.org/2024/12/05/ending-ocsp)
     
**The old edge case.** Browsers and apps on the network start throwing SSL/certificate
errors. The cause was the proxy mangling OCSP (the certificate-validity check);
OCSP servers reject anything that looks proxied.

**The feature.** A `nat / CUSTOMPREROUTING / ACCEPT` rule for the OCSP responder
lets certificate checks bypass the proxy. OCSP validation works
again across the whole network. Mechanically identical to #4 — listed separately
because this is probably not needed today unless somebody uses OCSP CAs.

---

## 10. Two-direction ASN control

**The edge case.** A cloud ASN is hostile in both directions: it probes you from
outside, *and* you do not want any LAN host quietly phoning home to it (malware
callbacks, phishing C2). One rule only covers one direction.

**The feature.** Add the ASN twice in **ASN Block**: a source block on the early
inbound chain (`BLOCKLISTIN`, stops the probes — see #1) and a destination REJECT
on `FORWARDFW` (stops LAN hosts reaching it). The bad network is sealed off coming
and going.

---

## 11. Outgoing Location Block at scale

**The edge case.** You want to block outbound traffic to a long list of countries — more than 200.
Done the per-country way, each country becomes its own block of
iptables rules, so the list turns into *hundreds of sequential rules* on FORWARDFW
and OUTGOINGFW. That carries two separate costs:
- **Throughput (every packet, always).** Every outbound packet walks those rules
  top to bottom until it matches or falls through — hundreds of comparisons per
  packet. On an older box, this is where it shows up as "slower internet."
- **Load time (once, at firewall start/reload).** Each country's network list has
  to be loaded into the kernel from `/var/lib/location/ipset/`, and the big country
  sets are genuinely large.

**The feature.** The **Outgoing Location Block** module attacks both costs at once:
- It collapses the entire country list into a single set (`GL_BAD_COUNTRIES`)
  matched by just **two** REJECT rules — one on FORWARDFW, one on OUTGOINGFW.
  Per packet, netfilter matches against that one set instead of walking hundreds of
  rules, so throughput stops depending on list length.
- On reload the live set is never torn down. A replacement set is built first, then
`ipset swap` flips it in atomically — so the two REJECT rules always match against
  a complete set and no traffic leaks during the swap. (The swap itself is instant;
  it does not shorten the build — that speed comes from the pre-built ipset files.)

**On low-RAM, SD-backed** IPFire boxes where unbound DBL, and Suricata rules are too
heavy to run, this module gives you a cheap in-kernel network-blocking layer that
those boxes might afford — covering a different gap than those services, not the same one.

---