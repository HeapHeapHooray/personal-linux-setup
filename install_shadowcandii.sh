#!/usr/bin/env bash
#
# install_shadowcandii.sh
# Download, install, and apply the ShadowCandii KDE Plasma rice profile.
# Repository: https://github.com/HeapHeapHooray/ShadowCandii
#

set -euo pipefail

KNSV_URL="https://raw.githubusercontent.com/HeapHeapHooray/ShadowCandii/master/ShadowCandii.knsv"
PROFILE_NAME="ShadowCandii"
DO_APPLY=true

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Download, install, and apply the ShadowCandii KDE Plasma configuration profile via Konsave.

Options:
  --no-apply     Import the profile into Konsave without applying it
  -h, --help     Show this help message
EOF
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-apply)
            DO_APPLY=false
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            print_usage
            exit 1
            ;;
    esac
done

# Ensure ~/.local/bin is in PATH (common location for uv/konsave binaries)
export PATH="$HOME/.local/bin:$PATH"

echo "=================================================="
echo "==> ShadowCandii KDE Rice Setup"
echo "=================================================="

# Step 1: Ensure konsave is installed and accessible
echo ""
echo "==> [1/4] Checking for Konsave..."
if ! command -v konsave >/dev/null 2>&1; then
    echo "--> Konsave not found. Checking available installation methods..."

    if command -v uv >/dev/null 2>&1; then
        echo "--> Installing Konsave using uv..."
        uv tool install konsave
    elif command -v pipx >/dev/null 2>&1; then
        echo "--> Installing Konsave using pipx..."
        pipx install konsave
    elif command -v curl >/dev/null 2>&1; then
        echo "--> Installing Astral uv to manage Python CLI tools..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        uv tool install konsave
    elif command -v pip3 >/dev/null 2>&1; then
        echo "--> Installing Konsave using pip3..."
        pip3 install --user --break-system-packages konsave 2>/dev/null || pip3 install --user konsave
    else
        echo "Error: Neither konsave, uv, pipx, nor pip3 was found." >&2
        echo "Please install uv (curl -LsSf https://astral.sh/uv/install.sh | sh) or pipx first." >&2
        exit 1
    fi

    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v konsave >/dev/null 2>&1; then
        echo "Error: Konsave installation finished but 'konsave' executable was not found in PATH." >&2
        exit 1
    fi
fi
echo "--> Konsave is ready: $(command -v konsave)"

# Step 2: Download ShadowCandii.knsv directly
echo ""
echo "==> [2/4] Downloading ShadowCandii.knsv..."
TMP_DIR="$(mktemp -d -t shadowcandii-XXXXXX)"
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

KNSV_FILE="$TMP_DIR/ShadowCandii.knsv"

echo "--> Downloading from $KNSV_URL..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$KNSV_URL" -o "$KNSV_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$KNSV_URL" -O "$KNSV_FILE"
else
    echo "Error: Neither curl nor wget is installed." >&2
    exit 1
fi

if [[ ! -s "$KNSV_FILE" ]]; then
    echo "Error: Downloaded ShadowCandii.knsv file is empty or missing." >&2
    exit 1
fi
echo "--> ShadowCandii.knsv successfully downloaded."

# Step 3: Import profile into Konsave
echo ""
echo "==> [3/4] Importing ShadowCandii profile..."
# Konsave fails if importing a profile with a name that already exists in ~/.config/konsave/profiles/
if konsave -l 2>/dev/null | grep -qw "$PROFILE_NAME" || [[ -d "$HOME/.config/konsave/profiles/$PROFILE_NAME" ]]; then
    echo "--> Existing '$PROFILE_NAME' profile found. Removing old profile for clean re-import..."
    konsave -r "$PROFILE_NAME" 2>/dev/null || rm -rf "$HOME/.config/konsave/profiles/$PROFILE_NAME"
fi

konsave -i "$KNSV_FILE"
echo "--> Profile '$PROFILE_NAME' successfully imported into Konsave."

# Step 4: Apply profile (if requested)
echo ""
if [[ "$DO_APPLY" == true ]]; then
    echo "==> [4/4] Applying '$PROFILE_NAME' profile..."
    konsave -a "$PROFILE_NAME"
    echo ""
    echo "=================================================="
    echo "==> ShadowCandii successfully applied!"
    echo "==> Please log out and log back in (or reboot) for"
    echo "    all KDE Plasma desktop changes to fully take effect."
    echo "=================================================="
else
    echo "==> [4/4] Skipping apply step (--no-apply specified)."
    echo "--> You can manually apply the profile at any time by running:"
    echo "    konsave -a $PROFILE_NAME"
fi
