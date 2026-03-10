# Changelog - Firewall-Local

## [3.2.0] - 2026-03-06
### Added
- **IP Master List Architecture**: Introduced `ip_master.list` as the Single Source of Truth for centralizing IP/CIDR-based firewall policies. This also holds the lines for Transparent proxy Bypass
- **SMB Master List Architecture**: Introduced `smb_master.list` as the Single Source of Truth for centralizing SMB firewall policies.
- **FIREWALL_FUNCTIONS**: Created `rprocess_ip_line` and `process_ip_master_l` for processing `ip_master.list`. Function can hanle IP or CIDR, one or multiple ports, any table, any chain. Because of this it can aslo handle Transparent Proxy Bypass (nat table)
- **FIREWALL_FUNCTIONS**: Created `resolve_smb_source_ip` and `process_smb_master_lis` for extracting IP from IPFire custom host and use that to allow SMB traffic.


### `ip_master.list` Structure
#### PATH: /etc/sysconfig/fw.local/hosts/ip_master.list
#### Version: 3.2.0 (Agnostic IP/Port)
#### FIELDS:
#### 1. OBJECT: IP, CIDR, or IPset Name (from a .hosts filename).
#### 2. TABLE:  filter / nat
#### 3. ACTION: ACCEPT / DROP / REJECT / RETURN
#### 4. DIR:    src / dst (determines if object is used for -s or -d)
#### 5. PROTO:  tcp / udp / all
#### 6. PORT:   Port, range (80:443), multiport (80,443) or 'all'
#### 7. CHAINS: Space-separated list of chains

#### ---------------------------------------------------------------------------------------
#### OBJECT            TABLE   ACTION  DIR  PROTO  PORT          CHAINS
#### -------------------------------------------------------------------------------------

### `smb_master.list` Structure
#### PATH: /etc/sysconfig/fw.local/hosts/ip_master.list
#### Version: 3.2.0 (Agnostic IP/Port)
#### FIELDS:
#### 1. Source/FROM: Host Fragment to be used for serach (fragment from a host filename).
#### 2. ACTION: ACCEPT / DROP / REJECT / RETURN
#### 3. IP address where SMB traffic should be allowed by IPFire
#### ---------------------------------------------------------------------------------------
#### Host_Fragment    ACTION    IP_DEST
#### ---------------------------------------------------------------------------------------


## [3.1.0] - 2026-03-06
### Added
- **Polymorphic IPset Engine**: Implemented `apply_ipset_in_table_chain_action_src_or_dst` to support multi-table (filter/nat) and multi-chain rule injection with dynamic directionality (src/dst).
- **Atomic IPset Generation**: Added `generate_ipset_from_asn_list` using `ipset restore` and `rename` for zero-downtime kernel updates.
- **Hardened Parser**: Created `process_firewall_master_list` featuring environmental validation and kernel-level IPset existence checks.
- **Master List Architecture**: Introduced `asn_master.list` as the Single Source of Truth for centralizing ASN-based firewall policies.

### `asn_master.list` Structure
#### PATH: /etc/sysconfig/fw.local/hosts/asn_master.list
####
##### FIELDS:
##### 1. ASN:    The Autonomous System Number (numeric) or a custom Alias. 
#####            The system automatically prefixes this with 'AS' and suffixes with 'v4'.
##### 2. TABLE:  The iptables table to target (usually 'filter' or 'nat').
##### 3. ACTION: The iptables jump target (e.g., DROP, REJECT, RETURN).
##### 4. DIR:    Direction of matching. Use 'src' for source or 'dst' for destination.
##### 5. LOG:    Boolean (true/false). If true, a LOG rule is placed before the action.
##### 6. CHAINS: Space-separated list of iptables chains where the rule should apply.
#####
##### ----------------------------------------------------------------------------------
##### ASN       TABLE   ACTION   DIR   LOG     CHAINS
##### ----------------------------------------------------------------------------------

##### Example: Block incoming traffic from specific ASN
####  212238      filter  DROP     src   true    INPUTFW

##### Example: Reject outgoing traffic to specific ASN
####  212238      filter  REJECT   dst   true    FORWARDFW

##### Example: Bypass Proxy/GeoIP for Privacy Provider (Friend)
####  208323      filter  RETURN   dst   false   FORWARDFW CUSTOMFORWARD

##### Example: Custom Alias for Alibaba CN exceptions
####    ALIBABA_CN  filter  RETURN   dst   false   CUSTOMFORWARD CUSTOMOUTPUT

---

## [3.0.0] - 2026-03-05
### Added
- Centralized library `/usr/local/bin/firewall_functions` for shared logic management.
- New `log_event` function providing dual-logging to `/var/log/messages` and terminal.
- Automated file presence validation prior to execution (Jack Reacher Rule).
- Migration of 26 firewall modules (e.g., ALIBABA, REVOLUT, ASN2Block) to `src/etc/sysconfig/fw.local/`.

### Changed
- Refactored `firewall.local` to eliminate redundancy via external library sourcing.
- Aligned `DEBUG` logic with `make-package.sh` standard: `[ "${DEBUG}" = true ]`.
- Incremented version to 3.0.0 to reflect structural architectural changes.

---

## [2.5.2] - 2026-02-09
### Description
- Modular firewall loader designed for IPFire.
- Execution of `*_start.sh` and `*_stop.sh` scripts from base directory.
- Dedicated logging to `/var/log/firewall.local.log`.
- Removal of iptables retry logic and runlevel dependencies.
- Transitioned `CUSTOM*` chain cleanup to `CUSTOM_chains_stop.sh`.