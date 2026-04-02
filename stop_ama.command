#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$PROJECT_DIR/.ama_runtime"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

is_running() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

stop_pid_file() {
  local name="$1"
  local pid_file="$2"

  if [ ! -f "$pid_file" ]; then
    log "No PID file for $name."
    return 0
  fi

  local pid
  pid="$(cat "$pid_file")"

  if ! is_running "$pid"; then
    log "$name PID file exists, but process $pid is not running."
    rm -f "$pid_file"
    return 0
  fi

  kill "$pid" 2>/dev/null || true

  local i
  for i in 1 2 3 4 5; do
    if ! is_running "$pid"; then
      break
    fi
    sleep 1
  done

  if is_running "$pid"; then
    kill -9 "$pid" 2>/dev/null || true
  fi

  rm -f "$pid_file"
  log "Stopped $name (PID $pid)."
}

stop_port_fallback() {
  local name="$1"
  local port="$2"
  local expected="$3"

  local pids
  pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"

  if [ -z "$pids" ]; then
    return 0
  fi

  for pid in $pids; do
    local comm
    comm="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
    if [[ "$comm" == *"$expected"* ]]; then
      kill "$pid" 2>/dev/null || true
      log "Stopped $name by port fallback (PID $pid on port $port)."
    fi
  done
}

main() {
  stop_pid_file "web server" "$RUNTIME_DIR/web.pid"
  stop_pid_file "node server" "$RUNTIME_DIR/server.pid"

  # Fallback to close likely leftover processes if PID files are missing.
  stop_port_fallback "web server" "6173" "Python"
  stop_port_fallback "web server" "6173" "python"
  stop_port_fallback "node server" "6001" "node"

  log "Stop command finished."
}

main "$@"
