#!/bin/zsh
set -euo pipefail

echo "Installing podman macOS helper (requires sudo)."
sudo /opt/podman/bin/podman-mac-helper install
