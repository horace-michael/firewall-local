#!/bin/sh
###############################################################################
# ZscalerBlock_start.sh
# Modular firewall block for IPSET Zscaler ASN
# Version: 1.0 2026-01-17
# Description: Recreates IPSET for Zscaler ASNs and inserts iptables --wait rules.
# LOG is applied before ACCEPT for visibility.
###############################################################################

CHAIN="CUSTOMPREROUTING"
LOGCOMMENT="** Zscaler ASN CUSTOMPREROUTING **"

ASNs=(22616 32921 40384 53444 53813 55242 62044 62907)

for ASN in "${ASNs[@]}"; do
    # Recreate ipset file
    location list-networks-by-as --format=ipset --family=ipv4 ${ASN} > "/etc/ipset/AS${ASN}.ipset"
    
    # Restore ipset to kernel
    ipset restore < "/etc/ipset/AS${ASN}.ipset"

    # LOG first
    iptables --wait -t nat -I "${CHAIN}" -m set --match-set AS${ASN}v4 dst -m limit --limit 10/sec --limit-burst 20 -j LOG --log-prefix "${LOGCOMMENT}"

    # Then ACCEPT
    iptables --wait -t nat -I "${CHAIN}" -m set --match-set AS${ASN}v4 dst -j ACCEPT
done
