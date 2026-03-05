###############################################################################
# CUSTOM_chains_stop.sh
# Clean CUSTOM* chains where several _start.sh scripts injected rules
# Generated manually by H&M
# Version 1.0 2026-01-19
###############################################################################

# at FW stop it is easier to flush the CUSTOMINPUT and CUSTOMFORWARD chains - it is faster!
iptables --wait -F CUSTOMINPUT 2>/dev/null || true
iptables --wait -F CUSTOMFORWARD 2>/dev/null || true
iptables --wait -F CUSTOMOUTPUT 2>/dev/null || true

