# rev4 defaults + CLI flags + log init
: "${APPID:=252950}"
: "${BASE_DIR:=$HOME/RocketLeague/scripts}"
: "${CONFIG:=$BASE_DIR/.rlbakkes.cfg}"
: "${LOG_DIR:=$BASE_DIR/logs}"
: "${BAKKES_URL:=https://bakkesmod.com/download.php}"
: "${BAKKES_INSTALLER:=$BASE_DIR/BakkesModSetup.exe}"
: "${WAIT_SECS:=90}"
: "${PRIORITY_STEAM_PATHS:=~/.steam/steam:~/.local/share/Steam}"

DEBUG=0; FORCE=0; NO_INJECT=0
for a in "${@:-}"; do
  case "$a" in
    --debug) DEBUG=1 ;;
    --force-rediscover) FORCE=1 ;;
    --no-inject) NO_INJECT=1 ;;
    *) echo "Unknown flag: $a" >&2; exit 64 ;;
  esac
done

mkdir -p "$BASE_DIR" "$LOG_DIR"
TS="$(date '+%Y%m%d.%H%S')"
LOG_FILE="$LOG_DIR/rl_bakkes_${TS}.log"
exec > >(tee -a "$LOG_FILE") 2> >(tee -a "$LOG_FILE" >exec > >(tee -a "$LOG_FILE") 2>&12)
LOG "===== RL + BakkesMod launcher (rev5 modular) ====="
LOG "Config: $CONFIG"
LOG "Logs:   $LOG_FILE"
LOG "Flags:  debug=$DEBUG force_rediscover=$FORCE no_inject=$NO_INJECT"
