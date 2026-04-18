#!/bin/zsh
set -euo pipefail

cli_root="${HARMONY_CLI_ROOT:-${HOME}/.harmony/tools/commandline-tools/command-line-tools}"
sdk_root="${HARMONY_SDK_ROOT:-${HOME}/.harmony/sdk}"
deveco_app="${DEVECO_STUDIO_APP:-/Applications/DevEco-Studio.app}"

sdkmgr="${cli_root}/bin/sdkmgr"
ohpm="${cli_root}/bin/ohpm"
codelinter="${cli_root}/bin/codelinter"

echo "Harmony CLI root: ${cli_root}"
echo "Harmony SDK root: ${sdk_root}"
echo "DevEco Studio app: ${deveco_app}"
echo

if [[ -x "${sdkmgr}" ]]; then
  echo "[ok] sdkmgr"
  "${sdkmgr}" version
else
  echo "[missing] sdkmgr"
fi

if [[ -x "${ohpm}" ]]; then
  echo "[ok] ohpm"
  "${ohpm}" --version
else
  echo "[missing] ohpm"
fi

if [[ -x "${codelinter}" ]]; then
  echo "[ok] codelinter"
  "${codelinter}" --version
else
  echo "[missing] codelinter"
fi

echo
if [[ -d "${sdk_root}" ]]; then
  echo "SDK root contents:"
  find "${sdk_root}" -maxdepth 2 -mindepth 1 | sort
else
  echo "SDK root is not created yet."
fi

echo
if [[ -d "${deveco_app}" ]]; then
  deveco_ohpm="${deveco_app}/Contents/tools/ohpm/bin/ohpm"
  deveco_node="${deveco_app}/Contents/tools/node/bin/node"
  deveco_hvigor="${deveco_app}/Contents/tools/hvigor/bin/hvigorw.js"
  deveco_sdk_root="${deveco_app}/Contents/sdk"

  echo "DevEco Studio 6 bundle detected."
  if [[ -x "${deveco_ohpm}" ]]; then
    echo "[ok] DevEco ohpm"
    "${deveco_ohpm}" --version
  fi
  if [[ -x "${deveco_node}" && -f "${deveco_hvigor}" ]]; then
    echo "[ok] DevEco hvigor"
    "${deveco_node}" "${deveco_hvigor}" --version
  fi
  if [[ -f "${deveco_sdk_root}/default/sdk-pkg.json" ]]; then
    echo "[ok] DevEco bundled Harmony SDK"
    plutil -p "${deveco_sdk_root}/default/sdk-pkg.json"
    find "${deveco_sdk_root}/default" -maxdepth 2 -mindepth 1 | sort
  fi
fi

echo
if [[ -x "${sdkmgr}" ]]; then
  remote_components="$("${sdkmgr}" list --sdk-directory="${sdk_root}" 2>/dev/null || true)"
  highest_api="$(printf '%s\n' "${remote_components}" | awk 'NR > 2 && $3 ~ /^[0-9]+$/ { print $3 }' | sort -nr | head -n 1)"

  if [[ -n "${highest_api}" ]]; then
    echo "Highest remote API version visible to current sdkmgr: ${highest_api}"
    if [[ "${highest_api}" -le 9 ]]; then
      echo "Note: current public CLI stream appears to expose HarmonyOS 3.1-era SDK components only."
      echo "      HarmonyOS 6 / latest HarmonyOS usually requires the current Beta / preview toolchain access."
    fi
  else
    echo "Could not determine the highest remote API version from sdkmgr list."
  fi
fi
