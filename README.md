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
