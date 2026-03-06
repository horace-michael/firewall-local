# H&M IPFire Firewall-Local

Custom firewall management system for IPFire, structured for modularity and scalability.

## 📂 Project Structure
* **src/etc/sysconfig/firewall.local**: Main entry point for IPFire.
* **src/etc/sysconfig/fw.local/**: Modular start/stop scripts.
* **src/etc/sysconfig/fw.local/hosts/**: Static IP/network definition files.
* **src/usr/local/bin/**: Shared logic and helper functions.
* **scripts/**: Development and migration utilities.

## 🚀 Deployment
Scripts are designed to be symlinked or copied to the root filesystem on an IPFire installation.

```text
firewall-local/ (master)
├── .gitignore
├── scripts/
│   └── sync_from_legacy.sh
└── src/
    └── etc/
        └── sysconfig/
            ├── firewall.local
            └── fw.local/
                ├── hosts/
                │   ├── allow_smb.hosts
                │   ├── block_smb.hosts
                │   ├── target_smb.hosts
                │   └── transparent_proxy_bypass.hosts
                ├── SCRIPT_1_start.sh
                ├── ASN2Block_start.sh
                ├── ASN2Block_stop.sh
                ├── SCRIPT_2_start.sh
                ├── ... (26 modules total) ...
                └── SCRIPT_N_stop.sh
```