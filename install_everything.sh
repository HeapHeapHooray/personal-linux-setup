#!/usr/bin/env bash
#
# install_everything.sh
# Complete setup script for personal Linux environment.
# Repository: https://github.com/HeapHeapHooray/personal-linux-setup
#

set -euo pipefail

# Determine repository base and local script directory if executed from a cloned repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd || echo "")"
REMOTE_REPO_BASE="https://raw.githubusercontent.com/HeapHeapHooray/personal-linux-setup/refs/heads/main"

run_installer() {
    local script_name="$1"
    local local_script="${SCRIPT_DIR:+$SCRIPT_DIR/$script_name}"
    local remote_url="$REMOTE_REPO_BASE/$script_name"

    echo ""
    echo "=================================================="
    echo "==> Running $script_name..."
    echo "=================================================="

    if [[ -n "${local_script:-}" && -f "$local_script" ]]; then
        echo "--> Found local script, executing $local_script..."
        bash "$local_script"
    else
        echo "--> Downloading and executing from remote repository..."
        curl -sSL "$remote_url" | bash -s
    fi
}

echo "=================================================="
echo "==> Starting Personal Linux Setup"
echo "=================================================="

# Step 1: Update package list and install core prerequisites
echo ""
echo "==> [1/8] Updating APT repositories and installing prerequisites..."
sudo apt update
sudo apt install -y curl wget tar unzip git

# Step 2: Run modular application installers
echo ""
echo "==> [2/8] Running standalone application installers..."
run_installer "install_google_chrome.sh"
run_installer "install_quickemu.sh"
run_installer "install_portablemc.sh"
run_installer "install_minecraft_mod_manager.sh"
run_installer "install_mimo.sh"
run_installer "install_eternal_summer.sh"

# Step 3: Install favorite terminal utilities via APT
echo ""
echo "==> [3/8] Installing favorite CLI packages..."
sudo apt install -y neofetch ncdu htop btop trash-cli

# Step 4: Configure safe file deletion alias
echo ""
echo "==> [4/8] Configuring trash-cli alias..."
if ! grep -q 'alias rm=' ~/.bashrc 2>/dev/null; then
    echo "alias rm=trash-put" >> ~/.bashrc
    echo "--> Added 'alias rm=trash-put' to ~/.bashrc"
else
    echo "--> Alias for 'rm' already present in ~/.bashrc"
fi

# Step 5: Ensure ~/.local/bin is in PATH
if ! grep -q 'PATH=.*\.local/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo "--> Added ~/.local/bin to PATH in ~/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"

# Step 6: Install uv and Python tools
echo ""
echo "==> [5/8] Setting up uv (Python package installer)..."
if ! command -v uv >/dev/null 2>&1; then
    echo "--> Installing uv via official Astral installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "--> uv is already installed: $(command -v uv)"
fi

echo ""
echo "==> [6/8] Installing Python CLI tools via uv..."
uv tool install konsave
uv tool install mozapp

echo ""
echo "==> [7/8] Setting up Minecraft..."
run_installer "setup_minecraft.sh"

echo ""
echo "==> [8/8] Setting up customization..."
run_installer "install_shadowcandii.sh"
run_installer "install_wallpapers.sh"

echo ""
echo "=================================================="
echo "==> All installations and configurations completed!"
echo "=================================================="
