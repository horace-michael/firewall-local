#!/bin/bash
#################################################################################
# make-rootfiles.sh - H&M Project Utility                                       #
# Version: 2026-03-13 1.0                                                       #
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
    sort -u -o "$manifest" "$manifest"
}

generate_rootfiles