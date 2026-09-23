# macOS Dotfiles - Cyberpunk Edition

[繁體中文](README.zh-TW.md)

My personal macOS configuration files for a cyberpunk-themed desktop environment.

## Components

- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** - Tiling window manager
- **[SketchyBar](https://github.com/FelixKratz/SketchyBar)** - Custom menu bar
- **[JankyBorders](https://github.com/FelixKratz/JankyBorders)** - Window borders
- **[Ghostty](https://ghostty.org/)** - Terminal; a thin host surface that launches straight into herdr, with native tabs/splits unbound and window decorations off so macOS only sees one window
- **[herdr](https://herdr.dev)** - Agent multiplexer that owns all workspaces, tabs, and panes in a single persistent session (default `Ctrl+B` prefix)
- **[Hammerspoon](https://www.hammerspoon.org/)** - Detects a double-tap of CMD and sends F19, which Ghostty binds globally to toggle its quick terminal
- **[tmux](https://github.com/tmux/tmux)** - Optional, on-demand sessions: `bin/tm [name]` attaches to a named session, and `bin/zed-tmux` gives each Zed project its own persistent session
- **[LazyVim](https://www.lazyvim.org/)** - Neovim configuration with CJK-aware wrapping and spell checking, Yazi, Snacks Explorer (with git and submodule state), Claude Code integration, per-directory session restore, and smart-splits window navigation

## Screenshots

![Cyberpunk Desktop](screenshot.png)

## Quick Install

```bash
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos
cd ~/dotfiles-macos
./install.sh
```

The install script will:
1. Install Homebrew (if not present)
2. Install AeroSpace, Hammerspoon, SketchyBar, JankyBorders, nowplaying-cli, Neovim, and Yazi
3. Backup your existing configs to `~/.dotfiles-backup/`
4. Create symlinks for SketchyBar, JankyBorders, Neovim, Ghostty, AeroSpace, tmux, Hammerspoon, and herdr
5. Start all services and restart AeroSpace so the CLI and app server use the same version

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
brew install nowplaying-cli  # For media widget
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
| `alt-d` | D | Docker |
| `alt-a` | A | AI / Agents |
| `alt-z` | Z | Obsidian (Notes) |
| `alt-x` | X | Xcode (plus Simulator and Android Studio) |

Workspaces 1–3 go to the secondary monitor when one is connected; letter workspaces stay on the main monitor.
`alt-enter` opens Ghostty, and `alt-shift-;` enters service mode (`esc` reloads the config).

## SketchyBar Widgets

**Left:** Mode Indicator (service mode) | Workspaces | Front App

**Right:** Calendar | Audio (volume + mic) | Battery | Temperature | Input | Network | Media | CPU / Memory

## Theme

Cyberpunk color palette for SketchyBar and JankyBorders:
- Primary: `#00fff7` (Neon Cyan)
- Secondary: `#ff00ff` (Magenta)
- Accent: `#ff6600` (Orange)
- Background: `#0a0a0f` (Dark)

Ghostty uses the `Dracula` theme at 90% opacity with blur, and herdr uses `vesper`.

## Tests

`tests/` holds shell contract checks for the AeroSpace config, the install script, and the theme settings:

```bash
for t in tests/*.sh; do bash "$t"; done
```

## License

MIT
