#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/../ios"
xcodegen generate
echo "Generated ios/Yinzhi.xcodeproj"
