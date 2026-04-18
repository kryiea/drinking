#!/bin/zsh
set -euo pipefail

cli_root="${HOME}/.harmony/tools/commandline-tools"
download_root="${HOME}/.harmony/downloads"
archive_path="${download_root}/commandline-tools-mac-2.0.0.2.zip"
official_url="https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_package_901_9/40/v3/7ib55XtMQGqFoSx-_pmjzg/commandline-tools-mac-2.0.0.2.zip?HW-CC-KV=V1&HW-CC-Date=20230621T074501Z&HW-CC-Expire=315360000&HW-CC-Sign=47997A296E519CE2132634C45D85DC57E96E174EBF55C1B4A3A7EDD256466FE9"

mkdir -p "${download_root}" "${cli_root}"

if [[ ! -f "${archive_path}" ]]; then
  echo "Downloading official HarmonyOS command line tools..."
  curl -L "${official_url}" -o "${archive_path}"
else
  echo "Using cached archive: ${archive_path}"
fi

echo "Extracting command line tools..."
unzip -q -o "${archive_path}" -d "${cli_root}"

ohpm_init="${cli_root}/command-line-tools/ohpm/bin/init"
if [[ -x "${ohpm_init}" ]]; then
  echo "Initializing ohpm..."
  (cd "${cli_root}/command-line-tools/ohpm" && ./bin/init)
fi

cat <<EOF

HarmonyOS CLI has been prepared at:
  ${cli_root}/command-line-tools

Available tools:
  ${cli_root}/command-line-tools/bin/sdkmgr
  ${cli_root}/command-line-tools/bin/ohpm
  ${cli_root}/command-line-tools/bin/codelinter

Suggested shell exports:
  export HARMONY_CLI_ROOT="${cli_root}/command-line-tools"
  export PATH="\$HARMONY_CLI_ROOT/bin:\$PATH"

EOF
