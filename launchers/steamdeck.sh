#!/usr/bin/env bash
set -euo pipefail
export PRIORITY_STEAM_PATHS="$HOME/.local/share/Steam:$HOME/.steam/steam"
export WAIT_SECS=120
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
source "$SCRIPT_DIR/core/rl_bakkes_core.sh" "$@"
