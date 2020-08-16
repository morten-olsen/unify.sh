USAGE="
  $SCRIPT_NAME <command>

  Commands:
  * setup_fs:
  * teardown:
  * list_unions:
  * flush_cache:
  * get_write:
  * set_write <INDEX>:
  * raid <COMMAND> [OPTIONS]:
"

BASE_DIR="$PWD/data"
UNION_DIR="$BASE_DIR/unify"
TARGET_DIR="$BASE_DIR/joined"
PARITY_DIR="$BASE_DIR/parity"
PARITY_CONTENT="$BASE_DIR/parity_content"
CACHE_DIR="$BASE_DIR/cache"
CACHE_WRITE_TARGET="$BASE_DIR/cache-write"
WRITE_TARGET="$BASE_DIR/write"

COMMAND="$1"; shift
UNION_DIRS=("$UNION_DIR"/*/)

function join_by {
  local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}";
}

function get_snapraid_config {
  LOCATION=$(mktemp)
  CONFIG="parity $PARITY_DIR
content $PARITY_CONTENT" 
  for ((i=0; i<${#UNION_DIRS[@]}; i++));
  do
    DIR="${UNION_DIRS[$i]}"
    CONFIG="$CONFIG
content $DIR./snapraid
data d$i $DIR"
  done

  echo "$CONFIG" > "$LOCATION"
  echo "$LOCATION"
}

function raid {
  mkdir -p "$PARITY_CONTENT"
  COMMAND=$1; shift
  snapraid $COMMAND -c "$(get_snapraid_config)" $@
}

function teardown {
  mount | grep "$TARGET_DIR" > /dev/null && umount "$TARGET_DIR"
  rm -rf "$TARGET_DIR" 

  [ -L "$WRITE_TARGET" ] && rm "$WRITE_TARGET"
}

function setup_fs {
  teardown
  mkdir -p "$TARGET_DIR"
  ln -s "${UNION_DIRS[0]}" "$WRITE_TARGET"

  if [ ! -d "$CACHE_DIR" ]; then
    CACHE_TARGET="$WRITE_TARGET"
  else
    CACHE_TARGET="$CACHE_DIR"
  fi

  for ((i=0; i<${#UNION_DIRS[@]}; i++));
  do
    DIRS[$i]="${UNION_DIRS[$i]}=rw"
  done
  DIR_ARG=$(join_by : ${DIRS[@]})

  mount -t unionfs -o dirs="$CACHE_TARGET=rw:$DIR_ARG" none "$TARGET_DIR"
}

function set_write {
  INDEX="$1"
  ln -sfn "${UNION_DIRS[$INDEX]}" "$WRITE_TARGET"
}

function list_unions {
  for ((i=0; i<${#UNION_DIRS[@]}; i++));
  do
    DIR="${UNION_DIRS[$i]}"
    INFO=$(df -Th "$DIR" | tail -1)
    echo "$i: $DIR
  $INFO
  "
  done
  if [ -d "$CACHE_DIR" ]; then
    INFO=$(df -Th "$CACHE_DIR" | tail -1)
    echo "cache: $CACHE_DIR
  $INFO
  "
  fi
}

function flush_cache {
  [ -d "$CACHE_DIR" ] && mv "$CACHE_DIR"/* "$WRITE_TARGET"
}

case "$COMMAND" in
  "setup_fs") setup_fs;;
  "teardown") teardown;;
  "get_write") get_write;;
  "set_write") set_write $@;;
  "list_unions") list_unions;;
  "flush_cache") flush_cache;;
  "raid") raid $@;;
esac
#setup_fs
