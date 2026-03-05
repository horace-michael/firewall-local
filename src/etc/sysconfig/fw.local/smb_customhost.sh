#!/bin/sh
###############################################################################
# smb_customhost.sh
#
# IPFire Modular Firewall Helper - SMB Allow / Block
#
# Version: 1.0 2026-01-17
#
# Description:
#   Applies SMB rules (ALLOW or BLOCK) for a host defined in
#   /var/ipfire/fwhosts/customhosts.
#
# Usage:
#   smb_customhost.sh allow <hostname-fragment> <destination-ip>
#   smb_customhost.sh block <hostname-fragment> <destination-ip>
#
###############################################################################

set -e

HOSTS_FILE="/var/ipfire/fwhosts/customhosts"
CHAIN="CUSTOMFORWARD"
SMB_PORTS="135,137,138,139,445,1025"

ACTION="$1"
HOST_FRAGMENT="$2"
DEST_IP="$3"

if [ $# -ne 3 ]; then
    echo "Usage: $0 <allow|block> <host-fragment> <destination-ip>"
    exit 1
fi

MATCH=$(grep -i "${HOST_FRAGMENT}" "${HOSTS_FILE}" | grep ',ip,' | head -n1)

if [ -z "${MATCH}" ]; then
    echo "[SMB] WARN: No IP host found for ${HOST_FRAGMENT}"
    exit 0
fi

SRC_IP=$(echo "${MATCH}" | awk -F',' '{print $4}' | cut -d'/' -f1)
HOST_NAME=$(echo "${MATCH}" | awk -F',' '{print $2}')

echo "[SMB] ${ACTION^^} | ${HOST_NAME} (${SRC_IP}) → ${DEST_IP}"

case "${ACTION}" in
    allow)
        TARGET="ACCEPT"
        ;;
    block)
        TARGET="DROP"
        ;;
    *)
        echo "Invalid action: ${ACTION}"
        exit 1
        ;;
esac

iptables --wait -t filter -A "${CHAIN}" \
    -p tcp -m multiport --dports ${SMB_PORTS} \
    -s "${SRC_IP}" -d "${DEST_IP}" -j "${TARGET}"

iptables --wait -t filter -A "${CHAIN}" \
    -p udp -m multiport --dports ${SMB_PORTS} \
    -s "${SRC_IP}" -d "${DEST_IP}" -j "${TARGET}"
