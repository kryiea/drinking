#!/bin/zsh
set -euo pipefail

echo "Installing Xcode 26.4 from the Mac App Store."
echo "If the App Store asks for your Apple ID password, complete that step interactively."
mas install 497799835
