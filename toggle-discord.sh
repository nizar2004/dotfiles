#!/bin/bash

# 1. Get the ID of the currently focused window
ACTIVE_WIN=$(kdotool getactivewindow)

# 2. Get the exact class name of that active window
ACTIVE_CLASS=$(kdotool getwindowclassname "$ACTIVE_WIN" 2>/dev/null)

# 3. Check if the active window's name contains "discord" (case-insensitive)
if [[ "${ACTIVE_CLASS,,}" == *"discord"* ]]; then
    # Discord is currently focused. Send the "X" (close) signal to push it to the tray.
    kdotool windowclose "$ACTIVE_WIN"
else
    # Discord is NOT focused. Try to find a visible Discord window.
    DISCORD_WIN=$(kdotool search --onlyvisible --class "discord" | head -n 1)

    if [ -z "$DISCORD_WIN" ]; then
        # No window exists (it's in the tray or completely closed). Launch it.
        discord &
    else
        # A Discord window exists in the background. Bring it to the front.
        kdotool windowactivate "$DISCORD_WIN"
    fi
fi
