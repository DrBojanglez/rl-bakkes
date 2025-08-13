#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
: "${APPID:=252950}"                           # Rocket League
: "${BASE_DIR:=$HOME/RocketLeague/scripts}"    # config + logs
: "${CONFIG:=$BASE_DIR/.rlbakkes.cfg}"
: "${LOG_DIR:=$BASE_DIR/logs}"
: "${BAKKES_URL:=https://bakkesmod.com/download.php}"
: "${BAKKES_INSTALLER:=$BASE_DIR/BakkesModSetup.exe}"
: "${WAIT_SECS:=90}"                           # RL startup wait
: "${PRIORITY_STEAM_PATHS:=~/.steam/steam:~/.local/share/Steam}"

# Flags
DEBUG=0; FORCE=0; NO_INJECT=0
for a in "${@:-}"; do
  case "$a" in
    --debug) DEBUG=1 ;;
    --force-rediscover) FORCE=1 ;;
    --no-inject) NO_INJECT=1 ;;
    *) echo "Unknown flag: $a" >&2; exit 64 ;;
  esac
done

# Logging
mkdir -p "$BASE_DIR" "$LOG_DIR"
TS="$(date '+%Y%m%d.%H%S')"
LOG_FILE="$LOG_DIR/rl_bakkes_${TS}.log"
exec > >(tee -a "$LOG_FILE") 2>&1
_now(){ date '+%H:%M:%S'; }
LOG(){ printf "[%s] %s\n" "$(_now)" "$*"; }
WARN(){ printf "[%s] ⚠ %s\n" "$(_now)" "$*" >&2; }
ERR(){ printf "[%s] ❌ %s\n" "$(_now)" "$*" >&2; exit 70; }
RUN(){ LOG "\$ $*"; if [ "$DEBUG" -eq 0 ]; then "$@"; else LOG "(debug: skipped)"; fi; }
has_cmd(){ command -v "$1" >/dev/null 2>&1; }
ask_yes_no(){ local p="$1" d="${2:-Y}" yn="[y/N]"; [[ $d =~ ^[Yy]$ ]] && yn="[Y/n]"; while true; do read -r -p "$p $yn " ans || ans=""; ans="${ans:-$d}"; case $ans in [Yy]*)return 0;;[Nn]*)return 1;;*)echo "Please answer y or n.";; esac; done; }

# --- protontricks (native or flatpak) ---
pick_protontricks(){
  if has_cmd protontricks; then echo "protontricks"
  elif has_cmd flatpak && flatpak info com.github.Matoking.protontricks >/dev/null 2>&1; then
    echo "flatpak run --branch=stable com.github.Matoking.protontricks"
  else echo ""; fi
}
PROTONTRICKS_CMD="$(pick_protontricks)"

# --- helper: offer RL install via Steam if missing ---
offer_rl_install(){
  WARN "Rocket League is not installed on this machine."
  if ask_yes_no "Open Steam to install Rocket League now?" "Y"; then
    if command -v xdg-open >/dev/null 2>&1; then
      RUN xdg-open "steam://install/252950" || true
    elif command -v steam >/dev/null 2>&1; then
      RUN steam steam://install/252950 || true
    else
      WARN "Steam not found in PATH; please install Steam and install Rocket League."
    fi
  fi
}

# --- discovery ---
steam_dir_guess(){
  IFS=':' read -r -a paths <<< "$PRIORITY_STEAM_PATHS"
  for p in "${paths[@]}"; do p="${p/#\~/$HOME}"; [ -d "$p" ] && { echo "$p"; return 0; }; done
  ERR "Steam dir not found in: $PRIORITY_STEAM_PATHS"
}
steam_libraries(){
  local sd="$1" v1="$sd/steamapps/libraryfolders.vdf" v2="$sd/libraryfolders.vdf"
  echo "$sd"
  local v=""; [ -f "$v1" ] && v="$v1" || { [ -f "$v2" ] && v="$v2"; }
  [ -z "$v" ] && return 0
  LOG "Parsing Steam libraries: $v"
  awk 'BEGIN{IGNORECASE=1}/"path"[ \t]*"/{if(match($0,/"path"[ \t]*"([^"]+)"/,a))print a[1]}' "$v" |
    while read -r p; do p="${p/#\~/$HOME}"; [ -d "$p" ] && echo "$p"; done
}
find_rl_dir(){
  local sd="$1"
  while read -r lib; do local cand="$lib/steamapps/common/Rocket League"; LOG "Check RL dir: $cand"; [ -d "$cand" ] && { echo "$cand"; return 0; }; done < <(steam_libraries "$sd")
  LOG "Fallback RL search under $sd…"
  find "$sd" -type d -path "*/steamapps/common/Rocket League" -print -quit 2>/dev/null || true
}
find_prefix_dir(){ local sd="$1" p="$sd/steamapps/compatdata/$APPID/pfx"; LOG "Check Proton prefix: $p"; [ -d "$p" ] && echo "$p" || true; }
find_bakkes(){ local pfx="$1" cand="$pfx/drive_c/Program Files/BakkesMod/BakkesMod.exe"; LOG "Check BakkesMod: $cand"; [ -f "$cand" ] && { echo "$cand"; return 0; }; LOG "Searching BakkesMod.exe under $pfx/drive_c…"; find "$pfx/drive_c" -type f -iname "BakkesMod.exe" -print -quit 2>/dev/null || true; }

# --- config ---
write_config(){ LOG "Write config: $CONFIG"; cat >"$CONFIG" <<EOF2
APPID=$APPID
STEAM_DIR=$1
RL_DIR=$2
PFX_DIR=$3
BAKKES_PATH=$4
EOF2
LOG "CONFIG: APPID=$APPID"; LOG "CONFIG: STEAM_DIR=$1"; LOG "CONFIG: RL_DIR=$2"; LOG "CONFIG: PFX_DIR=$3"; LOG "CONFIG: BAKKES_PATH=$4"; }
load_config(){ LOG "Load config: $CONFIG"; source "$CONFIG"; LOG "Loaded APPID=${APPID:-} STEAM_DIR=${STEAM_DIR:-} RL_DIR=${RL_DIR:-} PFX_DIR=${PFX_DIR:-} BAKKES_PATH=${BAKKES_PATH:-}"; }
valid_config(){ [ "${APPID:-}" = "252950" ] && [ -d "${STEAM_DIR:-/n}" ] && [ -d "${RL_DIR:-/n}" ] && [ -d "${PFX_DIR:-/n}" ] && [ -f "${BAKKES_PATH:-/n}" ]; }

# --- launch & inject ---
steam_running(){ pgrep -x steam >/dev/null 2>&1 || pgrep -f "flatpak.*com.valvesoftware.Steam" >/dev/null 2>&1; }
launch_rl(){
  if has_cmd steam; then RUN steam -applaunch "$APPID" >/dev/null 2>&1 &
  elif has_cmd flatpak && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then RUN flatpak run com.valvesoftware.Steam -applaunch "$APPID" >/dev/null 2>&1 &
  else ERR "Steam not found (native or Flatpak)."
  fi
}
rl_is_running(){ pgrep -fa "RocketLeague\.exe" >/dev/null 2>&1; }
inject_bakkes(){ [ -z "$PROTONTRICKS_CMD" ] && { WARN "protontricks missing; skipping injection."; return 0; }; RUN $PROTONTRICKS_CMD -c "wine \"$BAKKES_PATH\"" "$APPID"; }
ensure_vcrun2017(){
  [ -z "$PROTONTRICKS_CMD" ] && { WARN "protontricks missing; cannot manage vcrun2017 automatically"; return 0; }
  LOG "Checking vcrun2017…"
  if $PROTONTRICKS_CMD -q "$APPID" list-installed 2>/dev/null | grep -iq 'vcrun2017'; then LOG "vcrun2017 present."
  else
    WARN "vcrun2017 not detected."
    if ask_yes_no "Install vcrun2017 into this prefix now?" "Y"; then RUN $PROTONTRICKS_CMD "$APPID" vcrun2017; LOG "vcrun2017 installed."; else WARN "Continuing without vcrun2017 (injection may fail)."; fi
  fi
}
download_bakkes_installer(){
  [ -f "$BAKKES_INSTALLER" ] && { LOG "Installer present: $BAKKES_INSTALLER"; return 0; }
  if command -v curl >/dev/null 2>&1; then RUN curl -L "$BAKKES_URL" -o "$BAKKES_INSTALLER"
  elif command -v wget >/dev/null 2>&1; then RUN wget -O "$BAKKES_INSTALLER" "$BAKKES_URL"
  else
    WARN "No curl/wget. Open download page?"
    if command -v xdg-open >/dev/null 2>&1 && ask_yes_no "Open in browser?" "Y"; then RUN xdg-open "$BAKKES_URL" || true; WARN "Save to: $BAKKES_INSTALLER and re-run."; fi
  fi
}
install_bakkes_into_prefix(){
  [ -f "$BAKKES_INSTALLER" ] || { WARN "Installer missing: $BAKKES_INSTALLER"; return 1; }
  [ -n "$PROTONTRICKS_CMD" ] || { WARN "protontricks missing; cannot run installer in prefix automatically"; return 1; }
  RUN $PROTONTRICKS_CMD -c "wine \"$BAKKES_INSTALLER\"" "$APPID"
}

# --- main ---
LOG "===== RL + BakkesMod launcher ====="
LOG "Config: $CONFIG"
LOG "Logs:   $LOG_FILE"
LOG "Flags:  debug=$DEBUG force_rediscover=$FORCE no_inject=$NO_INJECT"

if [ -f "$CONFIG" ] && [ "$FORCE" -eq 0 ]; then
  load_config || true
  if ! valid_config; then WARN "Config invalid → rediscover"; rm -f "$CONFIG"; else LOG "Config valid."; fi
fi

if [ ! -f "$CONFIG" ]; then
  LOG "Discovering Steam/RL/prefix…"
  STEAM_DIR="$(steam_dir_guess)" || ERR "Steam dir not found."
  LOG "STEAM_DIR=$STEAM_DIR"
  RL_DIR="$(find_rl_dir "$STEAM_DIR")"
  if [ -z "${RL_DIR:-}" ]; then
    offer_rl_install
    ERR "Rocket League dir not found (install it, then re-run)"
  fi
  LOG "RL_DIR=$RL_DIR"
  PFX_DIR="$(find_prefix_dir "$STEAM_DIR")"; [ -n "${PFX_DIR:-}" ] || ERR "Proton prefix not found for AppID $APPID"
  LOG "PFX_DIR=$PFX_DIR"

  ensure_vcrun2017

  BAKKES_PATH="$(find_bakkes "$PFX_DIR")"
  if [ -z "${BAKKES_PATH:-}" ]; then
    WARN "BakkesMod not found in prefix."
    if ask_yes_no "Download and install BakkesMod now?" "Y"; then
      download_bakkes_installer
      [ -f "$BAKKES_INSTALLER" ] && install_bakkes_into_prefix || true
      BAKKES_PATH="$(find_bakkes "$PFX_DIR")"
    fi
  fi
  [ -n "${BAKKES_PATH:-}" ] || ERR "BakkesMod still not found after install."

  write_config "$STEAM_DIR" "$RL_DIR" "$PFX_DIR" "$BAKKES_PATH"
else
  load_config
fi

valid_config || ERR "Configuration invalid after (re)load."

if ! steam_running; then WARN "Steam not detected; continuing (will try CLI launch)."; fi
ensure_vcrun2017

if rl_is_running; then LOG "Rocket League already running."
else LOG "Launching Rocket League…"; launch_rl; fi

LOG "Waiting for Rocket League to start (max ${WAIT_SECS}s)…"
for ((i=0; i<WAIT_SECS; i++)); do rl_is_running && { LOG "Rocket League detected."; break; }; sleep 1; done
rl_is_running || ERR "Rocket League did not start in time."

if [ "$NO_INJECT" -eq 1 ]; then LOG "Skipping injection (--no-inject set)."
else LOG "Injecting BakkesMod: $BAKKES_PATH"; inject_bakkes; fi

LOG "✅ Done. Log file: $LOG_FILE"
