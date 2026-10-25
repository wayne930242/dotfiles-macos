// Command net shows the Straw Boss net in SketchyBar.
//
// `net feed` runs under launchd: it follows the net that the Straw Boss GUI server streams
// over SSE (its port and token are in ~/.pi/agent/straw-boss/gui.json), keeps the `net` pill
// and the JankyBorders focus color in step with it, and caches the rows for the other commands:
//
//	toggle     open or close the pill's popup (the pill's click_script)
//	event      the pill's script: closes the popup when the mouse leaves it
//	click KEY  a popup row: with shift, opens the unit in the GUI; otherwise jumps to it
//	jump KEY   focuses the unit's Herdr pane in its Ghostty window
//	next       jumps to the next unit waiting on the user (alt-w)
//	gui [KEY]  opens the GUI, at KEY's comms when given (alt-shift-w)
//	qr         shows a one-time remote pairing QR in the popup, turning remote access on if off
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

// Homebrew's bin directories hold herdr, aerospace, sketchybar, and borders; AeroSpace's
// exec, SketchyBar's scripts, and launchd may each start this program without them on PATH.
var toolDirs = []string{"/usr/local/bin", "/opt/homebrew/bin"}

func main() {
	path := filepath.SplitList(os.Getenv("PATH"))
	for _, dir := range toolDirs {
		if !slices.Contains(path, dir) {
			path = append([]string{dir}, path...)
		}
	}
	_ = os.Setenv("PATH", strings.Join(path, string(os.PathListSeparator)))
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "net:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	cmd, arg := "", ""
	if len(args) > 0 {
		cmd = args[0]
	}
	if len(args) > 1 {
		arg = args[1]
	}
	switch {
	case cmd == "feed":
		return feed()
	case cmd == "toggle":
		return toggle()
	case cmd == "event":
		switch os.Getenv("SENDER") {
		case "mouse.exited.global":
			if popupOpen() {
				closePopup()
			}
		case "forced":
			// A reload resets the pill to its hidden default with its popup closed, and the feed
			// redraws only on change
			closePopup()
			drawPill(readState())
		}
		return nil
	case cmd == "click" && arg != "":
		closePopup()
		if os.Getenv("MODIFIER") == "shift" {
			return openGUI(arg)
		}
		return jump(arg)
	case cmd == "jump" && arg != "":
		return jump(arg)
	case cmd == "next":
		return nextWaiting()
	case cmd == "gui":
		return openGUI(arg)
	case cmd == "qr":
		return showQR()
	}
	return fmt.Errorf("usage: net feed | toggle | event | click KEY | jump KEY | next | gui [KEY] | qr")
}
