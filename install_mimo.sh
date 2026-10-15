#!/usr/bin/env bash
#
# install_mimo.sh
# Download and install mimo.
# Repository: https://github.com/HeapHeapHooray/mimo

set -euo pipefail

curl -fsSL https://raw.githubusercontent.com/HeapHeapHooray/mimo/refs/heads/main/install.sh | bash -s
