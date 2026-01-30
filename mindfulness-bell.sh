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
    RELATIVE_VOLUME=${RELATIVE_VOLUME:-100}  # Default: 100% of system volume
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

    # Calculate volume based on current system volume and relative setting
    # Get current system volume (0-100)
    SYSTEM_VOLUME=$(osascript -e "output volume of (get volume settings)")

    # Calculate relative volume: (system_volume * relative_percentage) / 100
    # Then convert to afplay's 0.0-1.0 scale: / 100
    # Combined: (system_volume * relative_percentage) / 10000
    PLAY_VOLUME=$(echo "scale=2; ($SYSTEM_VOLUME * $RELATIVE_VOLUME) / 10000" | bc)

    # Use afplay with volume flag (0.0 to 1.0)
    afplay -v "$PLAY_VOLUME" "$AUDIO_FILE" &
    log "Bell played (system volume: ${SYSTEM_VOLUME}%, relative: ${RELATIVE_VOLUME}%, play volume: ${PLAY_VOLUME})"
}

# Main loop
main() {
    load_config
    log "Mindfulness bell started (interval: ${INTERVAL}s, audio: $AUDIO_FILE, relative volume: ${RELATIVE_VOLUME}%)"

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
