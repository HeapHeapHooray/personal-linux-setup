#!/usr/bin/env bash
#
# install_google_chrome.sh
# Download and install Google Chrome Stable on Ubuntu/Debian systems.
#

set -euo pipefail

# Install curl, wget, and gnupg before installation of Google Chrome
sudo apt install -y curl wget gnupg
# Add Google's repository signing key to trusted.gpg.d
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/google.gpg
sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
# Sync with Google's repositories.
sudo apt update
# Install Google Chrome
sudo apt install -y google-chrome-stable
