#!/bin/sh
# Start Meilisearch on Railway.
#
# Every deploy-form value is checked first. A bad value never stops the
# deploy (STANDARD 8.29): it falls back to the default with a warning. A
# missing or too short master key would make Meilisearch exit (production)
# or run without auth (development), so instead the API is locked with a
# random key nobody knows and the log says how to fix it.
set -eu

log() { echo "railway-meilisearch: $*" >&2; }

DATA=/meili_data
mkdir -p "$DATA"

# Port (Railway's healthcheck and the public domain use it).
case "${PORT:-}" in
  ''|*[!0-9]*) log "PORT='${PORT:-}' is not a number, using 7700"; PORT=7700 ;;
esac
if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  log "PORT=$PORT is out of range, using 7700"; PORT=7700
fi
# [::] is dual-stack for Meilisearch (Rust/actix): IPv4 healthcheck and
# IPv6/IPv4 private network both work.
export MEILI_HTTP_ADDR="[::]:$PORT"

# Environment: production (default) or development.
case "${MEILI_ENV:-production}" in
  production|development) export MEILI_ENV="${MEILI_ENV:-production}" ;;
  *) log "MEILI_ENV='${MEILI_ENV}' is not production/development, using production"; export MEILI_ENV=production ;;
esac

# Master key: at least 16 bytes in every mode.
key_len=$(printf '%s' "${MEILI_MASTER_KEY:-}" | wc -c | tr -d ' ')
if [ "$key_len" -lt 16 ]; then
  log "WARNING: MEILI_MASTER_KEY is missing or shorter than 16 characters ($key_len)."
  log "WARNING: the API is LOCKED with a random key nobody knows. Set MEILI_MASTER_KEY"
  log "WARNING: to at least 16 characters in the service variables and redeploy."
  MEILI_MASTER_KEY=$(head -c 48 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 40)
  export MEILI_MASTER_KEY
fi

# Data locations on the volume.
export MEILI_DB_PATH="$DATA/data.ms"
export MEILI_DUMP_DIR="$DATA/dumps"
export MEILI_SNAPSHOT_DIR="$DATA/snapshots"

# Booleans: anything but true/false falls back.
bool() { # name default
  eval "v=\${$1:-}"
  case "$v" in
    true|false) ;;
    '') eval "export $1=$2" ;;
    *) log "$1='$v' is not true/false, using $2"; eval "export $1=$2" ;;
  esac
}
bool MEILI_NO_ANALYTICS true
bool MEILI_UPGRADE_DB true

# Scheduled snapshots: empty/0 = off, else seconds between snapshots.
case "${MEILI_SCHEDULE_SNAPSHOT:-}" in
  ''|0|false) unset MEILI_SCHEDULE_SNAPSHOT ;;
  *[!0-9]*) log "MEILI_SCHEDULE_SNAPSHOT='${MEILI_SCHEDULE_SNAPSHOT}' is not a number of seconds, snapshots off"; unset MEILI_SCHEDULE_SNAPSHOT ;;
  *) mkdir -p "$MEILI_SNAPSHOT_DIR" ;;
esac

# Payload limit like 100MB / 1Gb; empty = Meilisearch default (100 MB).
case "${MEILI_HTTP_PAYLOAD_SIZE_LIMIT:-}" in
  '') unset MEILI_HTTP_PAYLOAD_SIZE_LIMIT ;;
  *)
    if ! printf '%s' "$MEILI_HTTP_PAYLOAD_SIZE_LIMIT" | grep -Eiq '^[0-9]+ ?([kmgt]i?b?|b)?$'; then
      log "MEILI_HTTP_PAYLOAD_SIZE_LIMIT='${MEILI_HTTP_PAYLOAD_SIZE_LIMIT}' is not a size like 100MB, using the default"
      unset MEILI_HTTP_PAYLOAD_SIZE_LIMIT
    fi ;;
esac

# Log level.
case "$(printf '%s' "${MEILI_LOG_LEVEL:-INFO}" | tr '[:lower:]' '[:upper:]')" in
  OFF|ERROR|WARN|INFO|DEBUG|TRACE) export MEILI_LOG_LEVEL="$(printf '%s' "${MEILI_LOG_LEVEL:-INFO}" | tr '[:lower:]' '[:upper:]')" ;;
  *) log "MEILI_LOG_LEVEL='${MEILI_LOG_LEVEL}' is not a log level, using INFO"; export MEILI_LOG_LEVEL=INFO ;;
esac

# Empty optional webhook settings would be parsed as invalid URLs.
[ -n "${MEILI_TASK_WEBHOOK_URL:-}" ] || unset MEILI_TASK_WEBHOOK_URL
[ -n "${MEILI_TASK_WEBHOOK_AUTHORIZATION_HEADER:-}" ] || unset MEILI_TASK_WEBHOOK_AUTHORIZATION_HEADER

log "starting Meilisearch ($MEILI_ENV) on $MEILI_HTTP_ADDR, data in $MEILI_DB_PATH"
cd "$DATA"
exec /bin/meilisearch
