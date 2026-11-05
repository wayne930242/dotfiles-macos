package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

const (
	// Rows added at runtime name their fonts; Hack Nerd Font has only Regular and Bold, and a
	// missing weight falls back to the system font, which lacks the Nerd Font glyphs.
	fontIcon  = "icon.font=Hack Nerd Font Mono:Bold:14.0"
	fontLabel = "label.font=Hack Nerd Font Mono:Regular:13.0"
	fontHead  = "label.font=Hack Nerd Font Mono:Bold:13.0"
)

func sketchybar(args ...string) {
	_ = exec.Command("sketchybar", args...).Run()
}

// Pill is what the pill shows: Claude's active account and its 7-day usage, a coffee cup while
// caffeine is on, and the robot alone when there is neither.
type Pill struct {
	Icon, IconColor, Label, LabelColor string
}

func PillOf(c map[string]string, accounts []Account, caf Caffeine) Pill {
	p := Pill{Icon: glyphRobot, IconColor: c["SPACE_INACTIVE"], LabelColor: c["LABEL_COLOR"]}
	if accounts != nil {
		p.Icon = glyphClaude
		var active *Account
		for i := range accounts {
			if accounts[i].Active {
				active = &accounts[i]
				break
			}
		}
		switch {
		case active == nil:
			p.IconColor, p.Label, p.LabelColor = c["RED"], "- · !", c["RED"]
		case active.Status() == "login":
			p.IconColor, p.Label, p.LabelColor = c["RED"], string(active.Num)+" · !", c["RED"]
		case active.Status() != "ok":
			p.IconColor, p.Label, p.LabelColor = c["YELLOW"], string(active.Num)+" · 7d ?", c["YELLOW"]
		default:
			p.IconColor, p.Label = c["ICON_COLOR"], fmt.Sprintf("%s · 7d %d%%", active.Num, active.Seven())
			if t := UsageTone(c, active.Seven()); t != "" {
				p.IconColor = t
			}
		}
	}
	if caf.On {
		if p.Label == "" {
			p.Label = glyphCoffee
		} else {
			p.Label = glyphCoffee + "  " + p.Label
		}
	}
	return p
}

func drawPill(c map[string]string) {
	p := PillOf(c, readAccounts(), readCaffeine())
	drawing := "on"
	if p.Label == "" {
		drawing = "off"
	}
	sketchybar("--set", "net", "drawing=on", "icon="+p.Icon, "icon.color="+p.IconColor,
		"label="+p.Label, "label.drawing="+drawing, "label.color="+p.LabelColor)
}

// redraw draws the pill, and the popup while it is open.
func redraw() {
	c, err := colors()
	if err != nil {
		fmt.Fprintln(os.Stderr, "net:", err)
		return
	}
	drawPill(c)
	if popupOpen() {
		drawPopup(readState(), c)
	}
}

// drawPopup rebuilds the popup's rows in one SketchyBar call: the Straw Net (the remote QR, a message
// to the head tower, the GUI) while its server runs, caffeine and when the Mac sleeps, then Claude's accounts.
func drawPopup(s State, c map[string]string) {
	exe, err := os.Executable()
	if err != nil {
		fmt.Fprintln(os.Stderr, "net: locate binary:", err)
		return
	}
	// click_script runs through sh -c
	self := "'" + strings.ReplaceAll(exe, "'", `'\''`) + "'"
	args := []string{"--remove", `/net\.row\..*/`}
	add := func(name string, props ...string) {
		args = append(args, "--add", "item", name, "popup.net", "--set", name,
			"background.drawing=off", "padding_left=6", "padding_right=6", fontIcon, fontLabel)
		args = append(args, props...)
	}
	heading := func(name, label string) {
		add(name, "icon.drawing=off", "label="+label, "label.color="+c["ICON_COLOR"], fontHead)
	}
	row := func(name, glyph, color, label string, props ...string) {
		add(name, append([]string{"icon=" + glyph, "icon.drawing=on", "icon.color=" + color,
			"label=" + label, "label.color=" + c["LABEL_COLOR"]}, props...)...)
	}

	if s.Online {
		heading("net.row.h.net", "Straw Net")
		if qr := qrProps(c); qr != nil {
			add(qrItem, qr...)
		}
		if s.Head != "" {
			row("net.row.tell", glyphMessage, c["ICON_COLOR"], "Message the head tower…", "click_script="+self+" tell")
		}
		row("net.row.gui", glyphOpen, c["ICON_COLOR"], "Open Straw Net", "click_script="+self+" gui")
	}

	caf := readCaffeine()
	heading("net.row.h.caf", "Caffeine")
	cafColor := c["SPACE_INACTIVE"]
	if caf.On {
		cafColor = c["ORANGE"]
	}
	row("net.row.caf", glyphCoffee, cafColor, CaffeineLabel(caf), "click_script="+self+" caffeine toggle")
	for _, d := range []struct {
		name, label string
		secs        int
	}{{"1h", "Keep awake 1 hour", 3600}, {"3h", "Keep awake 3 hours", 3 * 3600}, {"inf", "Keep awake until turned off", 0}} {
		row("net.row.caf."+d.name, glyphTimer, c["SPACE_INACTIVE"], d.label,
			"label.color="+c["SPACE_OCCUPIED"], "click_script="+self+" caffeine on "+strconv.Itoa(d.secs))
	}
	power := readPower()
	row("net.row.sleep", glyphSleep, c["SPACE_INACTIVE"], SleepLabel(caf, power))
	if h := HoldersLabel(power); h != "" {
		row("net.row.holders", glyphSleep, c["SPACE_INACTIVE"], h, "label.color="+c["SPACE_OCCUPIED"])
	}

	if accounts := readAccounts(); accounts != nil {
		heading("net.row.h.claude", "Claude")
		now := time.Now()
		for i, a := range accounts {
			mark, markColor := "○ ", c["SPACE_INACTIVE"]
			if a.Active {
				mark, markColor = "● ", c["GREEN"]
			}
			text := c["LABEL_COLOR"]
			switch a.Status() {
			case "login":
				text = c["RED"]
			case "limited", "unavailable":
				text = c["YELLOW"]
			default:
				if t := UsageTone(c, a.Seven()); t != "" {
					text = t
				}
			}
			props := []string{"icon=" + mark + string(a.Num), "icon.drawing=on", "icon.color=" + markColor,
				"label=" + AccountLabel(a, now), "label.color=" + text}
			// click_script runs through sh -c: only an account number goes into it
			if accountNum.MatchString(string(a.Num)) {
				props = append(props, "click_script="+self+" claude switch "+string(a.Num))
			}
			add(fmt.Sprintf("net.row.claude.%d", i), props...)
		}
		row("net.row.dashboard", glyphDashboard, c["ICON_COLOR"], "Open ccswitch dashboard",
			"label.color="+c["SPACE_INACTIVE"], "click_script="+self+" claude dashboard")
	}
	sketchybar(args...)
}

func popupOpen() bool {
	_, err := os.Stat(popupFlag)
	return err == nil
}

// popupOpenAs reports whether the popup is open, and is still the opening that wrote nonce.
func popupOpenAs(nonce string) bool {
	b, err := os.ReadFile(popupFlag)
	return err == nil && string(b) == nonce
}

func closePopup() {
	// The QR's pairing code stays valid for ten minutes, so it leaves with the popup
	sketchybar("--set", "net", "popup.drawing=off", "--remove", `/net\.row\..*/`)
	_ = os.Remove(popupFlag)
	clearQR()
}

// toggle opens the popup, or closes it. It opens from the caches at once; then it makes the remote
// QR while Tailscale is up, and refreshes Claude when its accounts moved outside the pill.
func toggle() error {
	if popupOpen() {
		closePopup()
		return nil
	}
	clearQR() // a QR from an earlier opening may be used up or expired
	c, err := colors()
	if err != nil {
		return err
	}
	s := readState()
	if err := os.MkdirAll(cacheDir, 0o700); err != nil {
		return fmt.Errorf("cache dir: %w", err)
	}
	wantQR := s.Online && tailnetUp()
	if wantQR {
		_ = os.WriteFile(qrWant, nil, 0o600)
	}
	// Each opening gets its own nonce, so a QR request from an earlier opening cannot draw into this one
	nonce := strconv.FormatInt(time.Now().UnixNano(), 36)
	if err := os.WriteFile(popupFlag, []byte(nonce), 0o600); err != nil {
		return fmt.Errorf("popup flag: %w", err)
	}
	drawPopup(s, c)
	sketchybar("--set", "net", "popup.drawing=on")
	if accountsMoved() {
		if err := refreshClaude(); err == nil {
			redraw()
		}
	}
	if wantQR {
		return makeQR(nonce)
	}
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
