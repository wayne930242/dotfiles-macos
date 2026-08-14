# macOS Dotfiles - Cyberpunk Edition

[繁體中文](README.zh-TW.md)

My personal macOS configuration files for a cyberpunk-themed desktop environment.

## Components

- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** - Tiling window manager
- **[SketchyBar](https://github.com/FelixKratz/SketchyBar)** - Custom menu bar
- **[JankyBorders](https://github.com/FelixKratz/JankyBorders)** - Window borders
- **[Ghostty](https://ghostty.org/)** - Terminal; stays a thin GUI layer with zero native tabs/splits of its own, quick terminal summoned by double-tapping CMD (via Hammerspoon)
- **[tmux](https://github.com/tmux/tmux)** - Owns all multiplexing (panes, windows, resize, copy mode, persistent sessions); Ghostty forwards its CMD-based shortcuts straight into tmux's leader keymap. Also ships with a `bin/zed-tmux` wrapper that gives each Zed project its own persistent session
- **[LazyVim](https://www.lazyvim.org/)** - Neovim configuration with CJK-aware wrapping, Yazi, Sidekick, Snacks Explorer, and seamless pane navigation

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
2. Install AeroSpace, SketchyBar, JankyBorders, and dependencies
3. Backup your existing configs to `~/.dotfiles-backup/`
4. Create symlinks to the dotfiles, including `~/.config/nvim`
5. Start all services and restart AeroSpace so the CLI and app server use the same version

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
brew tap FelixKratz/formulae
brew install sketchybar
brew install borders
brew install nowplaying-cli  # For media widget
brew install --cask ghostty
brew install tmux
brew install neovim yazi
```

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
| `alt-s` | S | Social (Discord, Slack, Telegram) |
| `alt-q` | Q | Project (Linear + Slack) |
| `alt-d` | D | Docker |
| `alt-a` | A | AI / Agents |
| `alt-z` | Z | Obsidian (Notes) |
| `alt-x` | X | Xcode |

## SketchyBar Widgets

**Left:** Workspaces | Front App | Git Branch

**Right:** Calendar | Volume/Mic | Input | Battery | Weather | Network | Media | CPU | Memory

## Theme

Cyberpunk color palette:
- Primary: `#00fff7` (Neon Cyan)
- Secondary: `#ff00ff` (Magenta)
- Accent: `#ff6600` (Orange)
- Background: `#0a0a0f` (Dark)

## License

MIT
