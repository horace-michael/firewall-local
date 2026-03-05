#!/bin/bash
###############################################################################
# sync_from_legacy.sh - H&M Project Migration Tool
# Version: 2026-03-05
###############################################################################

# Function: sync_legacy_assets
# Pseudocode: 
# 1. Initialize local path variables.
# 2. Verify source existence.
# 3. Synchronize files to the new 'src' hierarchy.
sync_legacy_assets() {
    local legacy_dir
    local target_dir

    legacy_dir="${HOME}/GIT_98c71be8/MyScripts/Linux_Scripts/ipfire/etc/sysconfig"
    target_dir="src/etc/sysconfig"

    # Jack Reacher Rule: Assumption kills! Check if source exists.
    if [ ! -d "${legacy_dir}" ]; then
        printf "ERROR: Source directory %s not found.\n" "${legacy_dir}"
        return 1
    fi

    # Create structure if missing
    mkdir -p "${target_dir}/fw.local/hosts"

    # Perform Sync
    cp -v "${legacy_dir}/firewall.local" "${target_dir}/"
    cp -v "${legacy_dir}/fw.local/"*.sh "${target_dir}/fw.local/"
    cp -v "${legacy_dir}/fw.local/"*.hosts "${target_dir}/fw.local/hosts/"
}

sync_legacy_assets