package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// Claude Code accounts from ccswitch (github.com/wayne930242/cc-account-switcher): the active account's
// 7-day usage on the pill, every account in the popup. Only a refresh touches the network: ccswitch --json
// goes into the cache every 5 minutes, and the popup draws from the cache.

var (
	claudeCache = filepath.Join(cacheDir, "claude.json")
	// Touched on every refresh attempt, so a failing one waits its turn like a good one
	claudeStamp = filepath.Join(cacheDir, "claude.fetched")
)

const (
	claudeEvery = 5 * time.Minute
	usageWarn   = 60
	usageHot    = 85
)

// text is a JSON string or number as text: ccswitch gives num as a string, and an error may be anything.
type text string

func (t *text) UnmarshalJSON(b []byte) error {
	var s string
	if json.Unmarshal(b, &s) == nil {
		*t = text(s)
		return nil
	}
	if string(b) == "null" {
		*t = ""
		return nil
	}
	*t = text(b)
	return nil
}

type Account struct {
	Num        text   `json:"num"`
	Email      string `json:"email"`
	Active     bool   `json:"active"`
	TokenState string `json:"token_state"`
	Error      text   `json:"error"`
	Usage      *struct {
		SevenDay *struct {
			Utilization float64 `json:"utilization"`
			ResetsAt    string  `json:"resets_at"`
		} `json:"seven_day"`
	} `json:"usage"`
}

// Status is ok; login (log in again, red); limited (usage API or token renewal rate limited, yellow);
// unavailable (usage not fetched for a passing reason such as the network, yellow).
func (a Account) Status() string {
	switch a.TokenState {
	case "relogin", "save-failed", "missing", "unknown":
		return "login"
	}
	switch {
	case strings.Contains(string(a.Error), "unauthorized"):
		return "login"
	case strings.Contains(string(a.Error), "rate limited"), a.TokenState == "refresh-rate-limited":
		return "limited"
	case a.Error != "", a.Usage == nil:
		return "unavailable"
	}
	return "ok"
}

// Seven is the 7-day usage in whole percent; Anthropic dropped the 5-hour window (2026-11).
func (a Account) Seven() int {
	if a.Usage == nil || a.Usage.SevenDay == nil {
		return 0
	}
	return int(a.Usage.SevenDay.Utilization)
}

func (a Account) ResetsIn(now time.Time) string {
	if a.Usage == nil || a.Usage.SevenDay == nil || a.Usage.SevenDay.ResetsAt == "" {
		return ""
	}
	at, err := time.Parse(time.RFC3339Nano, a.Usage.SevenDay.ResetsAt)
	if err != nil {
		return ""
	}
	return Span(at.Sub(now))
}

// UsageTone colors usage: plain, then yellow from 60%, red from 85%; "" for plain.
func UsageTone(c map[string]string, pct int) string {
	switch {
	case pct >= usageHot:
		return c["RED"]
	case pct >= usageWarn:
		return c["YELLOW"]
	}
	return ""
}

// AccountLabel is an account's popup row: its email, then its 7-day usage and the time to its reset.
func AccountLabel(a Account, now time.Time) string {
	email := []rune(a.Email)
	if len(email) > 22 {
		email = email[:22]
	}
	label := fmt.Sprintf("%-22s  ", string(email))
	switch a.Status() {
	case "login":
		return label + "login needs attention"
	case "limited":
		return label + "usage rate limited, retry later"
	case "unavailable":
		return label + "usage unavailable for now"
	}
	label += fmt.Sprintf("7d %3d%%", a.Seven())
	reset := ""
	if r := a.ResetsIn(now); r != "" {
		reset = " ↻" + r
	}
	for len([]rune(reset)) < 7 {
		reset += " "
	}
	return label + reset
}

func findCcswitch() (string, bool) {
	candidates := []string{os.Getenv("CCSWITCH_BIN")}
	if p, err := exec.LookPath("ccswitch"); err == nil {
		candidates = append(candidates, p)
	}
	candidates = append(candidates, filepath.Join(home, ".local/bin/ccswitch"), filepath.Join(home, "bin/ccswitch"), filepath.Join(home, "bin/ccswitch.sh"))
	for _, c := range candidates {
		if fi, err := os.Stat(c); c != "" && err == nil && fi.Mode().IsRegular() && fi.Mode()&0o111 != 0 {
			return c, true
		}
	}
	return "", false
}

func readAccounts() []Account {
	b, err := os.ReadFile(claudeCache)
	if err != nil {
		return nil
	}
	var accounts []Account
	if json.Unmarshal(b, &accounts) != nil {
		return nil
	}
	return accounts
}

// refreshClaude puts ccswitch --json into the cache. Without a ccswitch that has --json (1.3.0), the cache
// goes, and the pill drops its Claude part; a failed fetch keeps the last good cache.
func refreshClaude() error {
	_ = os.MkdirAll(cacheDir, 0o700)
	_ = os.WriteFile(claudeStamp, nil, 0o600)
	cc, ok := findCcswitch()
	if ok {
		help, _ := exec.Command(cc, "--help").CombinedOutput()
		ok = bytes.Contains(help, []byte("--json"))
	}
	if !ok {
		_ = os.Remove(claudeCache)
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	out, err := exec.CommandContext(ctx, cc, "--json").Output()
	if err != nil {
		return fmt.Errorf("ccswitch --json: %w", err)
	}
	var accounts []Account
	if err := json.Unmarshal(out, &accounts); err != nil {
		return fmt.Errorf("ccswitch --json: %w", err)
	}
	// A unique temporary file: the 30 s tick, an opening popup, and a switch may refresh at once
	tmp, err := os.CreateTemp(cacheDir, "claude-*.json")
	if err != nil {
		return fmt.Errorf("write claude cache: %w", err)
	}
	_, werr := tmp.Write(out)
	if cerr := tmp.Close(); werr == nil {
		werr = cerr
	}
	if werr != nil {
		_ = os.Remove(tmp.Name())
		return fmt.Errorf("write claude cache: %w", werr)
	}
	return os.Rename(tmp.Name(), claudeCache)
}

// claudeDue reports whether the last refresh attempt is older than claudeEvery.
func claudeDue() bool {
	fi, err := os.Stat(claudeStamp)
	return err != nil || time.Since(fi.ModTime()) >= claudeEvery
}

var listLine = regexp.MustCompile(`^ *([0-9]+): ([^ ]+?)( \(active\))?$`)

// ListedAccounts is "num email active" per account from ccswitch --list, in the cache's form.
func ListedAccounts(list string) []string {
	var out []string
	for _, line := range strings.Split(list, "\n") {
		if m := listLine.FindStringSubmatch(line); m != nil {
			out = append(out, fmt.Sprintf("%s %s %t", m[1], m[2], m[3] != ""))
		}
	}
	return out
}

func cachedAccounts(accounts []Account) []string {
	var out []string
	for _, a := range accounts {
		out = append(out, fmt.Sprintf("%s %s %t", a.Num, a.Email, a.Active))
	}
	return out
}

// accountsMoved reports whether accounts were added, removed, or switched outside the pill since the
// last refresh; ccswitch --list is local, so it spends no usage API call (it rate-limits).
func accountsMoved() bool {
	cc, ok := findCcswitch()
	if !ok {
		return false
	}
	out, err := exec.Command(cc, "--list").Output()
	if err != nil {
		return false
	}
	listed := ListedAccounts(string(out))
	return len(listed) > 0 && strings.Join(listed, "\n") != strings.Join(cachedAccounts(readAccounts()), "\n")
}

var accountNum = regexp.MustCompile(`^[0-9]+$`)

func switchAccount(num string) error {
	closePopup()
	if !accountNum.MatchString(num) {
		return fmt.Errorf("account number, got %q", num)
	}
	cc, ok := findCcswitch()
	if !ok {
		return errors.New("ccswitch not found")
	}
	sketchybar("--set", "net", "label=switching…", "label.drawing=on")
	_ = exec.Command(cc, "--switch-to", num).Run()
	err := refreshClaude()
	redraw()
	return err
}

func openDashboard() error {
	closePopup()
	// Herdr opens the plugin pane in its client; bring Ghostty forward so it shows
	_ = exec.Command("open", "-a", "Ghostty").Run()
	return exec.Command("herdr", "plugin", "pane", "open", "--plugin", "wayne930242.ccswitch", "--entrypoint", "dashboard", "--focus").Run()
}
