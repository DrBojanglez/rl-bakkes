# rev4 main orchestration
rl_main(){
  # config -> discover -> launch -> inject
  if [ -f "$CONFIG" ] && [ "${FORCE:-0}" -eq 0 ]; then
    load_config || true
    if ! valid_config; then WARN "Config invalid → rediscover"; rm -f "$CONFIG"; else LOG "Config valid."; fi
  fi

  if [ ! -f "$CONFIG" ]; then
    LOG "Discovering Steam/RL/prefix…"
    STEAM_DIR="$(steam_dir_guess)" || ERR "Steam dir not found."
    LOG "STEAM_DIR=$STEAM_DIR"
    RL_DIR="$(find_rl_dir "$STEAM_DIR")"
    if [ -z "${RL_DIR:-}" ]; then offer_rl_install; ERR "Rocket League dir not found (install it, then re-run)"; fi
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

  if [ "${NO_INJECT:-0}" -eq 1 ]; then LOG "Skipping injection (--no-inject set)."
  else LOG "Injecting BakkesMod: $BAKKES_PATH"; inject_bakkes; fi

  LOG "✅ Done. Log file: $LOG_FILE"
}
