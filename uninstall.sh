#!/bin/bash
#################################################################################
# uninstall.sh - H&M Firewall-Local Uninstaller Script                          #
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

# 1. Initialize variables
NAME=${NAME:-"firewall-local"}
# Use the official Pakfire manifest location for cleanup
MANIFEST="/opt/pakfire/db/rootfiles/${NAME}"

# 2. Source Pakfire library
# shellcheck source=/dev/null
if [ -f "/opt/pakfire/lib/functions.sh" ]; then
    . /opt/pakfire/lib/functions.sh
else
    logger -t "${NAME} UNINSTALLER" "[ERROR] Pakfire functions missing"
    exit 1
fi

# 3. Stop Services
if [ -x "/etc/sysconfig/firewall.local" ]; then
    /etc/sysconfig/firewall.local stop
fi

# 4. Remove Files Based on Manifest
if [ -f "${MANIFEST}" ]; then
    while read -r line || [ -n "${line}" ]; do
        # Strip IPFire prefix symbols (+ and #) to get the raw path
        target_path=$(echo "${line}" | sed 's/^[+#]//' | xargs)

        # Ignore descriptive comments and non-system paths
        [[ -z "${target_path}" || ! "${target_path}" =~ ^(etc|usr|var|opt|bin|sbin) ]] && continue

        # Remove the file if it exists
        if [ -f "/${target_path}" ] || [ -L "/${target_path}" ]; then
            rm -f "/${target_path}"
            [ "${DEBUG}" = "true" ] && printf "Removed file: /%s\n" "${target_path}"
        fi
    done < "${MANIFEST}"
fi

# 5. Cleanup Pakfire Database
rm -f "/opt/pakfire/db/installed/${NAME}"
rm -f "/opt/pakfire/db/rootfiles/${NAME}"
rm -f "/var/ipfire/backup/addons/includes/${NAME}"

logger -t "${NAME} UNINSTALLER" "Package ${NAME} uninstalled successfully."

exit 0
