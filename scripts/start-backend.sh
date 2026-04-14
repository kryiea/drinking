#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -d .venv ]]; then
  echo "缺少 .venv，请先执行 ./scripts/setup-backend.sh"
  exit 1
fi

if [[ ! -f backend/.env ]]; then
  cp backend/.env.example backend/.env
fi

export NO_PROXY="${NO_PROXY:+$NO_PROXY,}127.0.0.1,localhost,.local"
export no_proxy="$NO_PROXY"

set -a
source backend/.env
set +a

source .venv/bin/activate
uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000 --reload
