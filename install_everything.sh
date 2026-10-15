sudo apt update
# Prerequisites for folowing installations
sudo apt install -y curl wget tar
# Install Google Chrome
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/personal-linux-setup/refs/heads/main/install_google_chrome.sh | bash -s
# Install quickemu
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/personal-linux-setup/refs/heads/main/install_quickemu.sh | bash -s
# Install portablemc
curl -sSL https://raw.githubusercontent.com/HeapHeapHooray/personal-linux-setup/refs/heads/main/install_portablemc.sh | bash -s
# Install the remaining of my favourite packages
sudo apt install -y neofetch ncdu htop btop uv trash-cli
# Alias for trash-cli
if ! grep -q 'alias rm=' ~/.bashrc; then
    echo "alias rm=trash-cli" >> ~/.bashrc
fi
# Python packages
uv tool install konsave mozapp

