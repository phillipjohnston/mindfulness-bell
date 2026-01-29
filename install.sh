#!/bin/bash

# Mindfulness Bell Installation Script

set -e  # Exit on error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLIST_NAME="com.embeddedartistry.mindfulness-bell.plist"
PLIST_SOURCE="${SCRIPT_DIR}/${PLIST_NAME}"
PLIST_DEST="${HOME}/Library/LaunchAgents/${PLIST_NAME}"

echo "===================================="
echo "Mindfulness Bell Installation"
echo "===================================="
echo ""

# Check if plist exists
if [ ! -f "$PLIST_SOURCE" ]; then
    echo "ERROR: ${PLIST_NAME} not found in ${SCRIPT_DIR}"
    exit 1
fi

# Check if already installed
if [ -L "$PLIST_DEST" ] || [ -f "$PLIST_DEST" ]; then
    echo "⚠️  Bell appears to be already installed"
    echo ""
    read -p "Reinstall? This will restart the service. (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi

    # Unload existing service
    echo "Unloading existing service..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true

    # Remove existing symlink/file
    rm -f "$PLIST_DEST"
fi

# Create LaunchAgents directory if it doesn't exist
mkdir -p "${HOME}/Library/LaunchAgents"

# Create symlink
echo "Creating symlink..."
ln -s "$PLIST_SOURCE" "$PLIST_DEST"
echo "✓ Symlink created at ${PLIST_DEST}"

# Load the service
echo ""
echo "Loading service..."
launchctl load "$PLIST_DEST"
echo "✓ Service loaded"

# Wait a moment for service to start
sleep 2

# Check if running
echo ""
echo "Verifying installation..."
if launchctl list | grep -q "mindfulness-bell"; then
    PID=$(launchctl list | grep mindfulness-bell | awk '{print $1}')
    echo "✓ Service is running (PID: $PID)"
else
    echo "⚠️  Service may not have started properly"
    echo "Check logs: tail -f ${SCRIPT_DIR}/bell-stderr.log"
    exit 1
fi

# Show status
echo ""
echo "===================================="
echo "Installation Complete!"
echo "===================================="
echo ""
echo "The mindfulness bell is now active and will:"
echo "  • Play every 20 minutes (configurable in .bell-config)"
echo "  • Start automatically when you log in"
echo "  • Run in the background"
echo ""
echo "Usage:"
echo "  ${SCRIPT_DIR}/bell-control.sh pause [minutes]  # Pause the bell"
echo "  ${SCRIPT_DIR}/bell-control.sh resume           # Resume the bell"
echo "  ${SCRIPT_DIR}/bell-control.sh status           # Check status"
echo ""
echo "Optional: Add this alias to ~/.zshrc for convenience:"
echo "  alias bell='${SCRIPT_DIR}/bell-control.sh'"
echo ""
echo "To uninstall, run: ${SCRIPT_DIR}/uninstall.sh"
echo ""
