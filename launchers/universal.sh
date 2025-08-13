#!/usr/bin/env bash
set -euo pipefail
export PRIORITY_STEAM_PATHS="$HOME/.steam/steam:$HOME/.local/share/Steam"
export WAIT_SECS=100
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/rl_bakkes_core.sh" ]; then
  source "$SCRIPT_DIR/rl_bakkes_core.sh" "$@"
else
  PARENT="$(cd "$SCRIPT_DIR/.." && pwd)"
  source "$PARENT/core/rl_bakkes_core.sh" "$@"
fi
