#!/bin/bash
# Keeps the public demo link for Campus Green Mobility alive with no manual
# intervention. Runs at login and every 5 minutes via a LaunchAgent.
#
# Why a watchdog and not just launchd's own KeepAlive: a stale trycloudflare.com
# quick tunnel doesn't crash -- Cloudflare's edge invalidates it server-side and
# cloudflared just retries "Unauthorized: Tunnel not found" forever without
# ever exiting. launchd only restarts a process that actually exits, so it
# can't detect or fix this on its own; this script has to actively probe the
# tunnel and kill+restart it when it's stuck.
set -uo pipefail

APP_DIR="/Users/sid/Claude/pbl6-green-mobility"
SCRIPTS_DIR="$APP_DIR/scripts"
URL_FILE="$APP_DIR/TUNNEL_URL.txt"
CF_LOG="$SCRIPTS_DIR/cloudflared.log"
WATCHDOG_LOG="$SCRIPTS_DIR/tunnel-watchdog.log"
LOCAL_LOGIN_URL="http://localhost:8080/green-mobility/login.jsp"
TUNNEL_PATTERN="cloudflared tunnel --url http://localhost:8080"

CLOUDFLARED="/opt/homebrew/bin/cloudflared"
BREW="/opt/homebrew/bin/brew"
CURL="/usr/bin/curl"
PGREP="/usr/bin/pgrep"
PKILL="/usr/bin/pkill"
GREP="/usr/bin/grep"
TAIL="/usr/bin/tail"

mkdir -p "$SCRIPTS_DIR"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$WATCHDOG_LOG"; }

# Keep the log from growing forever across weeks of 5-minute runs.
if [ -f "$WATCHDOG_LOG" ]; then
    "$TAIL" -n 300 "$WATCHDOG_LOG" > "$WATCHDOG_LOG.tmp" 2>/dev/null && mv "$WATCHDOG_LOG.tmp" "$WATCHDOG_LOG"
fi

# Tomcat is already a `brew services` LaunchAgent (auto-starts on login), but
# this is a free extra check in case it ever crashes between logins.
if ! "$CURL" -s -o /dev/null -m 5 "$LOCAL_LOGIN_URL"; then
    log "Tomcat not responding locally -- restarting via brew services"
    "$BREW" services restart tomcat >> "$WATCHDOG_LOG" 2>&1
    sleep 12
fi

needs_restart=false

if ! "$PGREP" -f "$TUNNEL_PATTERN" > /dev/null; then
    log "cloudflared is not running"
    needs_restart=true
elif [ -f "$URL_FILE" ]; then
    CURRENT_URL=$(cat "$URL_FILE")
    if [ -z "$CURRENT_URL" ] || ! "$CURL" -s -o /dev/null -m 8 "${CURRENT_URL}/green-mobility/login.jsp"; then
        log "current tunnel URL unreachable: ${CURRENT_URL:-<empty>}"
        needs_restart=true
    fi
else
    log "no URL file yet"
    needs_restart=true
fi

if [ "$needs_restart" = true ]; then
    log "restarting cloudflared tunnel"
    "$PKILL" -f "$TUNNEL_PATTERN" 2>/dev/null
    sleep 2
    nohup "$CLOUDFLARED" tunnel --url http://localhost:8080 > "$CF_LOG" 2>&1 &
    disown

    new_url=""
    for i in $(seq 1 15); do
        sleep 2
        new_url=$("$GREP" -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" "$CF_LOG" 2>/dev/null | head -1)
        if [ -n "$new_url" ]; then
            echo "$new_url" > "$URL_FILE"
            log "new tunnel URL: $new_url"
            break
        fi
    done

    if [ -z "$new_url" ]; then
        log "failed to obtain a new tunnel URL after 30s"
    fi
fi
