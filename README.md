# Mindfulness Bell

An automated mindfulness bell that plays at regular intervals to help maintain awareness and presence throughout your day.

## Features

- Plays a bell sound at configurable intervals (default: 20 minutes)
- Runs automatically in the background on macOS
- Pause the bell temporarily with a simple command
- Automatically skips bell during Zoom meetings
- Configurable audio file, interval, and volume settings

## Setup

### Quick Install

Run the installation script:

```bash
./install.sh
```

This will:
- Create a symlink to your LaunchAgents directory
- Load and start the service
- Verify the installation

The bell will now start automatically and run in the background.

### Manual Installation (Alternative)

If you prefer to install manually:

```bash
chmod +x mindfulness-bell.sh bell-control.sh
ln -s "$(pwd)/com.embeddedartistry.mindfulness-bell.plist" ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.embeddedartistry.mindfulness-bell.plist
```

### Configuration (Optional)

Edit `.bell-config` to customize:

- `INTERVAL`: Time between bells in seconds (default: 1200 = 20 minutes)
- `AUDIO_FILE`: Path to your preferred audio file
- `RELATIVE_VOLUME`: Percentage of current system volume (0-100, default: 100)
  - Example: 60 means play at 60% of whatever your current system volume is
  - Useful for making the bell quieter than your music/videos without changing system volume
- `AUTO_MUTE_ZOOM`: Automatically skip bell during Zoom meetings (true/false, default: true)
  - When enabled, the bell won't play during active Zoom meetings
  - Set to false if you want the bell to play even during meetings

After changing configuration, restart the service:
```bash
./restart.sh
```

Or manually:
```bash
launchctl kickstart -k gui/$(id -u)/com.embeddedartistry.mindfulness-bell
```

## Usage

### Pause the bell

```bash
# Pause for 60 minutes (default)
./bell-control.sh pause

# Pause for 30 minutes
./bell-control.sh pause 30

# Pause for 2 hours
./bell-control.sh pause 120
```

### Resume the bell

```bash
./bell-control.sh resume
```

### Check status

```bash
./bell-control.sh status
```

## Management

### Uninstall

To completely remove the bell:

```bash
./uninstall.sh
```

This will unload the service, remove the symlink, and optionally remove log files.

### Stop the bell service

```bash
launchctl unload ~/Library/LaunchAgents/com.embeddedartistry.mindfulness-bell.plist
```

### Start the bell service

```bash
launchctl load ~/Library/LaunchAgents/com.embeddedartistry.mindfulness-bell.plist
```

### Restart the service

After changing configuration, use the restart script:

```bash
./restart.sh
```

This uses `launchctl kickstart -k` to force a clean restart and kill any old processes.

Alternatively, you can manually restart:

```bash
# Recommended: kickstart (forces clean restart)
launchctl kickstart -k gui/$(id -u)/com.embeddedartistry.mindfulness-bell

# Or: manual unload/load (may leave old process running)
launchctl unload ~/Library/LaunchAgents/com.embeddedartistry.mindfulness-bell.plist
launchctl load ~/Library/LaunchAgents/com.embeddedartistry.mindfulness-bell.plist
```

### View logs

```bash
# Bell activity log
tail -f bell.log

# System stdout
tail -f bell-stdout.log

# System errors
tail -f bell-stderr.log
```

## Adding to PATH (Optional)

For easier access to the control script from anywhere, you can create an alias in your shell configuration:

```bash
# Add to ~/.zshrc or ~/.bashrc
alias bell='~/src/mindfulness-bell/bell-control.sh'
```

Then you can use:

```bash
bell pause 30
bell resume
bell status
```

## Troubleshooting

### Bell not playing

1. Check if the service is running:
   ```bash
   launchctl list | grep mindfulness-bell
   ```

2. Check the logs for errors:
   ```bash
   cat bell.log
   cat bell-stderr.log
   ```

3. Verify the audio file exists:
   ```bash
   ls -l audio/medium_bell_wake_plus_full.mp3
   ```

### Bell playing too quietly or too loudly

The bell plays at a percentage of your current system volume (controlled by `RELATIVE_VOLUME` in `.bell-config`):

- To make the bell quieter: Set `RELATIVE_VOLUME` to a lower value (e.g., 60 for 60% of system volume)
- To make the bell louder: Set `RELATIVE_VOLUME` to a higher value (e.g., 100 to match system volume)
- The bell volume automatically adjusts when you change your system volume

Don't forget to restart the service after changing the configuration.

### Bell not skipping during Zoom meetings

If the bell plays during Zoom meetings when you expected it to be skipped:

1. Check that `AUTO_MUTE_ZOOM=true` in `.bell-config`
2. Verify you're in an active meeting (not just Zoom open)
3. Check the logs to see if meeting detection is working:
   ```bash
   tail -f bell.log
   ```
   You should see "Zoom meeting detected" messages during meetings

If you want the bell to play even during meetings, set `AUTO_MUTE_ZOOM=false` in `.bell-config`.

## Customization

### Using a different audio file

1. Add your audio file to the `audio/` directory
2. Edit `.bell-config` and update the `AUDIO_FILE` path
3. Restart the service

### Changing the interval

1. Edit `.bell-config` and update `INTERVAL` (in seconds)
   - 5 minutes: 300
   - 15 minutes: 900
   - 20 minutes: 1200
   - 30 minutes: 1800
   - 1 hour: 3600
2. Restart the service

### Adjusting the volume

1. Edit `.bell-config` and update `RELATIVE_VOLUME` (percentage of system volume)
   - Very quiet: 30
   - Quiet: 50
   - Medium: 60-70
   - Normal: 100 (matches system volume)
2. Restart the service

The bell will play at this percentage of whatever your current system volume is, so it automatically adjusts when you change your system volume.
