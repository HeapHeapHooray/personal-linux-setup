#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use: sudo ./install-rocm.sh)"
    exit 1
fi

echo "=== 1. Patching amdgpu-install for KDE neon ==="
if grep -q 'ubuntu|linuxmint|debian|velinux)' /usr/bin/amdgpu-install; then
    sed -i 's/ubuntu|linuxmint|debian|velinux)/ubuntu|linuxmint|debian|velinux|neon)/' /usr/bin/amdgpu-install
    echo "Added 'neon' to supported distributions in /usr/bin/amdgpu-install."
else
    echo "amdgpu-install already patched or pattern not found."
fi

echo "=== 2. Updating package lists ==="
apt-get update

echo "=== 3. Installing ROCm and HIP for RX 7600 (gfx1102) ==="
amdgpu-install -y \
    --usecase=rocm,hiplibsdk,rocmdev \
    --no-dkms \
    --gfxversion=gfx1102

echo "=== 4. Configuring Environment Variables ==="
cat << 'EOF' > /etc/profile.d/rocm.sh
export ROCM_PATH=/opt/rocm
export PATH="$ROCM_PATH/bin:$PATH"
export LD_LIBRARY_PATH="$ROCM_PATH/lib:${LD_LIBRARY_PATH:-}"
EOF

chmod +x /etc/profile.d/rocm.sh

echo "=== Installation complete! ==="
echo "You can test the installation with:"
echo "  /opt/rocm/bin/rocminfo"
echo "  /opt/rocm/bin/hipconfig --version"
