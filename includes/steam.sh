# rev4 steam helpers
steam_running(){ pgrep -x steam >/dev/null 2>&1 || pgrep -f "flatpak.*com.valvesoftware.Steam" >/dev/null 2>&1; }
launch_rl(){
  if has_cmd steam; then RUN steam -applaunch "$APPID" >/dev/null 2>&1 &
  elif has_cmd flatpak && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then RUN flatpak run com.valvesoftware.Steam -applaunch "$APPID" >/dev/null 2>&1 &
  else ERR "Steam not found (native or Flatpak)."
  fi
}
rl_is_running(){ pgrep -fa "RocketLeague\.exe" >/dev/null 2>&1; }
steam_dir_guess(){
  IFS=':' read -r -a paths <<< "$PRIORITY_STEAM_PATHS"
  for p in "${paths[@]}"; do
    local exp="${p/#\~/$HOME}"
    [ -d "$exp" ] && { echo "$exp"; return 0; }
  done
  ERR "Steam dir not found in: $PRIORITY_STEAM_PATHS"
}
offer_rl_install(){
  WARN "Rocket League is not installed on this machine."
  if ask_yes_no "Open Steam to install Rocket League now?" "Y"; then
    if has_cmd xdg-open; then RUN xdg-open "steam://install/252950" || true
    elif has_cmd steam; then RUN steam steam://install/252950 || true
    else WARN "Steam not found in PATH; please install Steam and then Rocket League."
    fi
  fi
}
