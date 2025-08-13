#!/usr/bin/env bash
set -euo pipefail
RAW_BASE="https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main"
REMOTE="https://github.com/DrBojanglez/rl-bakkes.git"
TARGET="steamdeck"

say(){ printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }
say "OS release:"; [ -f /etc/os-release ] && sed 's/^/  /' /etc/os-release || true
say "Kernel: $(uname -a)"

WORK="$HOME/.rl-bakkes-tmp"; mkdir -p "$WORK"; cd "$WORK"

fetch(){ local rel="$1" out="$2" url="$RAW_BASE/$rel"; say "Fetch: $url";
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$url" -o "$out";
  elif command -v wget >/dev/null 2>&1; then wget -q "$url" -O "$out";
  elif command -v git >/dev/null 2>&1; then rm -rf tmpgit && git clone --depth=1 "$REMOTE" tmpgit && cp "tmpgit/$rel" "$out" && rm -rf tmpgit || { echo "git fallback failed"; exit 1; }
  else echo "Need curl, wget, or git"; exit 1; fi; }

TARGET_DIR="$HOME/RocketLeague/scripts"
mkdir -p "$TARGET_DIR" "$TARGET_DIR/logs" "$TARGET_DIR/includes"

# Always fetch core loader
fetch core/rl_bakkes_core.sh "$TARGET_DIR/rl_bakkes_core.sh"

# Fetch modules from manifest (NOUNSET-SAFE)
MAN_TMP="$WORK/modules.manifest"
fetch installers/modules.manifest "$MAN_TMP"
rel=""
set +u
while IFS= read -r rel || [ -n "${rel:-}" ]; do
  line="${rel:-}"
  # skip blank and comments
  [[ -z "$line" || "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]] && continue
  dir="$(dirname "$line")"
  mkdir -p "$TARGET_DIR/$dir"
  fetch "$line" "$TARGET_DIR/$line"
done < "$MAN_TMP"
set -u
# Fetch launcher for target
fetch "launchers/steamdeck.sh" "$TARGET_DIR/rl_steamdeck.sh"
chmod +x "$TARGET_DIR"/rl_*.sh "$TARGET_DIR/rl_bakkes_core.sh" || true
chmod +x "$TARGET_DIR/includes/"*.sh || true

# Arg sanitizer (ignore leading --)
ARGS=( "$@" ); if [[ "${ARGS[0]:-}" == "--" ]]; then ARGS=( "${ARGS[@]:1}" ); fi
say "Launching platform script: steamdeck"
bash "$TARGET_DIR/rl_steamdeck.sh" "${ARGS[@]}"
