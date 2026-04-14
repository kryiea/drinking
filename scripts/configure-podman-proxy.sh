#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

machine_name="${PODMAN_MACHINE_NAME:-podman-machine-default}"
clear_proxy="${1:-}"

if ! command -v podman >/dev/null 2>&1; then
  echo "缺少 podman，无法配置 Podman machine 代理。"
  exit 1
fi

if ! podman machine inspect "$machine_name" >/dev/null 2>&1; then
  echo "未找到 Podman machine: $machine_name"
  exit 1
fi

podman machine start "$machine_name" >/dev/null 2>&1 || true

remote_proxy_file='~/.config/systemd/user/podman.service.d/proxy.conf'

if [[ "$clear_proxy" == "--clear" ]]; then
  podman machine ssh "rm -f $remote_proxy_file && systemctl --user daemon-reload && systemctl --user restart podman.socket && systemctl --user restart podman.service || true" >/dev/null
  echo "已清除 Podman machine 代理桥接配置。"
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]] || ! command -v scutil >/dev/null 2>&1; then
  echo "当前环境未提供 macOS 系统代理信息，跳过 Podman machine 代理桥接。"
  exit 0
fi

proxy_dump="$(scutil --proxy)"

http_enabled="$(printf '%s\n' "$proxy_dump" | awk '/HTTPEnable/ {print $3; exit}')"
https_enabled="$(printf '%s\n' "$proxy_dump" | awk '/HTTPSEnable/ {print $3; exit}')"

proxy_host=""
proxy_port=""

if [[ "$https_enabled" == "1" ]]; then
  proxy_host="$(printf '%s\n' "$proxy_dump" | awk '/HTTPSProxy/ {print $3; exit}')"
  proxy_port="$(printf '%s\n' "$proxy_dump" | awk '/HTTPSPort/ {print $3; exit}')"
elif [[ "$http_enabled" == "1" ]]; then
  proxy_host="$(printf '%s\n' "$proxy_dump" | awk '/HTTPProxy/ {print $3; exit}')"
  proxy_port="$(printf '%s\n' "$proxy_dump" | awk '/HTTPPort/ {print $3; exit}')"
fi

if [[ -z "$proxy_host" || -z "$proxy_port" ]]; then
  echo "未检测到启用中的 macOS HTTP/HTTPS 代理，跳过 Podman machine 代理桥接。"
  exit 0
fi

if [[ "$proxy_host" == "127.0.0.1" || "$proxy_host" == "localhost" ]]; then
  proxy_host="host.containers.internal"
fi

no_proxy_value="127.0.0.1,localhost,.local,host.containers.internal,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

remote_override="[Service]
Environment=\"HTTP_PROXY=http://$proxy_host:$proxy_port\"
Environment=\"HTTPS_PROXY=http://$proxy_host:$proxy_port\"
Environment=\"NO_PROXY=$no_proxy_value\"
"

printf '%s' "$remote_override" | podman machine ssh "mkdir -p ~/.config/systemd/user/podman.service.d && cat > $remote_proxy_file && systemctl --user daemon-reload && systemctl --user restart podman.socket && systemctl --user restart podman.service || true" >/dev/null

echo "已为 Podman machine 写入代理桥接配置: http://$proxy_host:$proxy_port"
echo "该设置只作用于 Podman VM，不会改动你的 macOS 全局 VPN/代理。"
