#!/bin/sh
###############################################################################
# smb_hosts_start.sh
#
# IPFire Modular Firewall - SMB Hosts Loader
#
# Version: 1.0 2026-01-17
#
# Description:
#   Loads SMB allow/block rules from declarative host lists.
#   - block_smb.hosts has PRIORITY over allow_smb.hosts
#   - SMB target IPs are loaded from target_smb.hosts
#
###############################################################################

BASEPATH="/root/.sysconfig/firewall.local"

ALLOW_FILE="${BASEPATH}/allow_smb.hosts"
BLOCK_FILE="${BASEPATH}/block_smb.hosts"
TARGET_FILE="${BASEPATH}/target_smb.hosts"

ENGINE="${BASEPATH}/smb_customhost.sh"

echo "FWLOCAL: Loading SMB host rules"
echo "FWLOCAL: Basepath: ${BASEPATH}"

# --- sanity checks -----------------------------------------------------------
[ -x "${ENGINE}" ] || {
    echo "FWLOCAL ERROR: smb_customhost.sh not executable"
    exit 1
}

[ -f "${TARGET_FILE}" ] || {
    echo "FWLOCAL ERROR: target_smb.hosts not found"
    exit 1
}

# --- load target IPs ----------------------------------------------------------
DEST_IPS=$(grep -v '^\s*#' "${TARGET_FILE}" | grep -v '^\s*$')

if [ -z "${DEST_IPS}" ]; then
    echo "FWLOCAL ERROR: No SMB targets defined"
    exit 1
fi

echo "FWLOCAL: SMB targets:"
for IP in ${DEST_IPS}; do
    echo "  - ${IP}"
done

# --- helper ------------------------------------------------------------------
process_file() {
    ACTION="$1"
    FILE="$2"

    [ -f "${FILE}" ] || return 0

    while read -r HOST; do
        HOST=$(echo "${HOST}" | sed 's/#.*//')
        [ -z "${HOST}" ] && continue

        echo "FWLOCAL: SMB ${ACTION} for host '${HOST}'"

        for DEST in ${DEST_IPS}; do
            "${ENGINE}" "${ACTION}" "${HOST}" "${DEST}"
        done
    done < "${FILE}"
}

# --- execution order ----------------------------------------------------------
process_file block "${BLOCK_FILE}"
process_file allow "${ALLOW_FILE}"

echo "FWLOCAL: SMB rules loaded successfully"
