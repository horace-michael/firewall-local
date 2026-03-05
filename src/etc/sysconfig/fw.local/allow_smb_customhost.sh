#!/bin/sh
###############################################################################
# allow_smb_customhost.sh
#
# IPFire Modular Firewall Helper
#
# Version: 1.0 2026-01-17
#
# Description:
#   Allows SMB / SAMBA access for a specific host defined in
#   /var/ipfire/fwhosts/customhosts.
#
#   The script takes ONE argument: a (partial) hostname.
#   It resolves the host to an IP (type=ip) and inserts ACCEPT rules
#   in CUSTOMFORWARD for SMB-related ports.
#
# Usage:
#   allow_smb_customhost.sh <hostname-fragment> <destination-ip>
#
# Example:
#   allow_smb_customhost.sh T15 192.168.10.2
#
###############################################################################

set -e

HOSTS_FILE="/var/ipfire/fwhosts/customhosts"
CHAIN="CUSTOMFORWARD"
SMB_PORTS="135,137,138,139,445,1025"

if [ $# -ne 2 ]; then
    echo "ERROR: Invalid arguments"
    echo "Usage: $0 <hostname-fragment> <destination-ip>"
    exit 1
fi

HOST_FRAGMENT="$1"
DEST_IP="$2"

echo "[SMB] Resolving host matching: ${HOST_FRAGMENT}"

MATCH=$(grep -i "${HOST_FRAGMENT}" "${HOSTS_FILE}" | grep ',ip,' | head -n1)

if [ -z "${MATCH}" ]; then
    echo "ERROR: No IP-based host found for '${HOST_FRAGMENT}'"
    exit 1
fi

SRC_IP=$(echo "${MATCH}" | awk -F',' '{print $4}' | cut -d'/' -f1)
HOST_NAME=$(echo "${MATCH}" | awk -F',' '{print $2}')

if [ -z "${SRC_IP}" ]; then
    echo "ERROR: Failed to extract source IP"
    exit 1
fi

echo "[SMB] Host resolved:"
echo "      Name : ${HOST_NAME}"
echo "      IP   : ${SRC_IP}"
echo "      Dest : ${DEST_IP}"

echo "[SMB] Inserting SMB rules into ${CHAIN}"

iptables --wait -t filter -A "${CHAIN}" \
    -p tcp -m multiport --dports ${SMB_PORTS} \
    -s "${SRC_IP}" -d "${DEST_IP}" \
    -j ACCEPT

iptables --wait -t filter -A "${CHAIN}" \
    -p udp -m multiport --dports ${SMB_PORTS} \
    -s "${SRC_IP}" -d "${DEST_IP}" \
    -j ACCEPT

echo "[SMB] Rules successfully installed for ${HOST_NAME}"
