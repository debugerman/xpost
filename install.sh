#!/usr/bin/env bash
set -euo pipefail

REPO="missuo/xpost"
BINARY="xpost"
INSTALL_DIR="/usr/local/bin"

# Detect OS and architecture.
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  arm64)   ARCH="arm64" ;;
  armv7l)  ARCH="armv7" ;;
  i386|i686) ARCH="386" ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

case "$OS" in
  linux|darwin|freebsd|openbsd|netbsd) ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

# Fetch latest release tag from GitHub API.
echo "Fetching latest release..."
TAG="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | cut -d '"' -f 4)"
if [ -z "$TAG" ]; then
  echo "Failed to determine latest release." >&2
  exit 1
fi
echo "Latest release: $TAG"

# Build download URL.
ASSET="${BINARY}-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"

# Download binary.
TMP="$(mktemp)"
echo "Downloading ${URL}..."
if ! curl -fSL -o "$TMP" "$URL"; then
  echo "Download failed. Check if a binary exists for ${OS}/${ARCH}." >&2
  rm -f "$TMP"
  exit 1
fi

# Install.
chmod +x "$TMP"
if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP" "${INSTALL_DIR}/${BINARY}"
else
  echo "Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mv "$TMP" "${INSTALL_DIR}/${BINARY}"
fi

echo "Installed ${BINARY} ${TAG} to ${INSTALL_DIR}/${BINARY}"
