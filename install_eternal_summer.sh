#!/usr/bin/env bash
#
# install_eternal_summer.sh
# Download eternal_summer.sh to /tmp and run it.
# Repository: https://github.com/HeapHeapHooray/eternal_summer
#

set -euo pipefail

SCRIPT_URL="https://raw.githubusercontent.com/HeapHeapHooray/eternal_summer/refs/heads/main/eternal_summer.sh"
DEST_FILE="/tmp/eternal_summer.sh"

echo "==> Downloading eternal_summer.sh to /tmp..."
curl -fsSL "$SCRIPT_URL" -o "$DEST_FILE"
chmod +x "$DEST_FILE"

echo "==> Running $DEST_FILE..."
if [[ $# -eq 0 ]]; then
    # Default to install when invoked without arguments
    if [[ $EUID -ne 0 ]]; then
        sudo "$DEST_FILE" install
    else
        "$DEST_FILE" install
    fi
else
    if [[ "$1" == "install" || "$1" == "uninstall" ]] && [[ $EUID -ne 0 ]]; then
        sudo "$DEST_FILE" "$@"
    else
        "$DEST_FILE" "$@"
    fi
fi
