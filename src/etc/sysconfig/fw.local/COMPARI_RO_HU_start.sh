#!/bin/sh
###############################################################################
# $FILENAME
# Firewall exception: compari.ro (Magyar Telekom – HU)
# Version: 2026-01-17
###############################################################################

# compari.ro – Magyar Telekom
# Netblock: 80.249.160.0/20
# Known IPs:
#  - 80.249.166.53
#  - 80.249.166.54
#  - 80.249.166.55
#  - 80.249.166.56
#  - 80.249.166.134

iptables --wait -t filter -A CUSTOMFORWARD -p tcp -m multiport --dports 80,443 -d 80.249.160.0/20 -j ACCEPT
iptables --wait -t filter -A CUSTOMOUTPUT  -p tcp -m multiport --dports 80,443 -d 80.249.160.0/20 -j ACCEPT
