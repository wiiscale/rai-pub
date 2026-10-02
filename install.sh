#!/usr/bin/env bash
# RAi installer — Linux & macOS
# Usage: curl -fsSL https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.sh | bash
set -euo pipefail

REPO="wiiscale/rai-pub"
INSTALL_DIR="${RAI_INSTALL_DIR:-$HOME/.local/bin}"
VERSION_FILE="https://raw.githubusercontent.com/$REPO/main/VERSION"
# Where release assets are downloaded from. Override only for local testing
# (the trust anchor below still decides what is accepted).
RAI_RELEASE_BASE_URL="${RAI_RELEASE_BASE_URL:-https://github.com/$REPO/releases/download}"

# Release public key. It authenticates checksums.txt, so a tampered archive
# (or an attacker-controlled checksum file) cannot pass verification.
# Owner: run 'task release:keygen' and paste rai-release.pub here.
RAI_RELEASE_PUBKEY='-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqisonAhetRCMmT1n/ulr
5AP1FqCa398fNTYtGt/7KeIcTE9/PyHoV5RpwZhbWx2hLKBRLBY6puFXxAWAXOTF
USjSP+MNcjRdSiDkAvjL8N6jwdQoSfaRjKstBy6VgvhQWiwjcH21VgcH98BqC0Nz
ZibXGBM41SPxdDuQZc7FtBnA3z5AmFMydBIOSp+eAloqK9leVAEHIu1QknumndGW
LwIZDvR20nJYQDVlPiRaKqhOqu5ptfvcrFr+HZNjvlXytKiDmbFaEEr1NI0znnx+
9fMCgsGVYzuNeIoSJL+kYLwHSxUHHyjHIodBcqvXYupl3leN/XjVvqxdbHOkAyga
q6mhGSNu6LIi9+aHsw5le656P1xonF9ctiyAw/uV9lmPL7Jk6fbJjHddUxcZwzkS
pwZtKZaCdmeE3fuHWXZOR+iRmYVksUGDiuErr7w13hY8f8lHKqCWyUBrWGT1RwSj
Zt4pTkdEJAM19dh2Mn0cv11wEF7u0tddNMIUZGdrtjBmc5saRKyxZOmV2FUIh4uK
C0zvcf58IKI6DJuBWy8RBgYYJWmUKs6xO1RBpV2LGvygo59dXwhyRxzuPcfWrpae
MTFWbBYntasa/cNVH9O4WY5FO2cvs+kWR2JEbiTUBnckDzIz0AOhgXR+VhQS0NzF
heVGOkn1eh9oHph1j3l0zSECAwEAAQ==
-----END PUBLIC KEY-----'

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
    Linux)
        case "$ARCH" in
            x86_64|amd64) TARGET="linux-amd64" ;;
            *) echo "ERROR: No rai release binary for Linux $ARCH" >&2; exit 1 ;;
        esac ;;
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

DOWNLOAD_URL="$RAI_RELEASE_BASE_URL/$VERSION/rai-$VERSION-$TARGET.tar.gz"
CHECKSUM_URL="$RAI_RELEASE_BASE_URL/$VERSION/checksums.txt"
SIGN_URL="$RAI_RELEASE_BASE_URL/$VERSION/checksums.txt.sig"

RAI_TMP_DIR=$(mktemp -d)
trap 'rm -rf "$RAI_TMP_DIR"' EXIT

PKG="rai-$VERSION-$TARGET.tar.gz"

# Download
echo "-> Downloading..."
curl -fsSL "$DOWNLOAD_URL" -o "$RAI_TMP_DIR/$PKG"
curl -fsSL "$CHECKSUM_URL" -o "$RAI_TMP_DIR/checksums.txt"
if ! curl -fsSL "$SIGN_URL" -o "$RAI_TMP_DIR/checksums.txt.sig"; then
    echo "ERROR: missing checksums.txt.sig for $VERSION — refusing to install an unsigned release" >&2
    exit 1
fi

# Verify the release signature before trusting checksums.txt
if [ "$RAI_RELEASE_PUBKEY" = "PASTE_PUBLIC_KEY_HERE" ]; then
    echo "ERROR: this installer has no release public key embedded (RAI_RELEASE_PUBKEY)." >&2
    echo "       Owner: run 'task release:keygen' and paste rai-release.pub into install.sh." >&2
    exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
    echo "ERROR: openssl is required to verify the release signature" >&2
    exit 1
fi
echo "-> Verifying release signature..."
printf '%s\n' "$RAI_RELEASE_PUBKEY" > "$RAI_TMP_DIR/rai-release.pub"
if ! openssl dgst -sha256 -verify "$RAI_TMP_DIR/rai-release.pub" \
        -signature "$RAI_TMP_DIR/checksums.txt.sig" "$RAI_TMP_DIR/checksums.txt" >/dev/null 2>&1; then
    echo "ERROR: release signature verification FAILED — refusing to install." >&2
    exit 1
fi

# Verify checksum
echo "-> Verifying checksum..."
cd "$RAI_TMP_DIR"
EXPECTED=$(awk -v pkg="$PKG" '$2 == pkg {print $1}' checksums.txt)
if [ -z "$EXPECTED" ]; then
    echo "ERROR: Missing checksum for $PKG" >&2
    exit 1
fi
if command -v shasum &>/dev/null; then
    ACTUAL=$(shasum -a 256 "$PKG" | awk '{print $1}')
elif command -v sha256sum &>/dev/null; then
    ACTUAL=$(sha256sum "$PKG" | awk '{print $1}')
else
    echo "ERROR: shasum or sha256sum is required to verify the installer" >&2
    exit 1
fi
if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "ERROR: Checksum mismatch for $PKG" >&2
    exit 1
fi

# Extract
tar -xzf "$PKG"

# Install
mkdir -p "$INSTALL_DIR"
cp rai "$INSTALL_DIR/rai"
chmod +x "$INSTALL_DIR/rai"

# Built-in browser tools are prepared by this installer, not by the user.
echo "-> Preparing browser runtime..."
"$INSTALL_DIR/rai" browser install

echo ""
echo "  -> Installed: $INSTALL_DIR/rai"
echo "  -> Make sure $INSTALL_DIR is in your PATH."
echo ""
echo "  Run 'rai' to get started!"
