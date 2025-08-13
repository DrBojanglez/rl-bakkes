#!/usr/bin/env bash
# rev5.0.12 shared installer library
set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main}"
REMOTE="${REMOTE:-https://github.com/DrBojanglez/rl-bakkes.git}"
TARGET="${TARGET:-universal}"   # debian | steamdeck | universal

say(){ printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }

# Hardened fetch with clear errors and git fallback
fetch(){
  local REL="${1:-}" OUT="${2:-}"
  if [[ -z "$REL" || -z "$OUT" ]]; then
    say "fetch: missing args (REL='$REL' OUT='$OUT')"; exit 2
  fi
  local URL="$RAW_BASE/$REL"
  say "Fetch: $URL"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$URL" -o "$OUT" || { say "curl failed: $URL"; exit 2; }
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$URL" -O "$OUT" || { say "wget failed: $URL"; exit 2; }
  elif command -v git >/dev/null 2>&1; then
    rm -rf .tmpgit
    git clone --depth=1 "$REMOTE" .tmpgit || { say "git clone failed"; exit 2; }
    cp ".tmpgit/$REL" "$OUT" || { say "git fallback path not found: $REL"; exit 2; }
    rm -rf .tmpgit
  else
    say "Need curl, wget, or git."; exit 2
  fi
}

main(){
  say "OS release:"; [ -f /etc/os-release ] && sed 's/^/  /' /etc/os-release || true
  say "Kernel: $(uname -a)"

  WORK="${WORK:-$HOME/.rl-bakkes-tmp}"; mkdir -p "$WORK"; cd "$WORK"
  TARGET_DIR="${TARGET_DIR:-$HOME/RocketLeague/scripts}"
  mkdir -p "$TARGET_DIR" "$TARGET_DIR/logs" "$TARGET_DIR/includes"

  # core loader
  fetch core/rl_bakkes_core.sh "$TARGET_DIR/rl_bakkes_core.sh"

  # choose manifest
  local MAN_REL
  case "$TARGET" in
    debian)    MAN_REL="installers/manifest.debian" ;;
    steamdeck) MAN_REL="installers/manifest.steamdeck" ;;
    *)         MAN_REL="installers/manifest.universal" ;;
  esac

  local MAN_TMP="$WORK/modules.manifest"
  fetch "$MAN_REL" "$MAN_TMP"

  # nounset-safe manifest loop
  set +u
  local REL LINE DIR
  REL=""; LINE=""; DIR=""
  while IFS= read -r REL || [ -n "${REL:-}" ]; do
    LINE="${REL:-}"
    LINE="$(printf "%s" "$LINE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    # skip blank or comment lines
    if [[ -z "$LINE" || "${LINE:0:1}" == "#" ]]; then
      continue
    fi
    DIR="$(dirname "$LINE")"
    mkdir -p "$TARGET_DIR/$DIR"
    fetch "$LINE" "$TARGET_DIR/$LINE"
  done < "$MAN_TMP"
  set -u

  # launcher
  fetch "launchers/${TARGET}.sh" "$TARGET_DIR/rl_${TARGET}.sh"
  chmod +x "$TARGET_DIR"/rl_*.sh "$TARGET_DIR/rl_bakkes_core.sh" 2>/dev/null || true
  chmod +x "$TARGET_DIR/includes/"*.sh 2>/dev/null || true

  # Arg sanitizer: drop a leading "--" then pass args only if any remain
  if [[ "${1:-}" == "--" ]]; then shift; fi
  say "Launching platform script: $TARGET"
  if [[ $# -gt 0 ]]; then
    bash "$TARGET_DIR/rl_${TARGET}.sh" "$@"
  else
    bash "$TARGET_DIR/rl_${TARGET}.sh"
  fi
}
