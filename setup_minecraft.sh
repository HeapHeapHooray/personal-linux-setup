#!/usr/bin/env bash
#
# setup_minecraft.sh
# Sets up Minecraft..
# Repository: https://github.com/HeapHeapHooray/PersonalMinecraftSetup


set -euo pipefail


curl -fsSL https://raw.githubusercontent.com/HeapHeapHooray/PersonalMinecraftSetup/refs/heads/main/setup_or_update.sh | bash -s
