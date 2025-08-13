# rev5.0.8 discovery — functions only; sanitized VDF; appmanifest installdir; case fallbacks
# LOG writes to stderr (see includes/logging.sh)

steam_libraries() {
  local sd="${1:-}"
  [ -n "$sd" ] || return 0
  [ -d "$sd" ] || return 0

  printf '%s\n' "$sd"

  local vdf=""
  if [ -f "$sd/steamapps/libraryfolders.vdf" ]; then
    vdf="$sd/steamapps/libraryfolders.vdf"
  elif [ -f "$sd/libraryfolders.vdf" ]; then
    vdf="$sd/libraryfolders.vdf"
  else
    return 0
  fi

  LOG "Parsing Steam libraries: $vdf"

  awk 'BEGIN{IGNORECASE=1}
       /"path"[ \t]*"/ {
         if (match($0,/"path"[ \t]*"([^"]+)"/,a)) {
           gsub("\\\\","/",a[1]); print a[1];
         }
       }' "$vdf" 2>/dev/null \
    | tr -d '\r' \
    | tr -cd '\11\12\15\40-\176' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | while IFS= read -r p; do
        case "$p" in "~/"*) p="${HOME}/${p#~/}";; "~") p="$HOME";; esac
        [ -d "$p" ] && printf '%s\n' "$p"
      done
}

find_rl_dir() {
  local sd="${1:-}"
  local lib="" cand="" acf="" INST=""

  # 1) Exact installdir from appmanifest if present
  acf="$sd/steamapps/appmanifest_252950.acf"
  if [ -n "$sd" ] && [ -f "$acf" ]; then
    INST="$(awk -F\" '/\"installdir\"/{print $4}' "$acf" 2>/dev/null | tr -d '\r')"
    if [ -n "$INST" ]; then
      cand="$sd/steamapps/common/$INST"
      LOG "Appmanifest installdir: $cand"
      [ -d "$cand" ] && { printf '%s\n' "$cand"; return 0; }
    fi
  fi

  # 2) Probe common names across all libraries
  while IFS= read -r lib; do
    for name in "Rocket League" "rocketleague"; do
      cand="$lib/steamapps/common/$name"
      LOG "Check RL dir: $cand"
      [ -d "$cand" ] && { printf '%s\n' "$cand"; return 0; }
    done
  done < <(steam_libraries "$sd")

  # 3) Last-resort find
  LOG "Fallback RL search under $sd…"
  if [ -n "$sd" ]; then
    find "$sd" -type d \
      \( -path "*/steamapps/common/Rocket League" -o -path "*/steamapps/common/rocketleague" \) \
      -print -quit 2>/dev/null || true
  fi
}

find_prefix_dir() {
  local sd="${1:-}"
  local p="$sd/steamapps/compatdata/${APPID}/pfx"
  LOG "Check Proton prefix: $p"
  [ -d "$p" ] && printf '%s\n' "$p" || true
}

find_bakkes() {
  local pfx="${1:-}"
  [ -n "$pfx" ] || return 0
  local cand="$pfx/drive_c/Program Files/BakkesMod/BakkesMod.exe"
  LOG "Check BakkesMod: $cand"
  if [ -f "$cand" ]; then
    printf '%s\n' "$cand"
    return 0
  fi
  LOG "Searching BakkesMod.exe under $pfx/drive_c…"
  find "$pfx/drive_c" -type f -iname "BakkesMod.exe" -print -quit 2>/dev/null || true
}
