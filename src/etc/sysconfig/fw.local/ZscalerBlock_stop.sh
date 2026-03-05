#!/bin/sh
###############################################################################
# ZscalerBlock_stop.sh
# Modular firewall block for IPSET Zscaler ASN
# Version: 1.0 2026-01-17
# Description: Removes iptables --wait rules and destroys IPSET for Zscaler ASNs.
# Only removes rules if the corresponding IPSET exists in memory.
###############################################################################

CHAIN="CUSTOMPREROUTING"
LOGCOMMENT="** Zscaler ASN CUSTOMPREROUTING **"

ASNs=(22616 32921 40384 53444 53813 55242 62044 62907)

for ASN in "${ASNs[@]}"; do
    # Check if the IPSET exists in kernel memory
    if ipset list AS${ASN}v4 >/dev/null 2>&1; then

        # Delete LOG and ACCEPT rules
        iptables --wait -t nat -D "${CHAIN}" -m set --match-set AS${ASN}v4 dst -m limit --limit 10/sec --limit-burst 20 -j LOG --log-prefix "${LOGCOMMENT}" 2>/dev/null
        iptables --wait -t nat -D "${CHAIN}" -m set --match-set AS${ASN}v4 dst -j ACCEPT 2>/dev/null

        # Flush and destroy IPSET
        ipset flush AS${ASN}v4
        ipset destroy AS${ASN}v4
    fi
done
