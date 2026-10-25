package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var (
	home, _   = os.UserHomeDir()
	guiState  = filepath.Join(home, ".pi/agent/straw-boss/gui.json")
	cacheDir  = filepath.Join(home, ".cache/sketchybar")
	cacheFile = filepath.Join(cacheDir, "net.json")
	// Present while the popup is open, so the feed redraws the popup only then without asking SketchyBar.
	popupFlag = filepath.Join(cacheDir, "net-popup-open")
	lastJump  = filepath.Join(cacheDir, "net-last-jump")
)

// State is the feed's cache: the rows, and the theme colors so a click needs no theme lookup.
type State struct {
	Online bool              `json:"online"`
	Rows   []Row             `json:"rows"`
	Colors map[string]string `json:"colors"`
}

func readState() State {
	var s State
	if b, err := os.ReadFile(cacheFile); err == nil {
		_ = json.Unmarshal(b, &s)
	}
	return s
}

func writeState(s State) error {
	if err := os.MkdirAll(cacheDir, 0o700); err != nil {
		return fmt.Errorf("cache dir: %w", err)
	}
	b, err := json.Marshal(s)
	if err != nil {
		return fmt.Errorf("encode cache: %w", err)
	}
	tmp := cacheFile + ".tmp"
	if err := os.WriteFile(tmp, b, 0o600); err != nil {
		return fmt.Errorf("write cache: %w", err)
	}
	return os.Rename(tmp, cacheFile)
}

// guiURL is the GUI server's local base URL, token included, ending in a slash.
func guiURL() (string, error) {
	b, err := os.ReadFile(guiState)
	if err != nil {
		return "", fmt.Errorf("read gui.json: %w", err)
	}
	var g struct {
		Port  int    `json:"port"`
		Token string `json:"token"`
	}
	if err := json.Unmarshal(b, &g); err != nil {
		return "", fmt.Errorf("parse gui.json: %w", err)
	}
	if g.Port == 0 || g.Token == "" {
		return "", errors.New("gui.json names no server")
	}
	return fmt.Sprintf("http://127.0.0.1:%d/%s/", g.Port, g.Token), nil
}

// guiCSRF is the secret the GUI server takes on writes from its local page.
func guiCSRF() (string, error) {
	b, err := os.ReadFile(guiState)
	if err != nil {
		return "", fmt.Errorf("read gui.json: %w", err)
	}
	var g struct {
		CSRF string `json:"csrf"`
	}
	if err := json.Unmarshal(b, &g); err != nil {
		return "", fmt.Errorf("parse gui.json: %w", err)
	}
	if g.CSRF == "" {
		return "", errors.New("gui.json names no csrf secret")
	}
	return g.CSRF, nil
}

// configDir is the SketchyBar config directory: this binary lives in <config>/helpers/bin.
func configDir() (string, error) {
	exe, err := os.Executable()
	if err != nil {
		return "", fmt.Errorf("locate binary: %w", err)
	}
	exe, err = filepath.EvalSymlinks(exe)
	if err != nil {
		return "", fmt.Errorf("resolve binary: %w", err)
	}
	return filepath.Dir(filepath.Dir(filepath.Dir(exe))), nil
}

var themeVars = []string{"LABEL_COLOR", "ICON_COLOR", "ORANGE", "BLUE", "PURPLE", "GREEN", "RED",
	"SPACE_INACTIVE", "SPACE_OCCUPIED", "BORDER_ACTIVE_COLOR"}

// theme reads the colors from the SketchyBar and JankyBorders themes, so this program keeps none of its own.
func theme() (map[string]string, error) {
	dir, err := configDir()
	if err != nil {
		return nil, err
	}
	borders := filepath.Join(filepath.Dir(dir), "borders")
	script := `CONFIG_DIR="$1"; source "$CONFIG_DIR/colors.sh"
source "$2/themes/$(sed -n 's/^THEME="\(.*\)"/\1/p' "$2/bordersrc").sh"
shift 2; for v in "$@"; do echo "$v=${!v}"; done`
	out, err := exec.Command("bash", append([]string{"-c", script, "theme", dir, borders}, themeVars...)...).Output()
	if err != nil {
		return nil, fmt.Errorf("read theme: %w", err)
	}
	colors := map[string]string{}
	for _, line := range strings.Fields(string(out)) {
		if k, v, ok := strings.Cut(line, "="); ok && v != "" {
			colors[k] = v
		}
	}
	for _, v := range themeVars {
		if colors[v] == "" {
			return nil, fmt.Errorf("theme lacks %s", v)
		}
	}
	return colors, nil
}
