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

# Set Google Chrome as default browser
if command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-web-browser google-chrome.desktop || true
fi

if command -v xdg-mime >/dev/null 2>&1; then
    xdg-mime default google-chrome.desktop x-scheme-handler/http || true
    xdg-mime default google-chrome.desktop x-scheme-handler/https || true
    xdg-mime default google-chrome.desktop text/html || true
fi

if command -v update-alternatives >/dev/null 2>&1; then
    sudo update-alternatives --set x-www-browser /usr/bin/google-chrome-stable 2>/dev/null || true
    sudo update-alternatives --set gnome-www-browser /usr/bin/google-chrome-stable 2>/dev/null || true
fi
