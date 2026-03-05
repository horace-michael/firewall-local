#!/bin/sh
###############################################################################
# ASN2Block_start.sh
# Modular firewall block for blocking specific ASNs
# Version: 1.0 2026-01-17
# Description: Creates IPSETs and inserts DROP/REJECT rules for malicious ASNs.
# LOG is applied before DROP/REJECT for visibility.
###############################################################################

CHAIN_INPUT="INPUTFW"
CHAIN_FORWARD="FORWARDFW"
LOGCOMMENT_INPUT="ASN2Block INPUTFW"
LOGCOMMENT_FORWARD="ASN2Block FORWARDFW"

ASN2Block=(212238 51852)

for ASN in "${ASN2Block[@]}"; do
    location list-networks-by-as --format=ipset --family=ipv4 ${ASN} > "/etc/ipset/AS${ASN}.ipset"
    ipset restore < "/etc/ipset/AS${ASN}.ipset"

    # INPUT rules
    iptables --wait -t filter -I "${CHAIN_INPUT}" -m set --match-set AS${ASN}v4 src -m limit --limit 10/sec --limit-burst 20 -j LOG --log-prefix "${LOGCOMMENT_INPUT}"
    iptables --wait -t filter -I "${CHAIN_INPUT}" -m set --match-set AS${ASN}v4 src -j DROP

    # FORWARD rules
    iptables --wait -t filter -I "${CHAIN_FORWARD}" -m set --match-set AS${ASN}v4 dst -m limit --limit 10/sec --limit-burst 20 -j LOG --log-prefix "${LOGCOMMENT_FORWARD}"
    iptables --wait -t filter -I "${CHAIN_FORWARD}" -m set --match-set AS${ASN}v4 dst -j REJECT --reject-with icmp-port-unreachable
done
