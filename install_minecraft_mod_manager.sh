#!/usr/bin/env bash
#
# install_minecraft_mod_manager.sh
# Download and install the latest Minecraft Mod Manager (mmm) Linux binary from GitHub.
# Repository: https://github.com/meza/minecraft-mod-manager
#

set -euo pipefail

REPO="meza/minecraft-mod-manager"
DEFAULT_INSTALL_DIR="$HOME/.minecraft"
INSTALL_DIR=""
REQUESTED_VERSION="latest"
CREATE_SYMLINK=true
LINK_BIN=false

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Download and install Minecraft Mod Manager (mmm) for Linux into your Minecraft directory.

Options:
  -d, --dir <DIR>        Installation directory (default: ~/.minecraft)
  -s, --system           Install system-wide to /usr/local/bin (uses sudo if needed)
  -v, --version <VER>    Specify version to install (e.g. "v2.0.12" or "2.0.12", default: latest)
      --no-symlink       Do not create a 'minecraft-mod-manager' symlink to 'mmm'
      --link-bin         Also create a symlink in ~/.local/bin to access 'mmm' from anywhere
  -h, --help             Show this help message
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --dir requires a directory path." >&2
                exit 1
            fi
            INSTALL_DIR="$2"
            shift 2
            ;;
        -s|--system)
            INSTALL_DIR="/usr/local/bin"
            shift
            ;;
        -v|--version)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --version requires a version string." >&2
                exit 1
            fi
            REQUESTED_VERSION="$2"
            shift 2
            ;;
        --no-symlink)
            CREATE_SYMLINK=false
            shift
            ;;
        --link-bin)
            LINK_BIN=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            print_usage >&2
            exit 1
            ;;
    esac
done

# Default install directory
if [[ -z "$INSTALL_DIR" ]]; then
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
fi

# Detect Operating System
OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
    echo "Error: This installer is intended for Linux only (detected $OS)." >&2
    exit 1
fi

# Detect Architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)
        ;;
    *)
        echo "Error: meza/minecraft-mod-manager official Linux binaries are only built for x86_64/amd64 (detected $ARCH)." >&2
        exit 1
        ;;
esac

# Check for required download utility
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: Required utility 'curl' is not installed." >&2
    exit 1
fi

# Check for decompression utility (unzip or python3)
EXTRACT_TOOL=""
if command -v unzip >/dev/null 2>&1; then
    EXTRACT_TOOL="unzip"
elif command -v python3 >/dev/null 2>&1; then
    EXTRACT_TOOL="python3"
elif command -v busybox >/dev/null 2>&1 && busybox unzip -h >/dev/null 2>&1; then
    EXTRACT_TOOL="busybox"
else
    echo "Error: Neither 'unzip' nor 'python3' was found. Please install 'unzip'." >&2
    exit 1
fi

echo "==> Detecting latest Minecraft Mod Manager release..."

DOWNLOAD_URL=""
RESOLVED_TAG=""

if [[ "$REQUESTED_VERSION" == "latest" ]]; then
    API_URL="https://api.github.com/repos/${REPO}/releases/latest"
else
    # Normalize version with 'v' prefix for GitHub tag lookup
    TAG_QUERY="$REQUESTED_VERSION"
    [[ "$TAG_QUERY" != v* ]] && TAG_QUERY="v$TAG_QUERY"
    API_URL="https://api.github.com/repos/${REPO}/releases/tags/${TAG_QUERY}"
fi

# Attempt 1: Fetch via GitHub API
API_RESPONSE=$(curl -fsSL -H "Accept: application/vnd.github+json" "$API_URL" 2>/dev/null || true)

if [[ -n "$API_RESPONSE" ]]; then
    # Parse tag name
    RESOLVED_TAG=$(echo "$API_RESPONSE" | grep -m1 '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || true)

    # Parse browser_download_url for linux zip asset
    DOWNLOAD_URL=$(echo "$API_RESPONSE" | grep "browser_download_url" | grep -i "linux" | grep -i "\.zip" | head -n 1 | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/' || true)
fi

# Attempt 2: Fallback if API was rate-limited or failed
if [[ -z "$DOWNLOAD_URL" ]]; then
    if [[ "$REQUESTED_VERSION" == "latest" ]]; then
        # Follow redirect of /releases/latest to resolve tag
        EFFECTIVE_URL=$(curl -sIL -o /dev/null -w "%{url_effective}" "https://github.com/${REPO}/releases/latest")
        RESOLVED_TAG=$(basename "$EFFECTIVE_URL")
    else
        RESOLVED_TAG="$REQUESTED_VERSION"
        [[ "$RESOLVED_TAG" != v* ]] && RESOLVED_TAG="v$RESOLVED_TAG"
    fi

    CLEAN_VERSION="${RESOLVED_TAG#v}"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${RESOLVED_TAG}/minecraft-mod-manager-${CLEAN_VERSION}-linux.zip"
fi

if [[ -z "$DOWNLOAD_URL" || -z "$RESOLVED_TAG" ]]; then
    echo "Error: Could not resolve download URL for Minecraft Mod Manager." >&2
    exit 1
fi

echo "==> Target Version: $RESOLVED_TAG"
echo "==> Download URL:   $DOWNLOAD_URL"
echo "==> Install Dir:    $INSTALL_DIR"

# Create a temporary directory for extraction
TMP_DIR=$(mktemp -d -t mmm-install.XXXXXX)
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

ARCHIVE_FILE="$TMP_DIR/mmm.zip"

echo "==> Downloading Minecraft Mod Manager..."
curl -fL --progress-bar -o "$ARCHIVE_FILE" "$DOWNLOAD_URL"

echo "==> Extracting archive using $EXTRACT_TOOL..."
if [[ "$EXTRACT_TOOL" == "unzip" ]]; then
    unzip -q -o "$ARCHIVE_FILE" -d "$TMP_DIR"
elif [[ "$EXTRACT_TOOL" == "python3" ]]; then
    python3 -m zipfile -e "$ARCHIVE_FILE" "$TMP_DIR"
elif [[ "$EXTRACT_TOOL" == "busybox" ]]; then
    busybox unzip -q -o "$ARCHIVE_FILE" -d "$TMP_DIR"
fi

# Locate the binary executable
BINARY_PATH=$(find "$TMP_DIR" -type f -name "mmm" | head -n 1)

if [[ -z "$BINARY_PATH" || ! -f "$BINARY_PATH" ]]; then
    # Fallback search for any executable file in the archive
    BINARY_PATH=$(find "$TMP_DIR" -type f -perm -u+x | head -n 1)
fi

if [[ -z "$BINARY_PATH" || ! -f "$BINARY_PATH" ]]; then
    echo "Error: Could not find 'mmm' executable in the downloaded archive." >&2
    exit 1
fi

chmod +x "$BINARY_PATH"

# Ensure destination directory exists and handle permissions
SUDO=""
if [[ ! -w "$INSTALL_DIR" && -d "$INSTALL_DIR" ]] || [[ ! -d "$INSTALL_DIR" && ! -w "$(dirname "$INSTALL_DIR")" ]]; then
    if [[ "$(id -u)" -ne 0 ]]; then
        if command -v sudo >/dev/null 2>&1; then
            echo "Notice: Root privileges required to write to $INSTALL_DIR. Using sudo..."
            SUDO="sudo"
        else
            echo "Error: Cannot write to $INSTALL_DIR and sudo is not available." >&2
            exit 1
        fi
    fi
fi

$SUDO mkdir -p "$INSTALL_DIR"

echo "==> Installing mmm to $INSTALL_DIR/mmm..."
$SUDO install -m 755 "$BINARY_PATH" "$INSTALL_DIR/mmm"

if [[ "$CREATE_SYMLINK" == true ]]; then
    echo "==> Creating symlink $INSTALL_DIR/minecraft-mod-manager -> mmm..."
    $SUDO ln -sf "mmm" "$INSTALL_DIR/minecraft-mod-manager"
fi

if [[ "$LINK_BIN" == true ]]; then
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    echo "==> Creating global symlink $BIN_DIR/mmm -> $INSTALL_DIR/mmm..."
    ln -sf "$INSTALL_DIR/mmm" "$BIN_DIR/mmm"
    if [[ "$CREATE_SYMLINK" == true ]]; then
        ln -sf "$INSTALL_DIR/mmm" "$BIN_DIR/minecraft-mod-manager"
    fi
fi

echo ""
echo "==> Verifying installation..."
if "$INSTALL_DIR/mmm" --version >/dev/null 2>&1; then
    INSTALLED_VER=$("$INSTALL_DIR/mmm" --version)
    echo "Successfully installed Minecraft Mod Manager (v${INSTALLED_VER}) to $INSTALL_DIR/mmm"
    if [[ "$CREATE_SYMLINK" == true ]]; then
        echo "Symlink created: $INSTALL_DIR/minecraft-mod-manager -> mmm"
    fi
else
    echo "Warning: Installed binary could not be executed or exited with an error." >&2
fi

echo ""
echo "==> Usage:"
echo "To manage mods, open a terminal in your Minecraft directory ($INSTALL_DIR):"
echo "    cd \"$INSTALL_DIR\""
echo "    ./mmm help"
