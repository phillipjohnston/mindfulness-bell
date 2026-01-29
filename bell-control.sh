#!/bin/bash

# Mindfulness Bell Control Script
# Control the mindfulness bell (pause, resume, status)

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PAUSE_FILE="${SCRIPT_DIR}/.bell-paused"
LOG_FILE="${SCRIPT_DIR}/bell.log"

# Show usage
usage() {
    cat << EOF
Usage: $(basename "$0") <command> [duration]

Commands:
  pause <minutes>   Pause the bell for specified minutes (default: 60)
  resume            Resume the bell immediately
  status            Show current bell status
  help              Show this help message

Examples:
  $(basename "$0") pause 30     # Pause for 30 minutes
  $(basename "$0") pause         # Pause for 60 minutes (default)
  $(basename "$0") resume        # Resume immediately
  $(basename "$0") status        # Check if paused
EOF
    exit 1
}

# Pause the bell
pause_bell() {
    local minutes=${1:-60}
    local seconds=$((minutes * 60))
    local pause_until=$(($(date +%s) + seconds))

    echo "$pause_until" > "$PAUSE_FILE"
    echo "Bell paused for $minutes minutes (until $(date -r $pause_until '+%H:%M:%S'))"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bell paused for ${minutes} minutes" >> "$LOG_FILE"
}

# Resume the bell
resume_bell() {
    if [ -f "$PAUSE_FILE" ]; then
        rm -f "$PAUSE_FILE"
        echo "Bell resumed"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bell manually resumed" >> "$LOG_FILE"
    else
        echo "Bell is not paused"
    fi
}

# Show status
show_status() {
    if [ -f "$PAUSE_FILE" ]; then
        PAUSE_UNTIL=$(cat "$PAUSE_FILE")
        CURRENT_TIME=$(date +%s)

        if [ "$CURRENT_TIME" -lt "$PAUSE_UNTIL" ]; then
            REMAINING=$((PAUSE_UNTIL - CURRENT_TIME))
            REMAINING_MIN=$((REMAINING / 60))
            echo "Bell is PAUSED"
            echo "Remaining: ${REMAINING_MIN} minutes (resumes at $(date -r $PAUSE_UNTIL '+%H:%M:%S'))"
        else
            echo "Bell is ACTIVE (pause expired)"
        fi
    else
        echo "Bell is ACTIVE"
    fi

    # Show last few log entries
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "Recent activity:"
        tail -5 "$LOG_FILE"
    fi
}

# Main script
case "${1:-}" in
    pause)
        pause_bell "$2"
        ;;
    resume)
        resume_bell
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Error: Unknown command '${1:-}'"
        echo ""
        usage
        ;;
esac
