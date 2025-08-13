# rev4 discovery (tolerant to unset vars)
steam_libraries(){
  local sd="${1:-}"
  [ -n "$sd" ] || return 0
  echo "$sd"
  local vdf=""
  [ -f "$sd/steamapps/libraryfolders.vdf" ] && vdf="$sd/steamapps/libraryfolders.vdf"
  [ -z "$vdf" ] && [ -f "$sd/libraryfolders.vdf" ] && vdf="$sd/libraryfolders.vdf"
  [ -z "$vdf" ] && return 0
  LOG "Parsing Steam libraries: $vdf"
  awk 'BEGIN{IGNORECASE=1}/"path"[ \t]*"/{if(match($0,/"path"[ \t]*"([^"]+)"/,a))print a[1]}' "$vdf" \
    | while read -r p; do p="${p/#\~/'$HOME'}"; [ -d "$p" ] && echo "$p"; done
}
find_rl_dir(){
  local sd="${1:-}"; local lib
  while read -r lib; do
    local cand="$lib/steamapps/common/Rocket League"
    LOG "Check RL dir: $cand"
    [ -d "$cand" ] && { echo "$cand"; return 0; }
  done < <(steam_libraries "$sd")
  LOG "Fallback RL search under $sd…"
  [ -n "$sd" ] && find "$sd" -type d -path "*/steamapps/common/Rocket League" -print -quit 2>/dev/null || true
}
find_prefix_dir(){ local sd="${1:-}"; local p="$sd/steamapps/compatdata/$APPID/pfx"; LOG "Check Proton prefix: $p"; [ -d "$p" ] && echo "$p" || true; }
find_bakkes(){
  local pfx="${1:-}"; [ -n "$pfx" ] || return 0
  local cand="$pfx/drive_c/Program Files/BakkesMod/BakkesMod.exe"
  LOG "Check BakkesMod: $cand"; [ -f "$cand" ] && { echo "$cand"; return 0; }
  LOG "Searching BakkesMod.exe under $pfx/drive_c…"
  find "$pfx/drive_c" -type f -iname "BakkesMod.exe" -print -quit 2>/dev/null || true
}
