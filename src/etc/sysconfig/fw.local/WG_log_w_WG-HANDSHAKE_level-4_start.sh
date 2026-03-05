###############################################################################
# WG_log_w_WG-HANDSHAKE_level-4_start.sh
# Start logging for  WireGuard WG handshake - NEW packets seen by FW
# Generated manually by H&M
# Version 1.0 2026-01-19
###############################################################################

#Log WireGuard WG start of session with log-prefix WG-HANDSHAKE
if iptables --wait -t filter -C WGINPUT -p udp --dport 1195 -m state --state NEW -j LOG --log-prefix "WG-HANDSHAKE: " --log-level 4 2>/dev/null; then
    boot_mesg "Rule already exists for WG-HANDSHAKE – skipping"
else
    iptables --wait -I WGINPUT -p udp --dport 1195 -m state --state NEW -j LOG --log-prefix "WG-HANDSHAKE: " --log-level 4
    #iptables --wait -A WGINPUT -p udp --dport 1195 -j ACCEPT
fi

