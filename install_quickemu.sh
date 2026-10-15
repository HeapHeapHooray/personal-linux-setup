#!/usr/bin/env bash
#
# install_quickemu.sh
# Install Quickemu from official PPA on Ubuntu/Debian systems.
# Repository: https://github.com/quickemu-project/quickemu
#

set -euo pipefail

sudo apt-add-repository ppa:flexiondotorg/quickemu
sudo apt update
sudo apt install -y quickemu
mkdir -p ~/.local/bin
