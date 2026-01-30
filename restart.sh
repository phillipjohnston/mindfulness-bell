#!/bin/bash

# Mindfulness Bell Restart Script
# Use this after changing configuration

PLIST_NAME="com.embeddedartistry.mindfulness-bell.plist"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_NAME}"

echo "Restarting mindfulness bell..."

if [ ! -e "$PLIST_PATH" ]; then
    echo "ERROR: Bell is not installed"
    echo "Run ./install.sh first"
    exit 1
fi

# Use kickstart -k to force a clean restart
# Format: gui/<uid>/service-id
SERVICE_TARGET="gui/$(id -u)/${PLIST_NAME%.plist}"
launchctl kickstart -k "$SERVICE_TARGET"

# Wait a moment for service to restart
sleep 1

# Verify it's running
if launchctl list | grep -q "mindfulness-bell"; then
    echo "✓ Bell restarted successfully"
else
    echo "⚠️  Service may not have restarted properly"
    echo "Check logs: tail -f bell-stderr.log"
    exit 1
fi
