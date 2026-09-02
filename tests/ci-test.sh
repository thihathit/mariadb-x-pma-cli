#!/usr/bin/env bash
# CI test for bin/mariadb-x-pma. Runs against real MariaDB + phpMyAdmin
# provisioned by the GitHub Actions workflow. Self-contained, no secrets.
set -euo pipefail

cd "$(dirname "$0")/.."
CLI="$(pwd)/bin/mariadb-x-pma"
[ -x "$CLI" ] || chmod +x "$CLI"

export PMA_DOCROOT="${PMA_DOCROOT:-/opt/phpmyadmin}"
export PMA_PHP="${PMA_PHP:-php}"
export PMA_STATE="/tmp/ci-pma-port.flag"
export PMA_BIND="127.0.0.1"

PASS=0
FAIL=0

check() {
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- phpMyAdmin lifecycle ---"
$CLI pma stop >/dev/null 2>&1 || true
check "pma status says not running before start" bash -c "! $CLI pma status | grep -q 'RUNNING on'"

$CLI pma start
sleep 1
PORT="$(cat "$PMA_STATE")"
check "pma writes a port flag ($PORT)" test -f "$PMA_STATE"
check "pma serves HTTP on port $PORT" curl -fsS -o /dev/null "http://127.0.0.1:${PORT}/index.php"
check "pma status reports RUNNING" bash -c "$CLI pma status | grep -q 'RUNNING on'"

$CLI pma restart
sleep 1
check "pma still up after restart" curl -fsS -o /dev/null "http://127.0.0.1:$(cat "$PMA_STATE")/index.php"

$CLI pma stop
check "pma status says not running after stop" bash -c "! $CLI pma status | grep -q 'RUNNING on'"

echo "--- MariaDB server detection ---"
export MARIADB_STATUS_CMD="mariadb -N -e 'SELECT VERSION();'"
check "mariadb status detects live server" bash -c "$CLI mariadb status | grep -qi running"

echo "--- MariaDB command wiring (start uses 'run', never 'start') ---"
CMDS_LOG="$(mktemp)"
export MARIADB_START_CMD="printf 'brew services run mariadb\\n' >> $CMDS_LOG"
export MARIADB_STOP_CMD="printf 'brew services stop mariadb\\n' >> $CMDS_LOG"
$CLI mariadb start
$CLI mariadb stop
check "mariadb start invokes brew services run (not start)" bash -c "grep -qx 'brew services run mariadb' $CMDS_LOG"
check "mariadb stop invokes brew services stop" bash -c "grep -qx 'brew services stop mariadb' $CMDS_LOG"
check "mariadb start never enables auto-start" bash -c "! grep -q 'brew services start' $CMDS_LOG"

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]