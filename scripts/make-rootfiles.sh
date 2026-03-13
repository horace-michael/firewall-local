#!/bin/bash
###############################################################################
# make-rootfiles.sh - H&M Project Utility
# Version: 2026-03-13 1.0
###############################################################################

# Function: generate_rootfiles
# Pseudocode:
# 1. Clear existing manifest.
# 2. Iterate 'src' files; remove 'src/' prefix.
# 3. Use '#' prefix for persistent configs (hosts/*.list, hosts/*.hosts).
generate_rootfiles() {
    local manifest="ROOTFILES"
    local source_dir="src"
    local line_path=""

    # Header - Overwrite old manifest
    printf "# firewall-local manifest\\n# Generated: %s\\n\\n" "$(date)" > "$manifest"

    # Process files using a while loop to handle paths safely
    find "$source_dir" -type f | while read -r line_path; do
        # Strip the 'src/' prefix
        local relative_path="${line_path#$source_dir/}"

        # Logic: If file is in 'hosts' or is a .list, mark as config (#)
        # Persistent files are NOT deleted on upgrade/uninstall.
        if [[ "$relative_path" == *"/hosts/"* ]]; then
            echo "#$relative_path" >> "$manifest"
        else
            echo "$relative_path" >> "$manifest"
        fi
    done

    # Sort manifest for consistency (excluding header)
    sort -u -o "$manifest" "$manifest"
}

generate_rootfiles