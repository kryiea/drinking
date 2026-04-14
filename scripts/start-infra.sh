#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
export CONTAINERS_MACHINE_PROVIDER=applehv

if [[ ! -f infra/.env ]]; then
  cp infra/.env.example infra/.env
fi

compose_file="infra/podman-compose.yml"

if ! podman machine inspect podman-machine-default >/dev/null 2>&1; then
  podman machine init --rootful --cpus 4 --memory 4096 --disk-size 100 podman-machine-default >/dev/null 2>&1
fi

podman machine start podman-machine-default >/dev/null 2>&1 || true

for _ in {1..20}; do
  if podman machine inspect podman-machine-default 2>/dev/null | grep -q '"State": "running"'; then
    if podman ps >/dev/null 2>&1; then
      podman-compose -f "$compose_file" --env-file infra/.env up -d
      podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
      exit 0
    fi
  fi
  sleep 2
done

echo "Podman machine exists, but this Mac still cannot reach the Podman socket."
echo "Recommended next fix:"
echo "  sudo /opt/podman/bin/podman-mac-helper install"
exit 1
