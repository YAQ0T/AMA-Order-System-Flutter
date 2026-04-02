#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$PROJECT_DIR/.ama_runtime"
SERVER_DIR="$PROJECT_DIR/AMA-Order-System/server"
API_BASE_URL="http://213.6.226.163:6001"
WEB_PORT="6173"

mkdir -p "$RUNTIME_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

is_running() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

resolve_flutter_bin() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return 0
  fi

  if [ -x "/Users/yaqot/Documents/Applications/Dikori-Flutter/flutter/bin/flutter" ]; then
    echo "/Users/yaqot/Documents/Applications/Dikori-Flutter/flutter/bin/flutter"
    return 0
  fi

  if [ -x "$HOME/flutter/bin/flutter" ]; then
    echo "$HOME/flutter/bin/flutter"
    return 0
  fi

  return 1
}

start_python_server() {
  local pid_file="$RUNTIME_DIR/web.pid"
  local log_file="$RUNTIME_DIR/web.log"

  if [ -f "$pid_file" ]; then
    local old_pid
    old_pid="$(cat "$pid_file")"
    if is_running "$old_pid"; then
      log "Web server already running with PID $old_pid on port $WEB_PORT."
      return 0
    fi
    rm -f "$pid_file"
  fi

  nohup python3 -m http.server "$WEB_PORT" --directory "$PROJECT_DIR/build/web" --bind 0.0.0.0 >"$log_file" 2>&1 &
  local pid=$!
  sleep 1

  if is_running "$pid"; then
    echo "$pid" >"$pid_file"
    log "Web server started on port $WEB_PORT (PID $pid)."
  else
    log "Failed to start web server on port $WEB_PORT. Check $log_file."
    exit 1
  fi
}

start_node_server() {
  local pid_file="$RUNTIME_DIR/server.pid"
  local log_file="$RUNTIME_DIR/server.log"

  if [ -f "$pid_file" ]; then
    local old_pid
    old_pid="$(cat "$pid_file")"
    if is_running "$old_pid"; then
      log "Node server already running with PID $old_pid."
      return 0
    fi
    rm -f "$pid_file"
  fi

  if [ ! -d "$SERVER_DIR" ]; then
    log "Server directory not found: $SERVER_DIR"
    exit 1
  fi

  nohup npm run dev --prefix "$SERVER_DIR" >"$log_file" 2>&1 &
  local pid=$!
  sleep 2

  if is_running "$pid"; then
    echo "$pid" >"$pid_file"
    log "Node dev server started (PID $pid)."
  else
    log "Failed to start Node dev server. Check $log_file."
    exit 1
  fi
}

main() {
  cd "$PROJECT_DIR"

  local flutter_bin
  if ! flutter_bin="$(resolve_flutter_bin)"; then
    log "Flutter executable not found. Update start_ama.command with your Flutter path."
    exit 1
  fi

  log "Using Flutter: $flutter_bin"
  log "Building web app with API_BASE_URL=$API_BASE_URL ..."

  "$flutter_bin" build web --dart-define="API_BASE_URL=$API_BASE_URL" 2>&1 | tee "$RUNTIME_DIR/build.log"

  log "Build complete. Starting services..."
  start_python_server
  start_node_server

  log "All services started."
  log "Web app: http://localhost:$WEB_PORT"
  log "Runtime logs: $RUNTIME_DIR"
}

main "$@"
