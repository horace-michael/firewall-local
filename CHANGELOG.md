# Changelog - Firewall-Local

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