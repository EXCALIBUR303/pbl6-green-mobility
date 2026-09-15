#!/bin/bash
# Keeps the permanent public demo link for Campus Green Mobility alive.
# Runs at login and every 5 minutes via a LaunchAgent.
#
# Unlike the old trycloudflare.com quick tunnel, this domain
# (familyish-trochal-galina.ngrok-free.dev) is a free static domain tied to
# Sid's ngrok account -- it never changes. So this watchdog only has one job:
# make sure the ngrok process is actually up, and restart it if not.
set -uo pipefail

APP_DIR="/Users/sid/Claude/pbl6-green-mobility"
SCRIPTS_DIR="$APP_DIR/scripts"
LOG="$SCRIPTS_DIR/ngrok.log"
WATCHDOG_LOG="$SCRIPTS_DIR/ngrok-watchdog.log"
DOMAIN="familyish-trochal-galina.ngrok-free.dev"
PROCESS_PATTERN="ngrok http 8080 --url https://$DOMAIN"
LOCAL_LOGIN_URL="http://localhost:8080/green-mobility/login.jsp"

NGROK="/opt/homebrew/bin/ngrok"
BREW="/opt/homebrew/bin/brew"
CURL="/usr/bin/curl"
PGREP="/usr/bin/pgrep"
TAIL="/usr/bin/tail"

mkdir -p "$SCRIPTS_DIR"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$WATCHDOG_LOG"; }

if [ -f "$WATCHDOG_LOG" ]; then
    "$TAIL" -n 300 "$WATCHDOG_LOG" > "$WATCHDOG_LOG.tmp" 2>/dev/null && mv "$WATCHDOG_LOG.tmp" "$WATCHDOG_LOG"
fi

# Tomcat is already a `brew services` LaunchAgent, but this is a free extra
# check in case it ever crashes between logins.
if ! "$CURL" -s -o /dev/null -m 5 "$LOCAL_LOGIN_URL"; then
    log "Tomcat not responding locally -- restarting via brew services"
    "$BREW" services restart tomcat >> "$WATCHDOG_LOG" 2>&1
    sleep 12
fi

if ! "$PGREP" -f "$PROCESS_PATTERN" > /dev/null; then
    log "ngrok is not running -- starting it"
    nohup "$NGROK" http 8080 --url "https://$DOMAIN" --log=stdout > "$LOG" 2>&1 &
    disown
    sleep 6
    if "$PGREP" -f "$PROCESS_PATTERN" > /dev/null; then
        log "ngrok started successfully"
    else
        log "ngrok failed to start -- check $LOG"
    fi
fi
