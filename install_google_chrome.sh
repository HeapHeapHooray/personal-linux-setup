#!/usr/bin/env bash
#
# install_google_chrome.sh
# Download and install Google Chrome Stable on Ubuntu/Debian systems.
#

set -euo pipefail

# Install curl and wget before installation of Google Chrome
sudo apt install -y curl wget
# Add Google's repository to source.
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
# Sync with Google's repositories.
sudo apt update
# Install Google Chrome
sudo apt install -y google-chrome-stable
