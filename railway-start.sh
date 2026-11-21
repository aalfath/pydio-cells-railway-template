#!/bin/sh
# Railway start script for Pydio Cells.
# - Railway's edge terminates TLS, so Cells serves plain HTTP on $PORT.
# - On the first boot (no config on the volume) it runs Cells' headless install
#   with the generated admin password and the Postgres service, then starts Cells.
# - Any failure exits non-zero so Railway's ON_FAILURE restart policy applies.
set -eu

log() { echo "railway-start: $*"; }
fail() { echo "railway-start: ERROR: $*" >&2; exit 1; }

PORT="${PORT:-8080}"
export CELLS_WORKING_DIR="${CELLS_WORKING_DIR:-/var/cells}"
export CELLS_SITE_BIND="0.0.0.0:${PORT}"
export CELLS_SITE_NO_TLS="${CELLS_SITE_NO_TLS:-true}"
if [ -z "${CELLS_SITE_EXTERNAL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export CELLS_SITE_EXTERNAL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
# Logs go to stdout (Railway's log view), not to files on the volume.
export CELLS_LOG_TO_FILE="${CELLS_LOG_TO_FILE:-false}"

# Let the Go runtime collect garbage before the container's memory limit is hit
# (Railway's Free plan gives 0.5 GB per service).
if [ -z "${GOMEMLIMIT:-}" ] && [ -r /sys/fs/cgroup/memory.max ]; then
  lim="$(cat /sys/fs/cgroup/memory.max)"
  case "$lim" in
    ''|max|*[!0-9]*) ;;
    *) export GOMEMLIMIT="$((lim / 100 * 85))"; log "GOMEMLIMIT=${GOMEMLIMIT} (85% of the container limit)";;
  esac
fi

mkdir -p "$CELLS_WORKING_DIR"

if ! cells admin config check >/dev/null 2>&1; then
  log "no configuration on the volume: running the headless install"
  [ -n "${DB_HOST:-}" ] || fail "DB_HOST is empty: reference the Postgres service (\${{Postgres.PGHOST}})"
  [ -n "${DB_PASSWORD:-}" ] || fail "DB_PASSWORD is empty: reference the Postgres service (\${{Postgres.PGPASSWORD}})"
  [ -n "${CELLS_ADMIN_PASSWORD:-}" ] || fail "CELLS_ADMIN_PASSWORD is empty"
  [ "${#CELLS_ADMIN_PASSWORD}" -ge 8 ] || fail "CELLS_ADMIN_PASSWORD must be at least 8 characters"

  yq() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
  umask 077
  conf="$(mktemp /tmp/cells-install.XXXXXX)"
  trap 'rm -f "$conf"' EXIT
  {
    printf 'frontendlogin: "%s"\n' "$(yq "${CELLS_ADMIN_LOGIN:-admin}")"
    printf 'frontendpassword: "%s"\n' "$(yq "$CELLS_ADMIN_PASSWORD")"
    printf 'frontendrepeatpassword: "%s"\n' "$(yq "$CELLS_ADMIN_PASSWORD")"
    printf 'frontendapplicationtitle: "%s"\n' "$(yq "${CELLS_APPLICATION_TITLE:-Pydio Cells}")"
    printf 'dbconnectiontype: pg_tcp\n'
    printf 'dbtcphostname: "%s"\n' "$(yq "$DB_HOST")"
    printf 'dbtcpport: "%s"\n' "$(yq "${DB_PORT:-5432}")"
    printf 'dbtcpname: "%s"\n' "$(yq "${DB_NAME:-railway}")"
    printf 'dbtcpuser: "%s"\n' "$(yq "${DB_USER:-postgres}")"
    printf 'dbtcppassword: "%s"\n' "$(yq "$DB_PASSWORD")"
    printf 'dstype: FS\n'
  } > "$conf"
  umask 022
  # `cells configure` returns after a YAML install instead of starting the
  # server, so the install and the start run as two steps.
  CELLS_INSTALL_YAML="$conf" cells configure || fail "headless install failed (see the log above)"
  rm -f "$conf"; trap - EXIT
  cells admin config check >/dev/null 2>&1 || fail "install finished but no valid configuration was written"
  log "install done: sign in as '${CELLS_ADMIN_LOGIN:-admin}' with CELLS_ADMIN_PASSWORD"
fi

log "starting Cells on ${CELLS_SITE_BIND} (external ${CELLS_SITE_EXTERNAL:-not set})"
exec "$@"
