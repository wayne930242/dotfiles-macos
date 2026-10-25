package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

const (
	ghosttyBundle = "com.mitchellh.ghostty"
	// The name Chrome gives the GUI installed as an app (Install page as app), from the page title.
	guiAppName = "Straw Net"
)

// paneFor finds the Herdr pane whose pi session file carries the unit's key in its name.
func paneFor(agentList []byte, key string) (string, error) {
	var out struct {
		Result struct {
			Agents []struct {
				PaneID  string `json:"pane_id"`
				Session *struct {
					Value string `json:"value"`
				} `json:"agent_session"`
			} `json:"agents"`
		} `json:"result"`
	}
	if err := json.Unmarshal(agentList, &out); err != nil {
		return "", fmt.Errorf("parse herdr agent list: %w", err)
	}
	for _, a := range out.Result.Agents {
		if a.Session != nil && strings.Contains(filepath.Base(a.Session.Value), key) {
			return a.PaneID, nil
		}
	}
	return "", nil
}

// ghosttyWindow is the oldest Ghostty window: Ghostty is the single host window of Herdr.
func ghosttyWindow() string {
	out, err := exec.Command("aerospace", "list-windows", "--all", "--app-bundle-id", ghosttyBundle,
		"--format", "%{window-id}").Output()
	if err != nil {
		return ""
	}
	best, bestID := "", 0
	for _, f := range strings.Fields(string(out)) {
		if id, err := strconv.Atoi(f); err == nil && (best == "" || id < bestID) {
			best, bestID = f, id
		}
	}
	return best
}

func jump(key string) error {
	list, err := exec.Command("herdr", "agent", "list").Output()
	if err != nil {
		return fmt.Errorf("herdr agent list: %w", err)
	}
	pane, err := paneFor(list, key)
	if err != nil {
		return err
	}
	if pane == "" {
		// A unit with no local pane (a Claude Code sidecar, an outpost) still has its comms in the GUI.
		return openGUI(key)
	}
	if err := exec.Command("herdr", "agent", "focus", pane).Run(); err != nil {
		return fmt.Errorf("herdr agent focus %s: %w", pane, err)
	}
	if w := ghosttyWindow(); w != "" {
		_ = exec.Command("aerospace", "focus", "--window-id", w).Run()
	}
	return nil
}

func guiWindow() string {
	out, err := exec.Command("aerospace", "list-windows", "--all", "--format", "%{window-id}|%{app-name}").Output()
	if err != nil {
		return ""
	}
	for _, line := range strings.Split(string(out), "\n") {
		if id, app, ok := strings.Cut(line, "|"); ok && app == guiAppName {
			return id
		}
	}
	return ""
}

// openGUI shows the GUI: the installed Straw Net app when there is one, else a browser tab.
// A unit's comms open as a page, since the app cannot be told where to navigate.
func openGUI(key string) error {
	base, err := guiURL()
	if err != nil {
		return err
	}
	if key != "" {
		for _, r := range readState().Rows {
			if r.Key == key {
				return exec.Command("open", base+"w/"+url.PathEscape(r.Base)+"/s/"+url.PathEscape(key)).Run()
			}
		}
	}
	if w := guiWindow(); w != "" {
		return exec.Command("aerospace", "focus", "--window-id", w).Run()
	}
	if exec.Command("open", "-a", guiAppName).Run() == nil {
		return nil
	}
	return exec.Command("open", base).Run()
}

// nextWaiting cycles through the units waiting on the user: each press goes past the last one jumped to.
func nextWaiting() error {
	var waiting []string
	for _, r := range readState().Rows {
		if r.Kind == "unit" && r.Mark == "waiting" {
			waiting = append(waiting, r.Key)
		}
	}
	if len(waiting) == 0 {
		// Nothing waits: flash the pill's border instead.
		sketchybar("--animate", "tanh", "10", "--set", "net", "background.border_width=3",
			"--animate", "tanh", "10", "--set", "net", "background.border_width=1")
		return nil
	}
	last, _ := os.ReadFile(lastJump)
	key := NextKey(waiting, strings.TrimSpace(string(last)))
	if err := os.MkdirAll(cacheDir, 0o700); err != nil {
		return fmt.Errorf("cache dir: %w", err)
	}
	if err := os.WriteFile(lastJump, []byte(key), 0o600); err != nil {
		return fmt.Errorf("record jump: %w", err)
	}
	return jump(key)
}

// NextKey is the key after last in keys, wrapping around; the first key when last is not among them.
func NextKey(keys []string, last string) string {
	for i, k := range keys {
		if k == last {
			return keys[(i+1)%len(keys)]
		}
	}
	return keys[0]
}
