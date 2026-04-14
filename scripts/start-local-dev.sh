#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
export NO_PROXY="${NO_PROXY:+$NO_PROXY,}127.0.0.1,localhost,.local"
export no_proxy="$NO_PROXY"

if [[ "${1:-}" != "--skip-infra" ]]; then
  if ! ./scripts/start-infra.sh; then
    echo "基础设施暂不可用，继续使用 SQLite 本地模式启动后端。"
  fi
fi

./scripts/start-backend.sh
