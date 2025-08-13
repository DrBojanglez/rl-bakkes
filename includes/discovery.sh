# rev5.0.5 discovery: sanitized VDF parsing + safe quoting
# LOG writes to stderr (see includes/logging.sh)

# Echo each Steam library root (including the main Steam dir)
steam_libraries(){
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

  # Extract "path" entries, normalize, sanitize, expand ~, and only emit existing dirs
  awk 'BEGIN{IGNORECASE=1}
       /"path"[ \t]*"/ {
         if (match($0,/"path"[ \t]*"([^"]+)"/,a)) {
           gsub("\\\\","/",a[1]);   # backslashes -> slashes
           print a[1];
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

find_rl_dir(){
  local sd="${1:-}"
  local lib=""
  while IFS= read -r lib; do
    local cand="$lib/steamapps/common/Rocket League"
    LOG "Check RL dir: $cand"
    if [ -d "$cand" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done < <(steam_libraries "$sd")

  LOG "Fallback RL search under $sd…"
  if [ -n "$sd" ]; then
    find "$sd" -type d -path "*/steamapps/common/Rocket League" -print -quit 2>/dev/null || true
  fi
}

find_prefix_dir(){
  local sd="${1:-}"
  local p="$sd/steamapps/compatdata/${APPID}/pfx"
  LOG "Check Proton prefix: $p"
  [ -d "$p" ] && printf '%s\n' "$p" || true
}

find_bakkes(){
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
