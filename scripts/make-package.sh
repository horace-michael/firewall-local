#!/bin/bash
#################################################################################
# make-package.sh - Firewall-Local Build Utility                                #
# VERSION="1.0.0 2026-03-13"                                                    #
#                                                                               #
# MIT License                                                                   #
#                                                                               #
# Copyright (c) 2026 H&M                                                        #
#                                                                               #
# Permission is hereby granted, free of charge, to any person obtaining a copy  #
# of this software and associated documentation files (the "Software"), to deal #
# in the Software without restriction, including without limitation the rights  #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     #
# copies of the Software, and to permit persons to whom the Software is         #
# furnished to do so, subject to the following conditions:                      #
#                                                                               #
# The above copyright notice and this permission notice shall be included in all#
# copies or substantial portions of the Software.                               #
#                                                                               #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE #
# SOFTWARE.                                                                     #
#################################################################################

# 1. Initialize variables (Base 0)
DEBUG="${DEBUG:-false}"
NAME="firewall-local"
VERSION="1.0.0"
AUTHOR="H&M"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${REPO_ROOT}/src"
MANIFEST="${REPO_ROOT}/ROOTFILES"
PACKAGE_NAME="${NAME}-v${VERSION}.ipfire"
PAYLOAD_NAME="files.tar.xz"

# 2. Define functions
check_files_from_manifest() {
    # Pseudocode: Verify manifest presence and physical file existence
    [ "${DEBUG}" = true ] && printf "[DEBUG] Validating manifest: %s\n" "${MANIFEST}"

    [ ! -s "${MANIFEST}" ] && { printf "ERROR: Manifest empty\n"; exit 1; }

    while read -r line || [ -n "${line}" ]; do
        [[ "$line" =~ ^#.* || -z "$line" ]] && line="${line#\#}"
        if [ ! -f "${SRC_DIR}/${line}" ]; then
            printf "ERROR: Missing file from manifest: %s\n" "${SRC_DIR}/${line}"
            exit 1
        fi
    done < "${MANIFEST}"
    [ "${DEBUG}" = true ] && printf "[DEBUG] Integrity checks passed.\n"
}

sanitize_build_perms() {
    # Pseudocode: Apply 755/700/600 bits to src directory before packing
    [ "${DEBUG}" = true ] && printf "[DEBUG] Sanitizing permissions in %s\n" "${SRC_DIR}"
    
    # Executables & Folders
    # 1. Standard directories: 755 (traversable by system services)
    find "${SRC_DIR}" -type d -not -path '*/.*' -exec chmod 755 {} +
    # 2. Any Scripts: 755 (must be executable)
    find "${SRC_DIR}" -type f -name "*.sh" -exec chmod 755 {} +
    # Configs & Libs
    # 3. Master Lists: 600 (Strictly root only)
    find "${SRC_DIR}" -type f \( -name "*.list" -o -name "*.hosts" \) -exec chmod 600 {} +
    # 4. firewall_functions 600 because we aonly source it - nobody should change it or read it apart from root
    [ -f "${SRC_DIR}/usr/local/bin/firewall_functions" ] && chmod 600 "${SRC_DIR}/usr/local/bin/firewall_functions"
    # 4. firewall.local 755 (standard ipfire)
    [ -f "${SRC_DIR}/etc/sysconfig/firewall.local" ] && chmod 755 "${SRC_DIR}/etc/sysconfig/firewall.local"
}

build_package() {
    # Pseudocode: Create tar.xz from src and wrap into .ipfire with control scripts
    cd "${REPO_ROOT}" || exit 1

    [ "${DEBUG}" = true ] && printf "[DEBUG] Creating payload: %s\n" "${PAYLOAD_NAME}"
    # Use --transform to strip 'src/' prefix during tar creation
    tar -cJf "${PAYLOAD_NAME}" -C "${SRC_DIR}" .

    [ "${DEBUG}" = true ] && printf "[DEBUG] Final assembly: %s\n" "${PACKAGE_NAME}"
    tar -cvf "${PACKAGE_NAME}" install.sh update.sh uninstall.sh ROOTFILES "${PAYLOAD_NAME}"
    
    rm -f "${PAYLOAD_NAME}"
}

generate_backup_includes() {
    # Function: generate_backup_includes
    # Logic: Scan src/etc and generates a backup include file for the backup system, ensuring only config files are included.
    local include_dir="${SRC_DIR}/var/ipfire/backup/addons/includes"
    local include_file="${include_dir}/${NAME}"

    mkdir -p "${include_dir}"
    # Only backup files from /etc/ (configs), add leading slash
    if [ -d "${SRC_DIR}/etc" ]; then
        find "${SRC_DIR}/etc" -type f | sed "s|${SRC_DIR}/|/|" > "${include_file}"
    fi
    [ "${DEBUG}" = true ] && printf "[DEBUG] Generated backup includes: %s\n" "${include_file}"
}

sync_versioning() {
    # Function: sync_versioning
    # Pseudocode: Inject current version into installer and manifest.
    
    # Update version in install.sh
    sed -i "s/^VERSION=.*/VERSION=\"${VERSION}\"/" src/install.sh
    # Update timestamp in ROOTFILES
    #sed -i "s/^# Generated:.*/# Generated: $(date)/" ROOTFILES
}

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
        local relative_path="${line_path#"$source_dir"/}"

        # Logic: If file is in 'hosts' or is a .list, mark as config (#)
        # Persistent files are NOT deleted on upgrade/uninstall.
        if [[ "$relative_path" == *"/hosts/"* ]]; then
            echo "#$relative_path" >> "$manifest"
        else
            echo "$relative_path" >> "$manifest"
        fi
    done

    # Sort manifest for consistency (excluding header)
    (head -n 2 "$manifest" && tail -n +3 "$manifest" | sort -u) > "${manifest}.tmp" && mv "${manifest}.tmp" "$manifest"
    # Ensure file is written and sorted before next function reads it
    sync
}

generate_checksum() {
    # Function: generate_checksum
    # Pseudocode: Create SHA256 hash for the final .ipfire package.
    sha256sum "${PACKAGE_NAME}" > "${PACKAGE_NAME}.sha256"
}

parse_args() {
    # Pseudocode: Loop through arguments and assign values to variables
    # Based on apache init script structure
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            -D|--debug)
                DEBUG=true
                shift
                ;;
            -n|--name)
                PACKAGE_NAME="${2}"
                shift 2
                ;;
            -p|--payload)
                PAYLOAD_NAME="${2}"
                shift 2
                ;;
            -h|--help)
                printf "Usage: %s [-D|--debug] [-n|--name NAME] [-p|--payload NAME]\n" "$0"
                exit 0
                ;;
            *)
                printf "Error: Unknown argument %s\n" "${1}"
                exit 1
                ;;
        esac
    done
}

# Run parser before logic
parse_args "$@"

# Verification
[ "${DEBUG}" = true ] && printf "[DEBUG] Package: %s | Payload: %s\n" "${PACKAGE_NAME}" "${PAYLOAD_NAME}"

# 3. Execution Logic
sync_versioning           # 1. Update versions in source files
generate_backup_includes  # 2. Create the backup includes file in src/
generate_rootfiles        # 3. Generate manifest (includes the backup file inside ROOTFILES!)
check_files_from_manifest # 4. Verify all files in manifest exist in src/
sanitize_build_perms      # 5. Fix permissions
build_package             # 6. Compress and wrap
generate_checksum         # 7. Hash the result

printf "Build Success: %s | Author: %s | Version: %s\n" "${PACKAGE_NAME}" "${AUTHOR}" "${VERSION}"