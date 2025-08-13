#!/usr/bin/env bash
set -euo pipefail
export PRIORITY_STEAM_PATHS="$HOME/.steam/steam:$HOME/.local/share/Steam"
export WAIT_SECS=100
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
source "$SCRIPT_DIR/core/rl_bakkes_core.sh" "$@"
