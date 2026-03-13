#!/bin/bash
#############################################################################
# install.sh - H&M Firewall-Local Installer Script                          #
# VERSION="1.1.1 2026-03-13"                                                #
#############################################################################

# 1. Initialize variables
NAME=${NAME:-"firewall-local"}
ROOTFILES_PATH="./ROOTFILES"

# 2. Source Pakfire library
# shellcheck source=/dev/null
if [ -f "/opt/pakfire/lib/functions.sh" ]; then
    . /opt/pakfire/lib/functions.sh
else
    logger -t "${NAME} INSTALLER" "[ERROR] Pakfire functions missing"
    exit 1
fi

apply_permissions_from_rootfiles() {
    # Function: apply_permissions_from_rootfiles
    # Pseudocode: 
    # 1. Read ROOTFILES.
    # 2. Strip prefix symbols (+ or #) to extract raw path.
    # 3. Apply chown if the path points to an existing file/dir.
    local line
    local target_path

    [ ! -f "${ROOTFILES_PATH}" ] && return 1

    while read -r line || [ -n "${line}" ]; do
        # 1. Strip IPFire prefix symbols (+ and #) and trim whitespace
        target_path=$(echo "${line}" | sed 's/^[+#]//' | xargs)

        # 2. Ignore descriptive comments (lines not starting with etc, usr, var, etc.)
        # and ignore empty lines.
        [[ -z "${target_path}" || ! "${target_path}" =~ ^(etc|usr|var|opt|bin|sbin) ]] && continue

        # 3. Apply ownership if file exists in the system
        if [ -e "/${target_path}" ]; then
            chown root:root "/${target_path}"
            printf "Applied root ownership: /%s\n" "${target_path}"
        fi
    done < "${ROOTFILES_PATH}"
}

register_package() {
    # Function: register_package
    # Pseudocode: 
    # 1. Create the version entry in the installed database.
    # 2. Copy the ROOTFILES to the pakfire database.
    
    local db_dir="/opt/pakfire/db/installed"
    local rf_dir="/opt/pakfire/db/rootfiles"

    # Create directories if missing
    [ ! -d "${db_dir}" ] && mkdir -p "${db_dir}"
    [ ! -d "${rf_dir}" ] && mkdir -p "${rf_dir}"

    # 1. Register Version
    echo "${VERSION}-1" > "${db_dir}/${NAME}"
    
    # 2. Register Rootfiles (Manifest)
    cp -f "./ROOTFILES" "${rf_dir}/${NAME}"
    
    logger -t "INFO" "Package ${NAME} v${VERSION} registered in Pakfire DB."
}

generate_backup_include() {
    # Function: generate_backup_include
    # Pseudocode: Extract only configuration paths from ROOTFILES for the backup system.
    
    local include_file="src/var/ipfire/backup/addons/includes/${NAME}"
    mkdir -p "$(dirname "${include_file}")"

    # Filter ROOTFILES to keep only /etc/sysconfig/fw.local/ files
    grep -E "^[+#]?etc/sysconfig/fw.local/" ROOTFILES | sed 's/^[+#]//' | sed 's/^/\//' > "${include_file}"
    
    logger -t "INFO" "Backup include file generated with $(wc -l < "${include_file}") entries."
}

# 3. Main Execution
extract_files
register_package
generate_backup_include
restore_backup "${NAME}"

# Apply ownership based on ROOTFILES manifest (including preserved config files)
apply_permissions_from_rootfiles

# Restart service
if [ -x "/etc/sysconfig/firewall.local" ]; then
    /etc/sysconfig/firewall.local restart
fi

exit 0