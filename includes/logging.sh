# rev4 logging & helpers
set -euo pipefail
_now(){ date '+%H:%M:%S'; }
LOG(){ printf "[%s] %s\n" "$(_now)" "$*"; }
WARN(){ printf "[%s] ⚠ %s\n" "$(_now)" "$*" >&2; }
ERR(){ printf "[%s] ❌ %s\n" "$(_now)" "$*" >&2; exit 70; }
RUN(){ LOG "\$ $*"; if [ "${DEBUG:-0}" -eq 0 ]; then "$@"; else LOG "(debug: skipped)"; fi; }
has_cmd(){ command -v "$1" >/dev/null 2>&1; }
ask_yes_no(){ local p="$1" d="${2:-Y}" yn="[y/N]"; [[ $d =~ ^[Yy]$ ]] && yn="[Y/n]"; while true; do read -r -p "$p $yn " ans || ans=""; ans="${ans:-$d}"; case $ans in [Yy]*)return 0;;[Nn]*)return 1;;*)echo "Please answer y or n.";; esac; done; }
