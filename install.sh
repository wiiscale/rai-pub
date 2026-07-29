#!/usr/bin/env bash
# RAi installer — Linux & macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.sh | bash
set -euo pipefail

REPO="wiiscale/rai-pub"
INSTALL_DIR="${RAI_INSTALL_DIR:-$HOME/.local/bin}"
VERSION_FILE="https://raw.githubusercontent.com/$REPO/main/VERSION"

VERSION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: install.sh [--version vX.Y.Z]"
            echo "  Installs rai to $INSTALL_DIR"
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

echo ""
echo "  ██████╗  █████╗ ██╗     ██████╗ ██████╗ ██████╗ ███████╗"
echo "  ██╔══██╗██╔══██╗██║    ██╔════╝██╔═══██╗██╔══██╗██╔════╝"
echo "  ██████╔╝███████║██║    ██║     ██║   ██║██║  ██║█████╗ "
echo "  ██╔══██╗██╔══██║██║    ██║     ██║   ██║██║  ██║██╔══╝"
echo "  ██║  ██║██║  ██║██║    ╚██████╗╚██████╔╝██████╔╝███████╗"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═════╝ ╚═════╝╚══════╝ ╚══════╝"
echo "  Reasonary Ai Code — AI-powered coding assistant"
echo ""

# Detect OS + arch -> target name
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Linux)  TARGET="linux-amd64" ;;
    Darwin)
        case "$ARCH" in
            arm64|aarch64) TARGET="darwin-arm64" ;;
            x86_64|amd64)  TARGET="darwin-amd64"   ;;
            *) echo "ERROR: Unsupported macOS arch: $ARCH" >&2; exit 1 ;;
        esac ;;
    *) echo "ERROR: Unsupported OS: $OS" >&2; exit 1 ;;
esac

# Resolve latest version if not specified
if [ -z "$VERSION" ]; then
    VERSION=$(curl -fsSL "$VERSION_FILE" | tr -d '[:space:]')
    if [ -z "$VERSION" ]; then
        echo "ERROR: Could not determine latest version" >&2
        exit 1
    fi
fi
echo "-> Installing rai $VERSION ($TARGET)..."

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/rai-$VERSION-$TARGET.tar.gz"
CHECKSUM_URL="https://github.com/$REPO/releases/download/$VERSION/checksums.txt"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

PKG="rai-$VERSION-$TARGET.tar.gz"

# Download
echo "-> Downloading..."
curl -fsSL "$DOWNLOAD_URL" -o "$TMPDIR/$PKG"
curl -fsSL "$CHECKSUM_URL" -o "$TMPDIR/checksums.txt"

# Verify checksum
echo "-> Verifying checksum..."
cd "$TMPDIR"
if command -v shasum &>/dev/null; then
    shasum -a 256 -c checksums.txt 2>/dev/null || true
elif command -v sha256sum &>/dev/null; then
    sha256sum -c checksums.txt 2>/dev/null || true
else
    echo "WARNING: No shasum/sha256sum found — skipping checksum verification" >&2
fi

# Extract
tar -xzf "$PKG"

# Install
mkdir -p "$INSTALL_DIR"
cp rai "$INSTALL_DIR/rai"
chmod +x "$INSTALL_DIR/rai"

echo ""
echo "  -> Installed: $INSTALL_DIR/rai"
echo "  -> Make sure $INSTALL_DIR is in your PATH."
echo ""
echo "  Run 'rai' to get started!"
