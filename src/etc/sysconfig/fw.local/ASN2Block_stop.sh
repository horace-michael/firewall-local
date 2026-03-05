#!/bin/sh
###############################################################################
# ASN2Block_stop.sh
# Modular firewall block for blocking specific ASNs
# Version: 1.0 2026-01-17
# Description: Removes DROP/REJECT rules for malicious ASNs.
# Only removes rules if the corresponding IPSET exists in memory.
# Ensures LOG precedes DROP/REJECT in removal.
###############################################################################

CHAIN_INPUT="INPUTFW"
CHAIN_FORWARD="FORWARDFW"
LOGCOMMENT_INPUT="ASN2Block INPUTFW"
LOGCOMMENT_FORWARD="ASN2Block FORWARDFW"

ASN2Block=(212238 51852)

for ASN in "${ASN2Block[@]}"; do
    # Check if the IPSET exists in kernel memory
    if ipset list AS${ASN}v4 >/dev/null 2>&1; then

        # Remove INPUT rules (LOG and DROP)
        iptables --wait -t filter -D "${CHAIN_INPUT}" -m set --match-set AS${ASN}v4 src -m limit --limit 10/sec --limit-burst 20 -j LOG --log-prefix "${LOGCOMMENT_INPUT}" 2>/dev/null
        iptables --wait -t filter -D "${CHAIN_INPUT}" -m set --match-set AS${ASN}v4 src -j DROP 2>/dev/null

        # Remove FORWARD rules (LOG and REJECT)
        iptables --wait -t filter -D "${CHAIN_FORWARD}" -m set --match-set AS${ASN}v4 dst -m limit --limit 10/sec --limit-burst 20 -j LOG --log-prefix "${LOGCOMMENT_FORWARD}" 2>/dev/null
        iptables --wait -t filter -D "${CHAIN_FORWARD}" -m set --match-set AS${ASN}v4 dst -j REJECT --reject-with icmp-port-unreachable 2>/dev/null

        # Destroy the IPSET in memory
        ipset destroy AS${ASN}v4
    fi
done
