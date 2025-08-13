#!/usr/bin/env bash
set -euo pipefail
RAW_BASE="https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main"
REMOTE="git@github.com:DrBojanglez/rl-bakkes.git"
TARGET="debian"

say(){ printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$*"; }

say "OS release:"
[ -f /etc/os-release ] && sed 's/^/  /' /etc/os-release || true
say "Kernel: $(uname -a)"

hint_install(){
  local tool="$1" pkg="$2"
  if ! command -v "$tool" >/dev/null 2>&1; then
    say "Missing '$tool'. Install suggestion:"
    if command -v apt >/dev/null 2>&1; then
      say "  sudo apt update && sudo apt install -y $pkg"
    elif command -v dnf >/dev/null 2>&1; then
      say "  sudo dnf install -y $pkg"
    elif command -v pacman >/dev/null 2>&1; then
      say "  sudo pacman -S --needed $pkg"
    else
      say "  Install package: $pkg"
    fi
  fi
}

# Recommend core tools
hint_install curl curl
hint_install wget wget
hint_install git git

WORK="$HOME/.rl-bakkes-tmp"
mkdir -p "$WORK"
cd "$WORK"

fetch(){
  local rel="$1" out="$2"
  local url="$RAW_BASE/$rel"
  say "Fetch: $url"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$out"
  elif command -v git >/dev/null 2>&1; then
    say "No curl/wget; attempting git clone fallback…"
    rm -rf tmpgit && mkdir -p tmpgit
    if git clone --depth=1 "$REMOTE" tmpgit; then
      cp "tmpgit/$rel" "$out"
      rm -rf tmpgit
    else
      say "git clone fallback failed; please install curl or wget."
      exit 1
    fi
  else
    say "ERROR: need curl, wget, or git to download files."
    exit 1
  fi
}

TARGET_DIR="$HOME/RocketLeague/scripts"
mkdir -p "$TARGET_DIR" "$TARGET_DIR/logs"

# Try git clone for full experience; else fetch only needed files
if command -v git >/dev/null 2>&1; then
  REPO="$WORK/rl-bakkes"
  if [ -d "$REPO/.git" ]; then
    (cd "$REPO" && git pull --ff-only) || say "git pull failed; continuing with existing clone"
  else
    if ! git clone --depth=1 "$REMOTE" "$REPO"; then
      say "git clone failed; will fetch raw files instead"
    fi
  fi
  if [ -d "$REPO/core" ]; then
    cp "$REPO/core/rl_bakkes_core.sh" "$TARGET_DIR/"
    cp "$REPO/launchers/debian.sh" "$TARGET_DIR/rl_debian.sh"
  else
    fetch "core/rl_bakkes_core.sh" "$TARGET_DIR/rl_bakkes_core.sh"
    fetch "launchers/debian.sh" "$TARGET_DIR/rl_debian.sh"
  fi
else
  fetch "core/rl_bakkes_core.sh" "$TARGET_DIR/rl_bakkes_core.sh"
  fetch "launchers/debian.sh" "$TARGET_DIR/rl_debian.sh"
fi

chmod +x "$TARGET_DIR/rl_bakkes_core.sh" "$TARGET_DIR/rl_debian.sh"

say "Launching platform script: debian"
bash "$TARGET_DIR/rl_debian.sh" "$@"
