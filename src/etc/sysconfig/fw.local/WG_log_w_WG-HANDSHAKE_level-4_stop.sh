###############################################################################
# WG_log_w_WG-HANDSHAKE_level-4_stop.sh
# Stop WireGuard WG handshake logging
# Generated manually by H&M 
# Version 1.0 2026-01-19
###############################################################################

# Show existing rules in WGINPUT and put numbers to each
# iptables --wait -L WGINPUT --line-numbers

# Remove WireGuard WG handshake logging 
iptables --wait -D WGINPUT -p udp --dport 1195 -m state --state NEW -j LOG --log-prefix "WG-HANDSHAKE: " --log-level 4
#iptables --wait -D WGINPUT -p udp --dport 1195 -j ACCEPT
