# Changelog - Firewall-Local

## [1.3.1] - 2026-03-15

### Added
- **Build System:** Implemented dynamic directory discovery in `make-package.sh` to automatically include `etc`, `usr`, and `var` from `src/`.
- **Build System:** Added `shellcheck disable=SC2086` to handle intentional word splitting for `tar` arguments.
- **Resilience:** Added a fallback mechanism to create a valid payload even if the source directory is empty, preventing build failure.

### Changed
- **Build Logic:** Refactored `tar` execution to use explicit directory names instead of relative `.` (dot) paths. This ensures compatibility with IPFire's native `extract_backup_includes` function by removing the leading `./` prefix.
- **Debug Logic:** Redirected environment integrity check messages to `STDERR`.
- **Logic:** Isolated `STDOUT` for functions returning values (like IP resolution) to prevent "Variable Pollution" when `DEBUG=true` is enabled.

### Fixed
- **Path Matching:** Resolved "Not found in archive" error during `update.sh` by aligning archive internal structure with Pakfire standards.
- **SMB Resolution:** Fixed `iptables` execution errors caused by debug strings being captured into IP address variables.

## [1.3.0] - 2026-03-13

### Added
- **Build System:** Updated `make-roortfiles.sh` to generate `ROOTFILES`.
- **Build System:** Updated `make-package.sh` to run from the `scripts/` directory with "Base 0" relative pathing to `src/` and `ROOTFILES`.
- **Self-Indexing Build**: `make-package.sh` now generates backup includes from source files *before* indexing, ensuring no orphaned files exist post-uninstallation.
- **Permission Sanitization:** Integrated a "Least Privilege" permission fix (755/600) directly into the `make-package.sh` build flow to ensure security-by-default on deployment.
- **Full Lifecycle Integration**: `install.sh` now bridges the gap between raw file extraction and official Pakfire package status.
- **Permission Logic**: Ownership is now applied to all project files listed in `ROOTFILES`, including those marked for configuration preservation (`#`).
- **Dependency Handling**: Standardized logger calls to ensure the installer remains functional even before the core library is linked.
- **Backup Persistence**: Integrated `extract_backup_includes` in `install.sh` to ensure SST master lists are captured by the IPFire Backup System (.ipf).
- **Smart Backup Filtering**: Implemented selective inclusion for the backup manifest, ensuring only configuration data (/etc/) is backed up, excluding static binaries.
- **Package Registration**: Standardized the duplication of ROOTFILES into `/opt/pakfire/db/rootfiles/` to ensure full Pakfire compliance and clean uninstallation paths.

### Fixed
- **Kernel Locking**: Eliminated the inability to destroy sets under active `iptables` rules via the Atomic Swap mechanism.
- **Environment Validation**: Integrated mandatory IPFire integrity checks before rule application.

### Changed
- **Modular Sourcing Refactor**: Resigned `run_scripts` to use sourcing (`. "$script"`) instead of sub-shell execution (`bash -c`).
  - *Result:* Modular scripts now successfully inherit the `firewall_functions` library.
- **ShellCheck Compliance**: Fixed all Severity 4 warnings (SC1090/SC1091) using explicit linter directives.
- **Atomic IPSet Swap Logic**: Implemented `generate_ipset_from_asn_list` using a temporary set and `ipset swap`. This enables zero-downtime updates and bypasses the "Set in use" kernel lock.
- **RAM-First Persistence**: Moved away from static `/etc/ipset` files to a dynamic, memory-resident IPSet structure.
- **SST (Single Source of Truth) Orchestration**: Rewrote `firewall.local` to prioritize Master Lists (ASN, IP, SMB) before executing modular scripts.
- **Syslog Audit Trail**: All core actions (sourcing, swapping, errors) now log to `/var/log/messages` via `FIREWALL_LOCAL` tag.


## [Logic Flow] Atomic IPSet Update Mechanism (v3.3.0)

To bypass the kernel lock (`Set cannot be destroyed: it is in use`), the function `generate_ipset_from_asn_list` implements an atomic swap instead of a direct rename or delete.

### Step-by-Step Execution `generate_ipset_from_asn_list`:

1.  **Stage: Preparation** Initialize a unique temporary name: `${target_name}_tmp`.
2.  **Stage: Data Transformation** Execute `location list-networks-by-as` -> Save the modified result to the `.ipset` file.
3.  **Stage: Memory Load** Run `ipset restore < file` -> The kernel now has the new data in memory under the **temporary name**, while the **live name** remains untouched and active in `iptables`.
4.  **Stage: Atomic Decision (The "Switch"):** **IF** `target_name` (Live) already exists:
        * Execute `ipset swap temp_name target_name`-> `iptables` now instantly points to the new data.
        * Execute `ipset destroy temp_name` (cleans up the old data now sitting in the temp slot).
    * **ELSE** (First run):
        * Execute `ipset rename temp_name target_name`-> The set is promoted to Live status.
5.  **Stage: Cleanup**
    * Remove the temporary file from `/tmp/`.
    * Log completion event to syslog.

## [1.2.0] - 2026-03-06
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


## [1.1.0] - 2026-03-06
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

## [1.0.0] - 2026-03-05
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

## [0.5.2] - 2026-02-09
### Description
- Modular firewall loader designed for IPFire.
- Execution of `*_start.sh` and `*_stop.sh` scripts from base directory.
- Dedicated logging to `/var/log/firewall.local.log`.
- Removal of iptables retry logic and runlevel dependencies.
- Transitioned `CUSTOM*` chain cleanup to `CUSTOM_chains_stop.sh`.