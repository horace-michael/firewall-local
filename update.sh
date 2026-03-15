#!/bin/bash
#################################################################################
# update.sh - Firewall-Local Update Utility                                     #
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

# Load Pakfire functions
# shellcheck source=/dev/null
if [ -f "/opt/pakfire/lib/functions.sh" ]; then
    . /opt/pakfire/lib/functions.sh
else
    logger -t "${NAME} INSTALLER" "[ERROR] Pakfire functions missing"
    exit 1
fi


# 1. Prepare for update
# Ensure new backup include rules are available before making the backup
extract_backup_includes

# 2. Stop Service
# Stop the firewall local script before removing files
if [ -x "/etc/sysconfig/firewall.local" ]; then
    /etc/sysconfig/firewall.local stop
fi

# 3. Migration Cycle
# Backup existing user data (SST lists) defined in ROOTFILES
make_backup "${NAME}"

# Remove old files (excluding those marked with # in ROOTFILES)
remove_files

# Extract new package files
extract_files

# Restore user data into the new structure
restore_backup "${NAME}"

# 4. Finalize
# Update Language cache for WebGUI
#/usr/local/bin/update-lang-cache

# Start the service with new logic
if [ -x "/etc/sysconfig/firewall.local" ]; then
    /etc/sysconfig/firewall.local start
fi

logger -t "firewall-local" "Update to version ${VERSION} completed successfully."
