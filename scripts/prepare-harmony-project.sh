#!/bin/zsh
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
harmony_root="${project_root}/harmony"
deveco_app="${DEVECO_STUDIO_APP:-/Applications/DevEco-Studio.app}"

if [[ ! -d "${deveco_app}" ]]; then
  echo "未找到 DevEco Studio.app: ${deveco_app}"
  exit 1
fi

deveco_sdk_root="${deveco_app}/Contents/sdk"

if [[ ! -f "${deveco_sdk_root}/default/sdk-pkg.json" ]]; then
  echo "DevEco Studio 未包含可用的 Harmony SDK: ${deveco_sdk_root}"
  exit 1
fi

cat > "${harmony_root}/local.properties" <<EOF
hwsdk.dir=${deveco_sdk_root}
EOF

echo
echo "Harmony project prepared with DevEco Studio:"
echo "  App: ${deveco_app}"
echo "  SDK: ${deveco_sdk_root}"
echo "  local.properties: ${harmony_root}/local.properties"
echo
echo "Next step:"
echo "  cd harmony && ./hvigorw tasks"
