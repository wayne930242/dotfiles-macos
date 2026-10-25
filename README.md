# macOS Dotfiles - Catppuccin Mocha

[繁體中文](README.zh-TW.md)

My personal macOS configuration files, themed with Catppuccin Mocha throughout.

## Components

- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** - Tiling window manager
- **[SketchyBar](https://github.com/FelixKratz/SketchyBar)** - Custom menu bar
- **[JankyBorders](https://github.com/FelixKratz/JankyBorders)** - Window borders
- **[Ghostty](https://ghostty.org/)** - Terminal; a thin host surface that launches straight into herdr, with native tabs/splits unbound and window decorations off so macOS only sees one window; `` Ctrl+` `` toggles its quick terminal globally
- **[herdr](https://herdr.dev)** - Agent multiplexer that owns all workspaces, tabs, and panes in a single persistent session (default `Ctrl+B` prefix)
- **[Hammerspoon](https://www.hammerspoon.org/)** - No active features; keeps a disabled CMD+1~9 Ghostty window switcher for a return to multi-window mode
- **[tmux](https://github.com/tmux/tmux)** - Optional, on-demand sessions: `bin/tm [name]` attaches to a named session, and `bin/zed-tmux` gives each Zed project its own persistent session
- **[LazyVim](https://www.lazyvim.org/)** - Neovim configuration with CJK-aware wrapping and spell checking, Yazi, Snacks Explorer (with git and submodule state), Claude Code integration, per-directory session restore, and smart-splits window navigation

## Screenshots

![Desktop](screenshot.png)

## Quick Install

```bash
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos
cd ~/dotfiles-macos
./install.sh
```

The install script will:
1. Install Homebrew (if not present)
2. Install AeroSpace, Hammerspoon, SketchyBar, JankyBorders, media-control, jq, Go, sketchybar-app-font, Neovim, and Yazi
3. Backup your existing configs to `~/.dotfiles-backup/`
4. Create symlinks for SketchyBar, JankyBorders, Neovim, Ghostty, AeroSpace, tmux, Hammerspoon, and herdr
5. Build the SketchyBar net helper (`sketchybar/helpers/bin/net`)
6. Start all services, including the net feed's launch agent, and restart AeroSpace so the CLI and app server use the same version

Ghostty, herdr, tmux, and fonts are not installed by the script; see [Prerequisites](#prerequisites).

After installing, open Hammerspoon once, grant Accessibility permission, and enable "Launch at Login" from its menu bar icon.

### Other Commands

```bash
./install.sh install    # Install (default)
./install.sh uninstall  # Remove symlinks and stop services
./install.sh restore    # Restore from a previous backup
./install.sh help       # Show help
```

## Manual Installation

### Prerequisites

```bash
brew install --cask nikitabobko/tap/aerospace
brew install --cask hammerspoon
brew tap FelixKratz/formulae
brew install sketchybar
brew install borders
brew install media-control  # For media widget
brew install jq go          # SketchyBar plugins; the net helper is built with Go
brew install --cask font-sketchybar-app-font  # App icons in the workspace pill
brew install --cask ghostty
brew install herdr
brew install tmux            # Optional, for bin/tm and bin/zed-tmux
brew install neovim yazi
brew install --cask font-iansui  # Taiwanese/Hakka glyph fallback in Ghostty
```

Ghostty also expects `MesloLGS NF`, and SketchyBar uses `Hack Nerd Font Mono`.

### Setup

```bash
# Clone this repo
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos

# Symlink configurations
ln -sf ~/dotfiles-macos/sketchybar ~/.config/sketchybar
ln -sf ~/dotfiles-macos/borders ~/.config/borders
ln -sf ~/dotfiles-macos/nvim ~/.config/nvim
ln -sf ~/dotfiles-macos/ghostty ~/.config/ghostty
ln -sf ~/dotfiles-macos/.aerospace.toml ~/.aerospace.toml
ln -sf ~/dotfiles-macos/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles-macos/hammerspoon ~/.hammerspoon
mkdir -p ~/.config/herdr
ln -sf ~/dotfiles-macos/herdr/config.toml ~/.config/herdr/config.toml

# Start services
brew services start sketchybar
brew services start borders
```

On the first Neovim launch, LazyVim bootstraps `lazy.nvim` and installs the plugins pinned in `nvim/lazy-lock.json`.

## Zed Integration

The `bin/zed-tmux` wrapper makes Zed's terminal panel attach to a per-project tmux session named `zed-<project-basename>`, so each Zed project keeps its own persistent shell state across restarts.

Add to `~/.config/zed/settings.json`:

```jsonc
"terminal": {
  "shell": {
    "with_arguments": {
      "program": "/Users/<you>/dotfiles-macos/bin/zed-tmux",
      "args": []
    }
  }
}
```

## Workspaces

| Key | Workspace | Purpose |
|-----|-----------|---------|
| `alt-1` | 1 | Terminal (Ghostty) |
| `alt-2` ~ `alt-3` | 2–3 | General use |
| `alt-c` | C | Browser (Chrome / Comet) |
| `alt-g` | G | Game / Chill |
| `alt-s` | S | Social (Discord, Telegram) |
| `alt-q` | Q | Project (Linear + Slack) |
| `alt-d` | D | OrbStack |
| `alt-a` | A | AI / Agents (the Straw Net GUI) |
| `alt-z` | Z | Obsidian (Notes) |
| `alt-x` | X | Xcode (plus Simulator and Android Studio) |

Workspaces 1–3 go to the secondary monitor when one is connected; letter workspaces stay on the main monitor.
`alt-enter` opens Ghostty, and `alt-shift-;` enters service mode (`esc` reloads the config).

| Key | Action |
|-----|--------|
| `alt-w` | Jump to the next agent waiting on you (each press goes to the one after) |
| `alt-shift-w` | Open the Straw Net GUI |
| service mode `b` | Bring the newest secondary browser window (an agent's page) beside the current workspace; again sends it back to G |

## SketchyBar

**Left:** Mode Indicator (service mode) | Workspaces, with an icon per app

**Right of the notch:** Media (only while something plays)

**Right:** Straw Boss net | Status (audio, battery, input; its popup holds CPU / memory, temperature, and network) | Calendar

Every group is one pill with the same background and a neutral border; icons take a color only to report a state (an agent waiting on you, a low battery, a muted mic).

### Straw Boss net

The pill counts the [Straw Boss](https://github.com/wayne930242/pi-straw-boss) agents that wait on you, fail, work, or are done, and hides while no Straw Boss GUI server runs. Click it for the whole net as a tree: click a row to focus that agent's herdr pane, or shift-click to open its comms in the GUI. "Remote QR" shows a one-time pairing QR (valid ten minutes) for opening the GUI on a phone over Tailscale, and turns remote access on first if it is off. While an agent waits on you, the focused window's border turns orange.

`sketchybar/helpers/net` is a small Go program. Its `feed` runs as the launch agent `com.wayne930242.sketchybar-net`, follows the event stream of the Straw Boss GUI server (its address is in `~/.pi/agent/straw-boss/gui.json`), and redraws only what changed; it logs to `~/Library/Logs/sketchybar-net.log`. With the herdr sidebar collapsed to zero width (`prefix+b` opens it), the pill is the agent list.

For the GUI as its own window in workspace A, open it (`/boss gui` in pi), then in Chrome choose Cast, save, and share > Install page as app; AeroSpace moves the `Straw Net` app to A.

### The notch

The built-in display's notch hides whatever is drawn under it, and SketchyBar's left and right items ignore it. `plugins/notch.sh` measures the notch at load and on every display change (its width in points follows the display scaling: 185 pt at the default 1512 pt, 220 pt at 1800 pt), sets `notch_width`, and records where the notch starts. When the left side would reach it, `plugins/aerospace.sh` shows fewer app icons per workspace.

The bar itself is transparent and only the pills draw. Each item is a window ordered above the bar's window; on macOS 27 a click on the bar's empty space raises the bar's window over them, and SketchyBar reorders its windows only when items change, so a drawn bar would hide every item until the next reload.

## Theme

Every component uses [Catppuccin Mocha](https://catppuccin.com/palette): Ghostty (`Catppuccin Mocha`), herdr (`catppuccin`), LazyVim (`catppuccin-mocha`), SketchyBar, and JankyBorders.

SketchyBar and JankyBorders load their colors from `themes/<name>.sh`; set `THEME` in `sketchybar/colors.sh` and `borders/bordersrc` to switch. The previous cyberpunk palette is archived as `themes/cyberpunk.sh` in both directories.

## Tests

`tests/` holds shell contract checks for the AeroSpace config, the install script, and the theme settings:

```bash
for t in tests/*.sh; do bash "$t"; done
```

The net helper has Go unit tests:

```bash
(cd sketchybar/helpers/net && go test ./...)
```

## License

MIT
