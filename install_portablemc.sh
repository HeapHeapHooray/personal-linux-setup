#!/usr/bin/env bash
#
# install_portablemc.sh
# Download and install the latest PortableMC Linux binary from GitHub.
# Repository: https://github.com/theorzr/portablemc
#

set -euo pipefail

REPO="theorzr/portablemc"
DEFAULT_INSTALL_DIR="$HOME/.local/bin"
INSTALL_DIR=""
REQUESTED_VERSION="latest"

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -d, --dir <DIR>        Installation directory (default: ~/.local/bin or /usr/local/bin if run as root)
  -s, --system           Install system-wide to /usr/local/bin (uses sudo if needed)
  -v, --version <VER>    Specify version to install (e.g. "v5.0.5" or "5.0.5", default: latest)
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
    if [[ "$(id -u)" -eq 0 ]]; then
        INSTALL_DIR="/usr/local/bin"
    else
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    fi
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
        ARCH_PATTERN="x86_64"
        ARCH_SUFFIX="x86_64-gnu"
        ;;
    aarch64|arm64)
        ARCH_PATTERN="aarch64"
        ARCH_SUFFIX="aarch64-gnu"
        ;;
    i386|i686)
        ARCH_PATTERN="i686"
        ARCH_SUFFIX="i686-gnu"
        ;;
    armv6*|armv7*|armhf)
        ARCH_PATTERN="arm.*gnueabihf"
        ARCH_SUFFIX="arm-gnueabihf"
        ;;
    *)
        echo "Error: Unsupported architecture '$ARCH'." >&2
        exit 1
        ;;
esac

# Check for required utilities
for cmd in curl tar; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required utility '$cmd' is not installed." >&2
        exit 1
    fi
done

echo "==> Detecting latest PortableMC release for $ARCH..."

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
    
    # Parse browser_download_url for linux tar.gz archive
    DOWNLOAD_URL=$(echo "$API_RESPONSE" | grep "browser_download_url" | grep -v '\.sig"' | grep "linux" | grep -E "$ARCH_PATTERN" | head -n 1 | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/' || true)
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
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${RESOLVED_TAG}/portablemc-${CLEAN_VERSION}-linux-${ARCH_SUFFIX}.tar.gz"
fi

if [[ -z "$DOWNLOAD_URL" || -z "$RESOLVED_TAG" ]]; then
    echo "Error: Could not resolve download URL for PortableMC ($ARCH)." >&2
    exit 1
fi

echo "==> Target Version: $RESOLVED_TAG"
echo "==> Download URL:   $DOWNLOAD_URL"
echo "==> Install Dir:    $INSTALL_DIR"

# Create a temporary directory for extraction
TMP_DIR=$(mktemp -d -t portablemc-install.XXXXXX)
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

ARCHIVE_FILE="$TMP_DIR/portablemc.tar.gz"

echo "==> Downloading PortableMC..."
curl -fL --progress-bar -o "$ARCHIVE_FILE" "$DOWNLOAD_URL"

echo "==> Extracting archive..."
tar -xzf "$ARCHIVE_FILE" -C "$TMP_DIR"

# Locate the portablemc executable in extracted directory
BINARY_PATH=$(find "$TMP_DIR" -type f -name "portablemc" -perm -u+x -o -name "portablemc" | head -n 1)

if [[ -z "$BINARY_PATH" || ! -f "$BINARY_PATH" ]]; then
    echo "Error: 'portablemc' binary not found in the downloaded archive." >&2
    exit 1
fi

chmod +x "$BINARY_PATH"

# Ensure destination directory exists
SUDO=""
if [[ ! -w "$INSTALL_DIR" ]]; then
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

echo "==> Installing portablemc to $INSTALL_DIR/portablemc..."
$SUDO install -m 755 "$BINARY_PATH" "$INSTALL_DIR/portablemc"

echo ""
echo "==> Verifying installation..."
if "$INSTALL_DIR/portablemc" --version; then
    echo ""
    echo "Successfully installed PortableMC to $INSTALL_DIR/portablemc"
else
    echo "Warning: Installed binary exited with a non-zero status code." >&2
fi

# Check if INSTALL_DIR is in PATH
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        echo ""
        echo "Note: '$INSTALL_DIR' is not in your current PATH."
        echo "To make 'portablemc' accessible globally, add the following to your ~/.bashrc or ~/.zshrc:"
        echo "    export PATH=\"$INSTALL_DIR:\$PATH\""
        ;;
esac
