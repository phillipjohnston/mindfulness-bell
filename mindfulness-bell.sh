#!/bin/bash

# Mindfulness Bell Script
# Plays a bell sound at regular intervals

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration file
CONFIG_FILE="${SCRIPT_DIR}/.bell-config"
PAUSE_FILE="${SCRIPT_DIR}/.bell-paused"
LOG_FILE="${SCRIPT_DIR}/bell.log"

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    # Set defaults if not configured
    INTERVAL=${INTERVAL:-1200}  # Default: 20 minutes (1200 seconds)
    AUDIO_FILE=${AUDIO_FILE:-"${SCRIPT_DIR}/audio/medium_bell_wake_plus_full.mp3"}
}

# Log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if bell is paused
is_paused() {
    if [ -f "$PAUSE_FILE" ]; then
        # Read pause until timestamp
        PAUSE_UNTIL=$(cat "$PAUSE_FILE")
        CURRENT_TIME=$(date +%s)

        if [ "$CURRENT_TIME" -lt "$PAUSE_UNTIL" ]; then
            return 0  # Still paused
        else
            # Pause expired, remove file
            rm -f "$PAUSE_FILE"
            log "Pause period expired, resuming bell"
            return 1  # Not paused
        fi
    fi
    return 1  # Not paused
}

# Play the bell sound
play_bell() {
    if [ ! -f "$AUDIO_FILE" ]; then
        log "ERROR: Audio file not found: $AUDIO_FILE"
        return 1
    fi

    # Use afplay (macOS built-in audio player)
    afplay "$AUDIO_FILE" &
    log "Bell played"
}

# Main loop
main() {
    load_config
    log "Mindfulness bell started (interval: ${INTERVAL}s, audio: $AUDIO_FILE)"

    while true; do
        if ! is_paused; then
            play_bell
        else
            PAUSE_UNTIL=$(cat "$PAUSE_FILE")
            REMAINING=$((PAUSE_UNTIL - $(date +%s)))
            log "Bell is paused (${REMAINING}s remaining)"
        fi

        sleep "$INTERVAL"
    done
}

# Run main loop
main
