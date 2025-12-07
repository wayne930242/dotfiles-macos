#!/bin/bash

# shellcheck disable=SC1091
source "$CONFIG_DIR/colors.sh"

# Get the frontmost app's document path or use current directory
# Try to get the current working directory from the focused terminal/editor

# Check common development apps for their current directory
FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

GIT_DIR=""

case "$FRONT_APP" in
    "WezTerm"|"Terminal"|"iTerm2"|"Alacritty"|"kitty")
        # For terminals, try to get the current directory via lsof
        FRONT_PID=$(osascript -e 'tell application "System Events" to get unix id of first process whose frontmost is true' 2>/dev/null)
        if [ -n "$FRONT_PID" ]; then
            # Get child shell process
            SHELL_PID=$(pgrep -P "$FRONT_PID" 2>/dev/null | head -1)
            if [ -n "$SHELL_PID" ]; then
                GIT_DIR=$(lsof -p "$SHELL_PID" 2>/dev/null | awk '$4=="cwd" {print $9}' | head -1)
            fi
        fi
        ;;
    "Cursor"|"Code"|"Visual Studio Code")
        # For VS Code/Cursor, try to get from recent window title or workspace
        # This is tricky, fallback to home directory projects
        GIT_DIR=$(osascript -e 'tell application "System Events" to get title of first window of process "'"$FRONT_APP"'"' 2>/dev/null | sed 's/ — .*//' | sed 's/^● //')
        if [[ "$GIT_DIR" != /* ]]; then
            GIT_DIR=""
        fi
        ;;
esac

# If we couldn't detect, hide the item
if [ -z "$GIT_DIR" ] || [ ! -d "$GIT_DIR" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

# Check if it's a git repo
BRANCH=$(git -C "$GIT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -n "$BRANCH" ]; then
    # Check for uncommitted changes
    DIRTY=$(git -C "$GIT_DIR" status --porcelain 2>/dev/null | head -1)

    if [ -n "$DIRTY" ]; then
        ICON="󰊢"
        LABEL="$BRANCH*"
    else
        ICON="󰊢"
        LABEL="$BRANCH"
    fi

    # Truncate branch name if too long
    if [ ${#LABEL} -gt 20 ]; then
        LABEL="${LABEL:0:17}..."
    fi

    sketchybar --set "$NAME" icon="$ICON" label="$LABEL" drawing=on
else
    sketchybar --set "$NAME" drawing=off
fi
