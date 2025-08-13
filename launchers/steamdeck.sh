#!/usr/bin/env bash
set -euo pipefail
export PRIORITY_STEAM_PATHS="$HOME/.local/share/Steam:$HOME/.steam/steam"
export WAIT_SECS=120
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/rl_bakkes_core.sh" ]; then
  source "$SCRIPT_DIR/rl_bakkes_core.sh" "$@"
else
  PARENT="$(cd "$SCRIPT_DIR/.." && pwd)"
  source "$PARENT/core/rl_bakkes_core.sh" "$@"
fi
