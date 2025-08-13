#!/usr/bin/env bash
# rev5 shared installer library: nounset-safe, centralized logic
set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main}"
REMOTE="${REMOTE:-https://github.com/DrBojanglez/rl-bakkes.git}"
TARGET="${TARGET:-universal}"   # debian | steamdeck | universal

say(){ printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }

# Hardened fetch with defaults + clear errors + HTTPS git fallback
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
    if git clone --depth=1 "$REMOTE" .tmpgit; then
      cp ".tmpgit/$REL" "$OUT" || { say "git fallback: path not found: $REL"; exit 2; }
      rm -rf .tmpgit
    else
      say "git fallback failed (network/permissions)."; exit 2
    fi
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

  # core loader always
  fetch core/rl_bakkes_core.sh "$TARGET_DIR/rl_bakkes_core.sh"

  # manifest chosen per profile
  case "$TARGET" in
    debian)    MAN_REL="installers/manifest.debian" ;;
    steamdeck) MAN_REL="installers/manifest.steamdeck" ;;
    *)         MAN_REL="installers/manifest.universal" ;;
  esac

  MAN_TMP="$WORK/modules.manifest"
  fetch "$MAN_REL" "$MAN_TMP"

  # nounset-safe, comment/blank aware loop
  set +u
  REL=""; LINE=""; DIR=""
  while IFS= read -r REL || [ -n "${REL:-}" ]; do
    LINE="${REL:-}"
    # Trim
    LINE="$(printf "%s" "$LINE" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    # Skip empty and comments
    if [[ -z "$LINE" || "${LINE:0:1}" == "#" ]]; then
      continue
    fi
    DIR="$(dirname "$LINE")"
    mkdir -p "$TARGET_DIR/$DIR"
    fetch "$LINE" "$TARGET_DIR/$LINE"
  done < "$MAN_TMP"
  set -u

  # platform launcher
  fetch "launchers/${TARGET}.sh" "$TARGET_DIR/rl_${TARGET}.sh"
  chmod +x "$TARGET_DIR"/rl_*.sh "$TARGET_DIR/rl_bakkes_core.sh" 2>/dev/null || true
  chmod +x "$TARGET_DIR/includes/"*.sh 2>/dev/null || true

  # Arg sanitizer (ignore leading --)
  ARGS=( "$@" ); if [[ "${ARGS[0]:-}" == "--" ]]; then ARGS=( "${ARGS[@]:1}" ); fi
  say "Launching platform script: $TARGET"
  bash "$TARGET_DIR/rl_${TARGET}.sh" "${ARGS[@]}"
}
