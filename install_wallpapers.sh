#!/usr/bin/env bash
#
# install_wallpapers.sh
# Download and install DailyDriverWallpapers.
# Repository: https://github.com/HeapHeapHooray/DailyDriverWallpapers

set -euo pipefail

curl -fsSL https://raw.githubusercontent.com/HeapHeapHooray/DailyDriverWallpapers/refs/heads/main/install.sh | bash -s -- "$@"
