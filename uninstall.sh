#!/bin/bash

# Mindfulness Bell Uninstallation Script

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLIST_NAME="com.embeddedartistry.mindfulness-bell.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/${PLIST_NAME}"

echo "===================================="
echo "Mindfulness Bell Uninstallation"
echo "===================================="
echo ""

# Check if installed
if [ ! -e "$PLIST_DEST" ]; then
    echo "Bell is not installed (no plist found at ${PLIST_DEST})"
    exit 0
fi

# Confirm uninstallation
read -p "Are you sure you want to uninstall the mindfulness bell? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled"
    exit 0
fi

# Unload the service
echo "Unloading service..."
if launchctl list | grep -q "mindfulness-bell"; then
    launchctl unload "$PLIST_DEST"
    echo "✓ Service unloaded"
else
    echo "✓ Service was not running"
fi

# Remove symlink/file
echo "Removing plist..."
rm -f "$PLIST_DEST"
echo "✓ Plist removed"

# Ask about log files
echo ""
read -p "Remove log files and state files? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "${SCRIPT_DIR}/bell.log"
    rm -f "${SCRIPT_DIR}/bell-stdout.log"
    rm -f "${SCRIPT_DIR}/bell-stderr.log"
    rm -f "${SCRIPT_DIR}/.bell-paused"
    echo "✓ Log and state files removed"
fi

echo ""
echo "===================================="
echo "Uninstallation Complete!"
echo "===================================="
echo ""
echo "The mindfulness bell has been removed."
echo "To reinstall, run: ${SCRIPT_DIR}/install.sh"
echo ""
