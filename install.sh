#!/usr/bin/env bash
# rai installer — Linux & macOS
# Downloads from public mirror wiiscale/rai-pub releases via curl.
# Usage: ./install.sh [--version vX.Y.Z] [--help]
set -euo pipefail

REPO="wiiscale/rai-pub"
INSTALL_DIR="${RAI_INSTALL_DIR:-$HOME/.local/bin}"

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
VERSION=""
while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            if [ $# -lt 2 ]; then
                echo "ERROR: --version requires a value (e.g., --version vX.Y.Z)" >&2
                exit 1
            fi
            VERSION="$2"; shift 2 ;;
        --help|-h)
            sed -n '2,4p' "$0"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo ""
echo "  ██████╗  █████╗ ██╗     ██████╗ ██████╗ ██████╗ ███████╗"
echo "  ██╔══██╗██╔══██╗██║    ██╔════╝██╔═══██╗██╔══██╗██╔════╝"
echo "  ██████╔╝███████║██║    ██║     ██║   ██║██║  ██║█████╗ "
echo "  ██╔══██╗██╔══██║██║    ██║     ██║   ██║██║  ██║██╔══╝"
echo "  ██║  ██║██║  ██║██║    ╚██████╗╚██████╔╝██████╔╝███████╗"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═════╝ ╚═════╝╚══════╝ ╚══════╝"
echo "  Reasonary Ai Code — AI-powered coding assistant"
echo ""

# ---------------------------------------------------------------------------
# Detect OS + arch → target name
# ---------------------------------------------------------------------------
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Linux)
        case "$ARCH" in
            x86_64)  TARGET="linux-x64" ;;
            *)       echo "ERROR: Unsupported Linux arch: $ARCH (only x86_64 supported)" >&2; exit 1 ;;
        esac
        ;;
    Darwin)
        case "$ARCH" in
            arm64)   TARGET="macos-arm64" ;;
            x86_64)  TARGET="macos-x64" ;;
            *) echo "ERROR: Unsupported macOS arch: $ARCH" >&2; exit 1 ;;
        esac
        ;;
    *) echo "ERROR: Unsupported OS: $OS (use install.ps1 on Windows)" >&2; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# Resolve version via GitHub public API (no jq, no gh CLI)
# ---------------------------------------------------------------------------
BASE_URL="https://github.com/${REPO}/releases/download"

if [ -z "$VERSION" ]; then
    echo "→ Resolving latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | head -1 \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    if [ -z "$VERSION" ]; then
        echo "ERROR: Could not determine latest release." >&2
        exit 1
    fi
fi

# Strip leading 'v' for filename convention, keep for tag
TAG="$VERSION"
# Asset version without 'v' prefix for filename matching
V_NUM="${VERSION#v}"

ASSET="rai-v${V_NUM}-${TARGET}.tar.gz"
echo "→ Installing rai ${TAG} for ${TARGET}..."

# ---------------------------------------------------------------------------
# Tmp in install dir to avoid EXDEV cross-filesystem rename
# ---------------------------------------------------------------------------
mkdir -p "$INSTALL_DIR"
TMP_ARCHIVE="${INSTALL_DIR}/.rai-installer-archive-$$"
TMP_CHECKSUMS="${INSTALL_DIR}/.rai-installer-checksums-$$"
TMP_EXTRACT="${INSTALL_DIR}/.rai-installer-extract-$$"

cleanup() {
    rm -f "$TMP_ARCHIVE" "$TMP_CHECKSUMS"
    rm -rf "$TMP_EXTRACT"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Download archive + checksums via curl
# ---------------------------------------------------------------------------
echo "→ Downloading ${ASSET}..."
curl -fL --progress-bar "${BASE_URL}/${TAG}/${ASSET}" -o "$TMP_ARCHIVE"

echo "→ Downloading checksums.txt..."
curl -fL --progress-bar "${BASE_URL}/${TAG}/checksums.txt" -o "$TMP_CHECKSUMS"

# ---------------------------------------------------------------------------
# Verify SHA256 checksum
# ---------------------------------------------------------------------------
echo "→ Verifying checksum..."
# Robust parse: handles both "hash  file" (binary) and "hash *file" (text) modes
EXPECTED=$(tr -d '\r' < "$TMP_CHECKSUMS" | awk -v asset="$ASSET" '$NF == asset {print $1; exit}')
if [ -z "$EXPECTED" ]; then
    echo "ERROR: No checksum found for ${ASSET} in checksums.txt" >&2
    exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL=$(sha256sum "$TMP_ARCHIVE" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    ACTUAL=$(shasum -a 256 "$TMP_ARCHIVE" | awk '{print $1}')
else
    echo "ERROR: No SHA256 tool (sha256sum or shasum)" >&2
    exit 1
fi

if [ "$EXPECTED" != "$ACTUAL" ]; then
    echo "ERROR: Checksum mismatch!" >&2
    echo "  Expected: $EXPECTED" >&2
    echo "  Got:      $ACTUAL" >&2
    exit 1
fi
echo "  ✓ Checksum OK"

# ---------------------------------------------------------------------------
# Extract archive
# ---------------------------------------------------------------------------
mkdir -p "$TMP_EXTRACT"
tar -xzf "$TMP_ARCHIVE" -C "$TMP_EXTRACT"

# Find the rai binary in extracted contents
BINARY_SRC=$(find "$TMP_EXTRACT" -name "rai" -type f | head -1)
if [ -z "$BINARY_SRC" ]; then
    echo "ERROR: rai binary not found in archive" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Backup existing binary + install
# ---------------------------------------------------------------------------
INSTALL_PATH="${INSTALL_DIR}/rai"

if [ -f "$INSTALL_PATH" ]; then
    cp "$INSTALL_PATH" "${INSTALL_PATH}.bak"
    echo "→ Backed up existing binary to ${INSTALL_PATH}.bak"
fi

cp "$BINARY_SRC" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
echo "→ Installed to ${INSTALL_PATH}"

# ---------------------------------------------------------------------------
# PATH hint
# ---------------------------------------------------------------------------
case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) ;;
    *)
        echo ""
        echo "⚠ ${INSTALL_DIR} is not in your PATH." >&2
        echo "  Add it: export PATH=\"${INSTALL_DIR}:\$PATH\"" >&2
        echo "  Or add to ~/.bashrc / ~/.zshrc" >&2
        ;;
esac

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------
echo "→ Verifying installation..."
"$INSTALL_PATH" --version

echo ""
echo "✅ rai ${TAG} installed successfully."

echo ""
echo "Quick start:"
echo "  rai                          # interactive mode"
echo "  rai prompt 'hello world'     # one-shot prompt"
echo "  rai doctor                   # health check"
