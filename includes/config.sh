# rev4 config
write_config(){ LOG "Write config: $CONFIG"; cat >"$CONFIG" <<EOF2
{
  # refuse to write an invalid config
  if [ -z "${2:-}" ] || [ -z "${3:-}" ] || [ -z "${4:-}" ]; then
    ERR "Refusing to write config: missing RL_DIR/PFX_DIR/BAKKES_PATH"
  fi
APPID=$APPID
STEAM_DIR=$1
RL_DIR=$2
PFX_DIR=$3
BAKKES_PATH=$4
EOF2
LOG "CONFIG: APPID=$APPID"; LOG "CONFIG: STEAM_DIR=$1"; LOG "CONFIG: RL_DIR=$2"; LOG "CONFIG: PFX_DIR=$3"; LOG "CONFIG: BAKKES_PATH=$4"; }
load_config(){ LOG "Load config: $CONFIG"; source "$CONFIG"; LOG "Loaded APPID=${APPID:-} STEAM_DIR=${STEAM_DIR:-} RL_DIR=${RL_DIR:-} PFX_DIR=${PFX_DIR:-} BAKKES_PATH=${BAKKES_PATH:-}"; }
valid_config(){ [ "${APPID:-}" = "252950" ] && [ -d "${STEAM_DIR:-/n}" ] && [ -d "${RL_DIR:-/n}" ] && [ -d "${PFX_DIR:-/n}" ] && [ -f "${BAKKES_PATH:-/n}" ]; }
