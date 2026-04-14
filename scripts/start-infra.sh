#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
export NO_PROXY="${NO_PROXY:+$NO_PROXY,}127.0.0.1,localhost,.local"
export no_proxy="$NO_PROXY"

if [[ ! -f infra/.env ]]; then
  cp infra/.env.example infra/.env
fi

if [[ "$(uname -s)" == "Darwin" ]] && command -v scutil >/dev/null 2>&1; then
  zsh ./scripts/configure-podman-proxy.sh >/dev/null || true
fi

compose_file="infra/podman-compose.yml"
compose_cmd=()

if podman compose version >/dev/null 2>&1; then
  compose_cmd=(podman compose -f "$compose_file" --env-file infra/.env)
elif command -v podman-compose >/dev/null 2>&1; then
  compose_cmd=(podman-compose -f "$compose_file" --env-file infra/.env)
else
  echo "缺少 podman compose / podman-compose，无法启动本地基础设施。"
  exit 1
fi

if podman ps >/dev/null 2>&1; then
  "${compose_cmd[@]}" up -d
  podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  exit 0
fi

if ! podman machine inspect podman-machine-default >/dev/null 2>&1; then
  podman machine init --rootful --cpus 4 --memory 4096 --disk-size 100 podman-machine-default >/dev/null 2>&1
fi

podman machine start podman-machine-default >/dev/null 2>&1 || true

for _ in {1..20}; do
  if podman machine inspect podman-machine-default 2>/dev/null | grep -q '"State": "running"'; then
    if podman ps >/dev/null 2>&1; then
      "${compose_cmd[@]}" up -d
      podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
      exit 0
    fi
  fi
  sleep 2
done

echo "Podman 仍不可连接，但脚本没有改动你的系统代理。"
echo "如果你正在挂 VPN，优先确认 localhost/127.0.0.1 已在 NO_PROXY 中。"
echo "如需只给 Podman VM 同步当前 macOS 代理，可执行：zsh ./scripts/configure-podman-proxy.sh"
echo "必要时再执行：sudo /opt/podman/bin/podman-mac-helper install"
exit 1
