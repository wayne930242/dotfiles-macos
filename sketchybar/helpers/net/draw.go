package main

import (
	"fmt"
	"os"
	"os/exec"
)

const (
	maxRows = 40
	// Rows added at runtime name their fonts; Hack Nerd Font has only Regular and Bold, and a
	// missing weight falls back to the system font, which lacks the Nerd Font glyphs.
	fontIcon  = "icon.font=Hack Nerd Font Mono:Bold:14.0"
	fontLabel = "label.font=Hack Nerd Font Mono:Regular:13.0"
	fontHead  = "label.font=Hack Nerd Font Mono:Bold:13.0"
)

func sketchybar(args ...string) {
	_ = exec.Command("sketchybar", args...).Run()
}

func markColor(c map[string]string, mark string) string {
	switch mark {
	case "waiting":
		return c["ORANGE"]
	case "working":
		return c["BLUE"]
	case "commanding":
		return c["PURPLE"]
	case "done":
		return c["GREEN"]
	case "error":
		return c["RED"]
	}
	return c["SPACE_INACTIVE"]
}

// pillAccent is the pill's color: the most urgent state present.
func pillAccent(c map[string]string, n Counts) string {
	switch {
	case n.Waiting > 0:
		return c["ORANGE"]
	case n.Error > 0:
		return c["RED"]
	case n.Working > 0:
		return c["BLUE"]
	}
	return c["SPACE_OCCUPIED"]
}

// drawPill hides the pill while no GUI server runs; otherwise it colors only the icon and
// label, and the pill keeps the border every pill in the bar shares.
func drawPill(s State) {
	c := s.Colors
	if !s.Online {
		sketchybar("--set", "net", "drawing=off")
		return
	}
	n := Count(s.Rows)
	label, accent, text := PillLabel(n), pillAccent(c, n), c["LABEL_COLOR"]
	if n.Waiting > 0 {
		text = c["ORANGE"]
	}
	drawing := "off"
	if label != "" {
		drawing = "on"
	}
	sketchybar("--set", "net", "drawing=on", "icon="+glyphRobot, "icon.color="+accent,
		"label="+label, "label.drawing="+drawing, "label.color="+text)
}

// drawPopup rebuilds the popup's rows in one SketchyBar call.
func drawPopup(s State, self string) {
	c := s.Colors
	args := []string{"--remove", `/net\.row\..*/`}
	add := func(name string, props ...string) {
		args = append(args, "--add", "item", name, "popup.net", "--set", name,
			"background.drawing=off", "padding_left=6", "padding_right=6", fontIcon, fontLabel)
		args = append(args, props...)
	}
	rows := s.Rows
	for i, r := range rows {
		if i == maxRows {
			add("net.row.more", "icon.drawing=off", "label.color="+c["SPACE_INACTIVE"],
				fmt.Sprintf("label=… %d more in the GUI", len(rows)-maxRows))
			break
		}
		name := fmt.Sprintf("net.row.%d", i)
		if r.Kind == "base" {
			add(name, "icon.drawing=off", "label="+r.Name, "label.color="+c["ICON_COLOR"], fontHead)
			continue
		}
		text := c["LABEL_COLOR"]
		if r.Depth > 0 {
			text = c["SPACE_OCCUPIED"]
		}
		props := []string{"icon=" + glyphOf(r.Mark), "icon.drawing=on", "icon.color=" + markColor(c, r.Mark),
			fmt.Sprintf("label.padding_left=%d", RowIndent(r)), "label=" + RowLabel(r), "label.color=" + text}
		// click_script runs through sh -c: only a key that needs no quoting goes into it
		if SafeKey(r.Key) {
			props = append(props, "click_script="+self+" click "+r.Key)
		}
		add(name, props...)
	}
	add("net.row.qr", "icon="+glyphQR, "icon.drawing=on", "icon.color="+c["ICON_COLOR"],
		"label=Remote QR", "click_script="+self+" qr")
	add("net.row.gui", "icon="+glyphOpen, "icon.drawing=on", "icon.color="+c["ICON_COLOR"],
		"label=Open Straw Net", "click_script="+self+" gui")
	sketchybar(args...)
}

func popupOpen() bool {
	_, err := os.Stat(popupFlag)
	return err == nil
}

func closePopup() {
	// The QR's pairing code stays valid for ten minutes, so it leaves with the popup
	sketchybar("--set", "net", "popup.drawing=off", "--remove", qrItem)
	_ = os.Remove(popupFlag)
	_ = os.Remove(qrFile)
}

func toggle() error {
	if popupOpen() {
		closePopup()
		return nil
	}
	// A QR from an earlier opening may be used up or expired
	sketchybar("--remove", qrItem)
	_ = os.Remove(qrFile)
	s := readState()
	if s.Colors == nil {
		c, err := theme()
		if err != nil {
			return err
		}
		s.Colors = c
	}
	self, err := os.Executable()
	if err != nil {
		return fmt.Errorf("locate binary: %w", err)
	}
	drawPopup(s, self)
	if err := os.MkdirAll(cacheDir, 0o700); err != nil {
		return fmt.Errorf("cache dir: %w", err)
	}
	if err := os.WriteFile(popupFlag, nil, 0o600); err != nil {
		return fmt.Errorf("popup flag: %w", err)
	}
	sketchybar("--set", "net", "popup.drawing=on")
	return nil
}

// setBorder turns the focus border orange while a unit waits. It is skipped when JankyBorders
// is not running, because `borders` with arguments would start a new instance in the foreground.
func setBorder(c map[string]string, waiting bool, current string) string {
	want := c["BORDER_ACTIVE_COLOR"]
	if waiting {
		want = c["ORANGE"]
	}
	if want == current {
		return current
	}
	if exec.Command("pgrep", "-x", "borders").Run() != nil {
		return current
	}
	if exec.Command("borders", "active_color="+want).Run() != nil {
		return current
	}
	return want
}
