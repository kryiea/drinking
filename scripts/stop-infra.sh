#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."
export CONTAINERS_MACHINE_PROVIDER=applehv

podman-compose -f infra/podman-compose.yml --env-file infra/.env down
