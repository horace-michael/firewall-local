#!/bin/bash
###############################################################################
# transparent_proxy_bypass_start.sh
# Transparent proxy bypass
# Modular firewall block for bypassing a certain IP from proxy inspection
# Version: 1.0 2026-01-17
# Reason: certificate validation / CRL / OCSP failures via proxy
# NO LOG
###############################################################################

set -u

SCRIPT_NAME="$(basename "$0")"
BASE_DIR="/root/.sysconfig/firewall.local"
HOSTS_FILE="$BASE_DIR/transparent_proxy_bypass.hosts"

TABLE="nat"
CHAIN="CUSTOMPREROUTING"

log() {
    logger -t "FWLOCAL:$SCRIPT_NAME" "$1"
    echo "FWLOCAL:$SCRIPT_NAME: $1"
}

log "Starting transparent proxy bypass"

# sanity checks
if [ ! -f "$HOSTS_FILE" ]; then
    log "No helper file found ($HOSTS_FILE) – nothing to do"
    exit 0
fi

if ! iptables --wait -t "$TABLE" -L "$CHAIN" >/dev/null 2>&1; then
    log "ERROR: chain $CHAIN not found in $TABLE table"
    exit 1
fi

# process destinations
while IFS= read -r DEST; do
    # strip comments & whitespace
    DEST="$(echo "$DEST" | sed 's/#.*//g' | xargs)"

    [ -z "$DEST" ] && continue

    log "Processing bypass destination: $DEST"

    if iptables --wait -t "$TABLE" -C "$CHAIN" -d "$DEST" -j ACCEPT 2>/dev/null; then
        log "Rule already exists for $DEST – skipping"
        continue
    fi

    iptables --wait -t "$TABLE" -A "$CHAIN" -d "$DEST" -j ACCEPT

    if [ $? -eq 0 ]; then
        log "Bypass enabled for $DEST"
    else
        log "ERROR: failed to add bypass rule for $DEST"
    fi

done < "$HOSTS_FILE"

log "Transparent proxy bypass initialization complete"
exit 0
