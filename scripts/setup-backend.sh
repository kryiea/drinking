#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -d .venv ]]; then
  uv venv .venv
fi

source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -e "backend[dev]"

echo "Backend environment ready."
