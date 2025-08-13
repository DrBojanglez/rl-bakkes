# rev4 bakkes/protontricks
pick_protontricks(){
  if has_cmd protontricks; then echo "protontricks"
  elif has_cmd flatpak && flatpak info com.github.Matoking.protontricks >/dev/null 2>&1; then
    echo "flatpak run --branch=stable com.github.Matoking.protontricks"
  else echo ""; fi
}
PROTONTRICKS_CMD="$(pick_protontricks)"

ensure_vcrun2017(){
  [ -n "$PROTONTRICKS_CMD" ] || { WARN "protontricks missing; cannot manage vcrun2017 automatically"; return 0; }
  LOG "Checking vcrun2017…"
  if $PROTONTRICKS_CMD -q "$APPID" list-installed 2>/dev/null | grep -iq 'vcrun2017'; then LOG "vcrun2017 present."
  else
    WARN "vcrun2017 not detected."
    if ask_yes_no "Install vcrun2017 into this prefix now?" "Y"; then RUN $PROTONTRICKS_CMD "$APPID" vcrun2017; LOG "vcrun2017 installed."; else WARN "Continuing without vcrun2017 (injection may fail)."; fi
  fi
}

download_bakkes_installer(){
  [ -f "$BAKKES_INSTALLER" ] && { LOG "Installer present: $BAKKES_INSTALLER"; return 0; }
  if has_cmd curl; then RUN curl -L "$BAKKES_URL" -o "$BAKKES_INSTALLER"
  elif has_cmd wget; then RUN wget -O "$BAKKES_INSTALLER" "$BAKKES_URL"
  else
    WARN "No curl/wget. Open download page?"
    if has_cmd xdg-open && ask_yes_no "Open in browser?" "Y"; then RUN xdg-open "$BAKKES_URL" || true; WARN "Save to: $BAKKES_INSTALLER and re-run."; fi
  fi
}
install_bakkes_into_prefix(){
  [ -f "$BAKKES_INSTALLER" ] || { WARN "Installer missing: $BAKKES_INSTALLER"; return 1; }
  [ -n "$PROTONTRICKS_CMD" ] || { WARN "protontricks missing; cannot run installer in prefix automatically"; return 1; }
  RUN $PROTONTRICKS_CMD -c "wine \"$BAKKES_INSTALLER\"" "$APPID"
}
inject_bakkes(){ [ -z "$PROTONTRICKS_CMD" ] && { WARN "protontricks missing; skipping injection."; return 0; }; RUN $PROTONTRICKS_CMD -c "wine \"$BAKKES_PATH\"" "$APPID"; }
