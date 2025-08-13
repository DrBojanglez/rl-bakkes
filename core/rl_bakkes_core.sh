#!/usr/bin/env bash
# rev4 loader: source modules from local install dir first, else repo layout
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Prefer neighbor includes (curl one-liner install)
if [ -d "$SCRIPT_DIR/includes" ]; then INC="$SCRIPT_DIR/includes"
# Fallback to repo layout (core/../includes)
elif [ -d "$(cd "$SCRIPT_DIR/.." && pwd)/includes" ]; then INC="$(cd "$SCRIPT_DIR/.." && pwd)/includes"
# Fallback to user install path
elif [ -d "$HOME/RocketLeague/scripts/includes" ]; then INC="$HOME/RocketLeague/scripts/includes"
else echo "Includes folder not found"; exit 70; fi

# shellcheck source=includes/*.sh
source "$INC/logging.sh"
# pass all args through env init so flags are parsed before logging/exec
source "$INC/env.sh" "$@"
source "$INC/steam.sh"
source "$INC/discovery.sh"
source "$INC/bakkes.sh"
source "$INC/config.sh"
source "$INC/main.sh"
rl_main "$@"
