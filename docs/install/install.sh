#!/usr/bin/env sh
# Clovance installer (Linux/macOS)
#
# Usage:
#   ./install.sh            (install)
#   ./install.sh install
#   ./install.sh uninstall
#   ./install.sh update
#
# Written in POSIX sh on purpose: the documented one-liners pipe this file into
# "sh", which is dash on Debian/Ubuntu, ash on Alpine and bash elsewhere.
set -eu

PAGES_BASE="https://evaristocuesta.github.io/clovance"

DEFAULT_INSTALL_DIR="$HOME/clovance"
DEFAULT_VERSION="latest"
DEFAULT_FRONTEND_PORT="7000"
DEFAULT_API_PORT="8080"
DEFAULT_BIND="0.0.0.0"
DEFAULT_DASHBOARD_BIND="127.0.0.1"

# ---------- helpers ----------
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
err() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; }
is_nonblank() {
  case "$1" in *[![:space:]]*) return 0 ;; *) return 1 ;; esac
}

# True when we can ask the user something. When this file is piped into a
# shell, stdin is the script itself, so we read from /dev/tty instead.
can_prompt() {
  if [ -t 0 ]; then return 0; fi
  ( : </dev/tty ) 2>/dev/null
}

read_line() {
  # read_line <varname>
  if [ -t 0 ]; then
    IFS= read -r "$1"
  else
    IFS= read -r "$1" </dev/tty
  fi
}

prompt() {
  # prompt <default> <message>  -> sets REPLY
  _def="$1"
  _msg="$2"
  if can_prompt; then
    printf '%s [%s]: ' "$_msg" "$_def"
    read_line REPLY || REPLY=""
    [ -n "$REPLY" ] || REPLY="$_def"
  else
    REPLY="$_def"
  fi
}

prompt_yes_no() {
  # prompt_yes_no <default: Y|N> <message> -> sets REPLY to Y or N
  _default="$1"
  _msg="$2"
  if ! can_prompt; then
    REPLY="$_default"
    return 0
  fi
  while :; do
    if [ "$_default" = "Y" ]; then
      printf '%s [Y/n]: ' "$_msg"
    else
      printf '%s [y/N]: ' "$_msg"
    fi
    read_line REPLY || REPLY=""
    REPLY="${REPLY:-$_default}"
    case "$REPLY" in
      y|Y|yes|YES|Yes) REPLY="Y"; return 0 ;;
      n|N|no|NO|No) REPLY="N"; return 0 ;;
      *) warn "Please answer yes or no." ;;
    esac
  done
}

prompt_required() {
  # prompt_required <default> <message> -> sets non-empty REPLY
  _def="$1"
  _msg="$2"
  while :; do
    if can_prompt; then
      if [ -n "$_def" ]; then
        printf '%s [%s]: ' "$_msg" "$_def"
      else
        printf '%s: ' "$_msg"
      fi
      read_line REPLY || REPLY=""
      REPLY="${REPLY:-$_def}"
    else
      REPLY="$_def"
    fi
    is_nonblank "$REPLY" && return 0
    err "$_msg is required when SMTP is enabled."
    if ! can_prompt; then exit 1; fi
  done
}

prompt_secret() {
  # prompt_secret <message>  -> sets REPLY (empty when there is no terminal)
  if ! can_prompt; then
    REPLY=""
    return 0
  fi
  printf '%s: ' "$1"
  if [ -t 0 ]; then
    stty -echo 2>/dev/null || true
  else
    stty -echo </dev/tty 2>/dev/null || true
  fi
  read_line REPLY || REPLY=""
  if [ -t 0 ]; then
    stty echo 2>/dev/null || true
  else
    stty echo </dev/tty 2>/dev/null || true
  fi
  printf '\n'
}

prompt_secret_required() {
  # prompt_secret_required <message> <existing> -> sets non-empty REPLY
  _msg="$1"
  _existing="$2"
  while :; do
    if [ -n "$_existing" ]; then
      prompt_secret "$_msg (empty = keep current)"
      REPLY="${REPLY:-$_existing}"
    else
      prompt_secret "$_msg"
    fi
    is_nonblank "$REPLY" && return 0
    err "$_msg is required when SMTP is enabled."
    if ! can_prompt; then exit 1; fi
  done
}

is_yes() {
  case "$1" in
    y|Y|yes|YES|Yes) return 0 ;;
    *) return 1 ;;
  esac
}

gen_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 18 | tr -d '\n' | tr '/+' '_-'
  elif [ -r /dev/urandom ]; then
    head -c 24 /dev/urandom | base64 | tr -d '\n' | tr '/+' '_-'
  fi
}

require() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }
}

check_docker() {
  require docker
  docker info >/dev/null 2>&1 || { err "Docker daemon is not running. Start Docker and retry."; exit 1; }
  docker compose version >/dev/null 2>&1 || { err "Docker Compose plugin (v2) is required."; exit 1; }
}

compose_file() { printf '%s/docker-compose.yml' "$INSTALL_DIR"; }
env_file() { printf '%s/.env' "$INSTALL_DIR"; }

env_get() {
  # env_get <key>  -> current value from .env (empty when missing)
  [ -f "$(env_file)" ] || return 0
  sed -n "s/^$1=//p" "$(env_file)" | head -n 1
}

has_data() {
  # has_data <dir>
  [ -d "$1" ] && [ -n "$(ls -A "$1" 2>/dev/null || true)" ]
}

assert_compose_running() {
  # A container that crashes right after "up -d" shows up as "restarting", not
  # running, so wait a bit for the stack to settle before declaring success.
  # The state is "State/Health": a service with a healthcheck reports "running"
  # while its check has not passed yet, so "running" alone is not enough.
  _timeout="${CLOVANCE_VERIFY_TIMEOUT:-300}"
  _i=0
  while [ "$_i" -lt "$_timeout" ]; do
    _states="$(docker compose ps -a --format '{{.State}}/{{.Health}}' 2>/dev/null || true)"
    _ready=0
    _broken=0
    for _s in $_states; do
      case "$_s" in
        running/|running/healthy) _ready=$((_ready + 1)) ;;
        *) _broken=$((_broken + 1)) ;;
      esac
    done
    if [ "$_ready" -ge 2 ] && [ "$_broken" -eq 0 ]; then return 0; fi
    _i=$((_i + 1))
    sleep 1
  done
  err "Clovance did not start correctly ($_ready container(s) ready, $_broken not ready)."
  err "Check 'docker compose ps' and 'docker compose logs' in $INSTALL_DIR."
  exit 1
}

ensure_jwt_writable() {
  # The API image runs as the unprivileged "app" user (uid 1654) and writes its
  # JWT signing key to /home/app (the "jwt" bind mount). On Linux and WSL the
  # bind mount keeps the host ownership, so a directory created by the
  # installing user is not writable by the container and the API crash-loops
  # with "Access to the path '/home/app/jwt.key' is denied". Docker Desktop on
  # Windows/macOS ignores ownership, which is why this only bites on Linux.
  case "$(uname -s)" in
    Linux*) ;;
    *) return 0 ;;
  esac
  _dir="$VOLUME_PATH/jwt"
  [ -d "$_dir" ] || return 0
  if [ "$(id -u)" = "0" ]; then
    chown -R 1654:1654 "$_dir" 2>/dev/null || chmod 0777 "$_dir" 2>/dev/null || true
  else
    chmod 0777 "$_dir" 2>/dev/null || true
  fi
}

write_compose() {
  _target="$(compose_file)"
  _tmp="${_target}.tmp"
  _template=""

  # For a local checkout, copy the canonical template next to this installer.
  # The published one-liner is piped into the shell, so in that case download
  # the same file from GitHub Pages.
  case "$0" in
    */*)
      _candidate="${0%/*}/docker-compose.yml"
      if [ -f "$_candidate" ]; then _template="$_candidate"; fi
      ;;
  esac

  if [ -n "$_template" ]; then
    cp "$_template" "$_tmp"
  elif ! curl -fsSL "$PAGES_BASE/install/docker-compose.yml" -o "$_tmp"; then
    rm -f "$_tmp"
    err "Unable to download the canonical Docker Compose file. Check your internet connection and try again."
    exit 1
  fi

  mv "$_tmp" "$_target"
}

do_install() {
  check_docker
  prompt "$DEFAULT_INSTALL_DIR" "Install directory"
  INSTALL_DIR="$REPLY"

  # Reuse the current configuration as prompt defaults so re-running the
  # installer does not silently change the database password or lose settings.
  _existing_version="$(env_get CLOVANCE_APISERVICE_IMAGE)"
  _existing_version="${_existing_version##*:}"
  _existing_api_port="$(env_get CLOVANCE_APISERVICE_PORT)"
  _existing_bind="$(env_get CLOVANCE_BIND_ADDRESS)"
  _existing_dashboard_bind="$(env_get CLOVANCE_DASHBOARD_BIND_ADDRESS)"
  _existing_pg_user="$(env_get POSTGRES_USERNAME)"
  _existing_pg_pass="$(env_get POSTGRES_PASSWORD)"
  _existing_smtp_host="$(env_get SMTP_HOST)"
  _existing_smtp_port="$(env_get SMTP_PORT)"
  _existing_smtp_user="$(env_get SMTP_USERNAME)"
  _existing_smtp_pass="$(env_get SMTP_PASSWORD)"
  _existing_smtp_from="$(env_get SMTP_FROM_ADDRESS)"
  _existing_smtp_name="$(env_get SMTP_FROM_NAME)"
  _existing_frontend_url="$(env_get FRONTEND_BASE_URL)"

  VOLUME_PATH="$INSTALL_DIR/data"
  if has_data "$VOLUME_PATH/postgres"; then
    warn "Existing database found in $VOLUME_PATH/postgres."
    warn "Keeping the current PostgreSQL password so the API can still connect."
    warn "POSTGRES_PASSWORD is only used when the database is created."
  fi

  prompt "${_existing_version:-$DEFAULT_VERSION}" "Image version tag (e.g. latest, 1.0.0)"
  VERSION="$REPLY"
  prompt "$DEFAULT_FRONTEND_PORT" "Frontend host port"
  FRONTEND_PORT="$REPLY"
  prompt "${_existing_api_port:-$DEFAULT_API_PORT}" "API container port"
  API_PORT="$REPLY"
  prompt "${_existing_bind:-$DEFAULT_BIND}" "Bind address for frontend"
  BIND="$REPLY"
  prompt "${_existing_dashboard_bind:-$DEFAULT_DASHBOARD_BIND}" "Bind address for Aspire dashboard"
  DASHBOARD_BIND="$REPLY"
  prompt "${_existing_pg_user:-clovance}" "PostgreSQL username"
  PG_USER="$REPLY"
  if [ -n "$_existing_pg_pass" ]; then
    prompt_secret "PostgreSQL password (empty = keep current)"
  else
    prompt_secret "PostgreSQL password (empty = auto-generate)"
  fi
  PG_PASS="${REPLY:-$_existing_pg_pass}"
  if [ -z "$PG_PASS" ]; then
    PG_PASS="$(gen_password)"
    [ -n "$PG_PASS" ] || { err "Could not generate a PostgreSQL password."; exit 1; }
    log "Generated PostgreSQL password."
  fi
  _smtp_existing_any=0
  for _smtp_value in "$_existing_smtp_host" "$_existing_smtp_user" "$_existing_smtp_pass" "$_existing_smtp_from"; do
    if [ -n "$_smtp_value" ]; then _smtp_existing_any=1; fi
  done
  _smtp_existing_complete=0
  if [ -n "$_existing_smtp_host" ] && [ -n "$_existing_smtp_user" ] \
      && [ -n "$_existing_smtp_pass" ] && [ -n "$_existing_smtp_from" ]; then
    _smtp_existing_complete=1
  elif [ "$_smtp_existing_any" -eq 1 ]; then
    warn "Existing SMTP settings are incomplete. Choose Yes to complete them or No to disable SMTP."
  fi

  _smtp_default="N"
  if [ "$_smtp_existing_complete" -eq 1 ]; then _smtp_default="Y"; fi
  prompt_yes_no "$_smtp_default" "Configure SMTP? Without it, invitations and password reset emails cannot be sent."
  if is_yes "$REPLY"; then
    prompt_required "$_existing_smtp_host" "SMTP host"
    SMTP_HOST="$REPLY"
    prompt_required "${_existing_smtp_port:-587}" "SMTP port"
    SMTP_PORT="$REPLY"
    prompt_required "$_existing_smtp_user" "SMTP username"
    SMTP_USER="$REPLY"
    prompt_secret_required "SMTP password" "$_existing_smtp_pass"
    SMTP_PASS="$REPLY"
    prompt_required "$_existing_smtp_from" "SMTP from address"
    SMTP_FROM="$REPLY"
    prompt "${_existing_smtp_name:-Clovance}" "SMTP from name"
    SMTP_FROM_NAME="$REPLY"
  else
    SMTP_HOST=""
    SMTP_USER=""
    SMTP_PASS=""
    SMTP_FROM=""
    SMTP_PORT="${_existing_smtp_port:-587}"
    SMTP_FROM_NAME="${_existing_smtp_name:-Clovance}"
    log "SMTP is not configured; invitations and password reset emails cannot be sent."
  fi
  prompt "${_existing_frontend_url:-http://localhost:${FRONTEND_PORT}}" "Frontend base URL"
  FRONTEND_URL="$REPLY"

  mkdir -p "$INSTALL_DIR"
  mkdir -p "$VOLUME_PATH/postgres" "$VOLUME_PATH/jwt"
  ensure_jwt_writable

  API_IMAGE="ghcr.io/evaristocuesta/clovance/clovance-api:${VERSION}"
  FE_IMAGE="ghcr.io/evaristocuesta/clovance/clovance-frontend:${VERSION}"

  cat > "$(env_file)" <<EOF
CLOVANCE_APISERVICE_IMAGE=${API_IMAGE}
CLOVANCE_APISERVICE_PORT=${API_PORT}
CLOVANCE_FRONTEND_IMAGE=${FE_IMAGE}
FRONTEND_BASE_URL=${FRONTEND_URL}
POSTGRES_PASSWORD=${PG_PASS}
POSTGRES_USERNAME=${PG_USER}
SMTP_FROM_ADDRESS=${SMTP_FROM}
SMTP_FROM_NAME=${SMTP_FROM_NAME}
SMTP_HOST=${SMTP_HOST}
SMTP_PASSWORD=${SMTP_PASS}
SMTP_PORT=${SMTP_PORT}
SMTP_USERNAME=${SMTP_USER}
VOLUME_SOURCE_PATH=${VOLUME_PATH}
CLOVANCE_BIND_ADDRESS=${BIND}
CLOVANCE_DASHBOARD_BIND_ADDRESS=${DASHBOARD_BIND}
EOF

  write_compose
  log "Configuration written to $INSTALL_DIR"

  cd "$INSTALL_DIR"
  log "Pulling images..."
  docker compose pull
  log "Starting Clovance..."
  docker compose up -d
  log "Verifying containers..."
  assert_compose_running

  echo
  log "Clovance is running!"
  echo "   Frontend:  http://localhost:${FRONTEND_PORT}"
  echo "   Data dir:  ${VOLUME_PATH}"
  echo
  echo "   Aspire dashboard token:"
  echo "     docker logs \$(docker compose ps -q env-dashboard) 2>&1 | grep -i token"
  echo
  echo "   Stop:    cd $INSTALL_DIR && docker compose down"
  echo "   Update:  curl -fsSL $PAGES_BASE/install/update.sh | sh"
}

do_uninstall() {
  check_docker
  prompt "$DEFAULT_INSTALL_DIR" "Install directory"
  INSTALL_DIR="$REPLY"
  if [ ! -f "$(compose_file)" ]; then
    err "No docker-compose.yml found in $INSTALL_DIR. Nothing to stop there."
    exit 1
  fi
  cd "$INSTALL_DIR"
  log "Stopping containers..."
  docker compose down || { err "Could not stop the containers. Nothing was deleted."; exit 1; }

  if can_prompt; then
    printf 'Remove data volumes (postgres + jwt)? [y/N]: '
    read_line REPLY || REPLY=""
  else
    REPLY="N"
  fi
  if is_yes "${REPLY:-N}"; then
    if rm -rf "$INSTALL_DIR/data" 2>/dev/null && [ ! -d "$INSTALL_DIR/data" ]; then
      log "Data removed."
    elif command -v sudo >/dev/null 2>&1 && sudo rm -rf "$INSTALL_DIR/data" 2>/dev/null && [ ! -d "$INSTALL_DIR/data" ]; then
      log "Data removed (with sudo)."
    else
      warn "Could not remove $INSTALL_DIR/data."
      warn "Run manually: sudo rm -rf $INSTALL_DIR/data"
    fi
  fi

  if can_prompt; then
    printf 'Remove generated config files (.env, docker-compose.yml)? [y/N]: '
    read_line REPLY || REPLY=""
  else
    REPLY="N"
  fi
  if is_yes "${REPLY:-N}"; then
    rm -f "$INSTALL_DIR/.env" "$INSTALL_DIR/docker-compose.yml"
    log "Config removed."
  fi

  log "Uninstall complete."
  echo "   Docker images are kept. To delete them:"
  echo "     docker image rm ghcr.io/evaristocuesta/clovance/clovance-api:latest ghcr.io/evaristocuesta/clovance/clovance-frontend:latest"
}

do_update() {
  check_docker
  prompt "$DEFAULT_INSTALL_DIR" "Install directory"
  INSTALL_DIR="$REPLY"
  if [ ! -f "$(env_file)" ]; then
    err "No .env found in $INSTALL_DIR."
    exit 1
  fi
  prompt "$DEFAULT_VERSION" "New image version tag"
  VERSION="$REPLY"

  cp "$(env_file)" "$(env_file).bak"
  _tmp="$(env_file).tmp"
  sed -e "s|^CLOVANCE_APISERVICE_IMAGE=.*|CLOVANCE_APISERVICE_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-api:${VERSION}|" \
      -e "s|^CLOVANCE_FRONTEND_IMAGE=.*|CLOVANCE_FRONTEND_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-frontend:${VERSION}|" \
      "$(env_file)" > "$_tmp"
  mv "$_tmp" "$(env_file)"

  # The compose file is generated by the installer, so refresh it: fixes to the
  # generated services (healthchecks, ordering) must reach existing installs.
  write_compose

  cd "$INSTALL_DIR"
  if ! docker compose pull; then
    err "Failed to pull the new images. The previous configuration is in $(env_file).bak."
    exit 1
  fi
  if ! docker compose up -d; then
    err "Failed to recreate the containers. The previous configuration is in $(env_file).bak."
    exit 1
  fi
  log "Verifying containers..."
  assert_compose_running
  log "Update complete."
}

CMD="${1:-install}"
case "$CMD" in
  install) do_install ;;
  uninstall) do_uninstall ;;
  update) do_update ;;
  *)
    echo "Usage: $0 [install|uninstall|update]"
    exit 1
    ;;
esac
