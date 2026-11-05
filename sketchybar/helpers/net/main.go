// Command net draws the agent pill in SketchyBar: Claude's active account and its 7-day usage
// (from ccswitch), whether caffeine keeps the Mac awake, and a popup for the Straw Boss net
// (the remote QR, a message to the head tower, the GUI), caffeine and sleep, and Claude's accounts.
//
// `net feed` runs under launchd: it follows the net that the Straw Boss GUI server streams
// over SSE (its port and token are in ~/.pi/agent/straw-boss/gui.json), keeps the JankyBorders
// focus color in step with it, and caches the rows and the head tower's key for the other commands:
//
//	toggle            open or close the pill's popup (the pill's click_script)
//	event             the pill's script: redraws it every 30 s and refreshes Claude every 5 minutes,
//	                  and closes the popup when the mouse leaves it
//	tell              asks for a message in a dialog and sends it to the head tower
//	caffeine toggle | off | on SECONDS
//	                  turns caffeine off or on, for SECONDS or (0) until turned off
//	claude switch N   switches Claude Code to account N
//	claude dashboard  opens ccswitch's dashboard in Herdr
//	jump KEY          focuses the unit's Herdr pane in its Ghostty window
//	next              jumps to the next unit waiting on the user (alt-w)
//	gui [KEY]         opens the GUI, at KEY's comms when given (alt-shift-w)
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
	// ccswitch lives in the user's bin directories and needs Homebrew's bash 4+ and jq
	for _, dir := range append([]string{filepath.Join(home, "bin"), filepath.Join(home, ".local/bin")}, toolDirs...) {
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
	cmd, arg, arg2 := "", "", ""
	if len(args) > 0 {
		cmd = args[0]
	}
	if len(args) > 1 {
		arg = args[1]
	}
	if len(args) > 2 {
		arg2 = args[2]
	}
	switch {
	case cmd == "feed":
		return feed()
	case cmd == "toggle":
		return toggle()
	case cmd == "event":
		return event(os.Getenv("SENDER"))
	case cmd == "tell":
		return tellHead()
	case cmd == "caffeine":
		closePopup()
		return caffeine(arg, arg2)
	case cmd == "claude" && arg == "switch" && arg2 != "":
		return switchAccount(arg2)
	case cmd == "claude" && arg == "dashboard":
		return openDashboard()
	case cmd == "jump" && arg != "":
		return jump(arg)
	case cmd == "next":
		return nextWaiting()
	case cmd == "gui":
		closePopup()
		return openGUI(arg)
	}
	return fmt.Errorf("usage: net feed | toggle | event | tell | caffeine toggle|off|on SECONDS | claude switch N|dashboard | jump KEY | next | gui [KEY]")
}

func event(sender string) error {
	switch sender {
	case "mouse.exited.global":
		if popupOpen() {
			closePopup()
		}
		return nil
	case "forced":
		// A reload resets the pill to its hidden default with its popup closed
		closePopup()
	case "system_woke":
		err := refreshClaude()
		redraw()
		return err
	}
	// The routine tick redraws the pill only: rebuilding an open popup every 30 s would flicker
	c, err := colors()
	if err != nil {
		return err
	}
	drawPill(c)
	if claudeDue() {
		err = refreshClaude()
		drawPill(c)
	}
	return err
}
