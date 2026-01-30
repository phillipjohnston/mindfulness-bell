# Zoom Auto-Mute Design

**Date:** 2026-01-30
**Feature:** Automatically skip mindfulness bell during active Zoom meetings

## Overview

Add automatic meeting detection to skip the mindfulness bell when the user is in an active Zoom meeting. The bell will silently skip (not play at all) when a meeting is detected, then resume normal operation after the meeting ends.

## Requirements

- Skip bell completely when in active Zoom meeting (not pause, not quieter - just don't play)
- Detect only active meetings, not when Zoom is just open
- Work for Zoom only (other apps can be added later)
- Configurable - user can disable if desired
- No special permissions required
- Fail-safe - if detection fails, bell plays normally

## Architecture

### Integration with Existing System

The meeting detection integrates into the existing bell loop as a new check function, similar to the existing `is_paused()` function.

**Current flow:**
```
Loop every INTERVAL seconds
  → Check if paused
  → If not paused: play bell
```

**New flow:**
```
Loop every INTERVAL seconds
  → Check if paused
  → Check if in meeting (new!)
  → If not paused AND not in meeting: play bell
```

### Detection Method

Use process detection via `pgrep` to check for Zoom's `CptHost` process, which only runs during active meetings.

**Why CptHost?**
- Reliable indicator of active meeting
- No false positives when Zoom is just open
- Fast check with no performance impact
- No special permissions required
- Works on macOS without accessibility access

### Design Decisions

- Detection runs every time before playing (every 20 minutes by default)
- Manual pause functionality takes precedence over meeting detection
- Configurable via `AUTO_MUTE_ZOOM` flag (defaults to enabled)
- Logs when bell is skipped due to meeting

## Implementation

### Configuration Changes

Add to `.bell-config`:
```bash
# Auto-mute bell during Zoom meetings (true/false)
AUTO_MUTE_ZOOM=true
```

### Code Changes

**1. New detection function in `mindfulness-bell.sh`:**
```bash
is_in_meeting() {
    if [ "$AUTO_MUTE_ZOOM" != "true" ]; then
        return 1  # Feature disabled, not in meeting
    fi

    # Check for Zoom's CptHost process (meeting component)
    if pgrep -q CptHost; then
        return 0  # In meeting
    fi

    return 1  # Not in meeting
}
```

**2. Update `load_config()` function:**
Add default for new config option:
```bash
AUTO_MUTE_ZOOM=${AUTO_MUTE_ZOOM:-true}  # Default: enabled
```

**3. Modify main loop:**
```bash
while true; do
    if ! is_paused; then
        if ! is_in_meeting; then
            play_bell
        else
            log "Bell skipped (Zoom meeting detected)"
        fi
    else
        PAUSE_UNTIL=$(cat "$PAUSE_FILE")
        REMAINING=$((PAUSE_UNTIL - $(date +%s)))
        log "Bell is paused (${REMAINING}s remaining)"
    fi

    sleep "$INTERVAL"
done
```

**4. Update startup log message:**
```bash
log "Mindfulness bell started (interval: ${INTERVAL}s, audio: $AUDIO_FILE, relative volume: ${RELATIVE_VOLUME}%, auto-mute Zoom: ${AUTO_MUTE_ZOOM})"
```

## Error Handling

The design uses fail-safe defaults:

- **pgrep fails:** Returns non-zero, function returns 1 (not in meeting), bell plays normally
- **CptHost name changes:** Detection stops working, bell plays normally (no crashes)
- **Zoom not installed:** pgrep finds nothing, bell plays normally
- **Feature disabled:** Checked first, minimal overhead

No special error handling needed - all failure modes result in normal bell operation.

## Edge Cases

| Scenario | Behavior | Status |
|----------|----------|--------|
| Zoom not installed | pgrep returns nothing, bell plays | ✓ |
| Multiple Zoom instances | Any CptHost detected = in meeting | ✓ |
| Meeting ends | CptHost disappears, next interval plays | ✓ |
| Feature disabled | Check skipped, bell always plays | ✓ |
| Zoom open but no meeting | No CptHost process, bell plays | ✓ |

## Testing

### Manual Testing
1. Start Zoom meeting → verify bell skipped (check logs)
2. End meeting → verify bell resumes at next interval
3. Toggle `AUTO_MUTE_ZOOM=false` → verify bell plays during meeting
4. Check logs show "Zoom meeting detected" when meetings active

### Verification Commands
```bash
# Check if currently in meeting
pgrep -q CptHost && echo "In meeting" || echo "Not in meeting"

# View recent bell activity
tail -20 bell.log

# Test service restart after config change
launchctl unload ~/Library/LaunchAgents/com.embeddedartistry.mindfulness-bell.plist
launchctl load ~/Library/LaunchAgents/com.embeddedartistry.mindfulness-bell.plist
```

No automated tests needed - observable behavior is sufficient.

## Documentation Updates

### README.md Updates

**Configuration section:**
Add `AUTO_MUTE_ZOOM` to configuration options with explanation.

**Troubleshooting section:**
Add note about how to disable auto-mute if needed.

**Features section:**
Add bullet point about automatic Zoom meeting detection.

## Future Enhancements

Potential additions (not in scope for this implementation):

- Support for other video conferencing apps (Google Meet, Teams, WebEx)
- Configurable list of apps to detect
- Different behavior per app (skip vs. quiet vs. pause)
- Status command shows meeting detection status

## Implementation Checklist

- [ ] Add `AUTO_MUTE_ZOOM` to `.bell-config`
- [ ] Add `is_in_meeting()` function to `mindfulness-bell.sh`
- [ ] Update `load_config()` with new default
- [ ] Modify main loop to check meeting status
- [ ] Update startup log message
- [ ] Update README.md configuration section
- [ ] Update README.md features section
- [ ] Update README.md troubleshooting section
- [ ] Test with real Zoom meeting
- [ ] Test feature toggle
- [ ] Commit changes
