#!/usr/bin/env bash
# rev5 thin wrapper
set -euo pipefail
TARGET="steamdeck"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main}"
REMOTE="${REMOTE:-https://github.com/DrBojanglez/rl-bakkes.git}"

# source the shared library from RAW (curl preferred, then wget, then git fallback)
if command -v curl >/dev/null 2>&1; then
  source <(curl -fsSL "${RAW_BASE}/installers/lib.sh")
elif command -v wget >/dev/null 2>&1; then
  source <(wget -q -O - "${RAW_BASE}/installers/lib.sh")
else
  tmp="$(mktemp)"; git clone --depth=1 "${REMOTE}" "$tmp.git" && source "$tmp.git/installers/lib.sh" && rm -rf "$tmp.git"
fi

main "$@"
