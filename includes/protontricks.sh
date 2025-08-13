# rev5.0.9: ensure protontricks exists (Debian/Ubuntu/Pop!_OS first; flatpak fallback if available)
ensure_protontricks() {
  if command -v protontricks >/dev/null 2>&1; then
    LOG "protontricks present."
    return 0
  fi
  WARN "protontricks missing; required to install VC runtimes into the Rocket League prefix."

  # Prefer apt on Debian/Ubuntu/Pop!_OS
  if [ -f /etc/debian_version ]; then
    if command -v sudo >/dev/null 2>&1; then
      if ask_yes_no "Install protontricks with apt now?" Y; then
        RUN sudo apt-get update
        RUN sudo apt-get install -y protontricks
        if command -v protontricks >/dev/null 2>&1; then
          LOG "protontricks installed via apt."
          return 0
        fi
        WARN "apt install finished but protontricks not found."
      else
        WARN "User declined apt install of protontricks."
      fi
    else
      WARN "sudo not found; cannot apt install protontricks automatically."
    fi
  fi

  # Flatpak fallback if available (works on many desktops; not required)
  if command -v flatpak >/dev/null 2>&1; then
    if ask_yes_no "Install Protontricks (Flatpak) from Flathub?" N; then
      RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      RUN flatpak install -y --noninteractive flathub com.github.Matoking.protontricks
      LOG "Protontricks (Flatpak) installed. You may need to launch it separately for GUI usage."
      # CLI binary name for flatpak differs; we still prefer native protontricks for scripting.
    fi
  fi

  # Final check
  if command -v protontricks >/dev/null 2>&1; then
    return 0
  fi
  WARN "protontricks still not available; VC runtime cannot be auto‑installed."
  return 1
}
