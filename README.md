# macOS Dotfiles - Cyberpunk Edition

My personal macOS configuration files for a cyberpunk-themed desktop environment.

## Components

- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** - Tiling window manager
- **[SketchyBar](https://github.com/FelixKratz/SketchyBar)** - Custom menu bar
- **[JankyBorders](https://github.com/FelixKratz/JankyBorders)** - Window borders

## Screenshots

<!-- Add your screenshots here -->

## Quick Install

```bash
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos
cd ~/dotfiles-macos
./install.sh
```

The install script will:
1. Install Homebrew (if not present)
2. Install AeroSpace, SketchyBar, JankyBorders, and dependencies
3. Backup your existing configs
4. Create symlinks to the dotfiles
5. Start all services

## Manual Installation

### Prerequisites

```bash
brew install --cask nikitabobko/tap/aerospace
brew tap FelixKratz/formulae
brew install sketchybar
brew install borders
brew install nowplaying-cli  # For media widget
```

### Setup

```bash
# Clone this repo
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos

# Symlink configurations
ln -sf ~/dotfiles-macos/sketchybar ~/.config/sketchybar
ln -sf ~/dotfiles-macos/borders ~/.config/borders
ln -sf ~/dotfiles-macos/.aerospace.toml ~/.aerospace.toml

# Start services
brew services start sketchybar
brew services start borders
```

## Workspaces

| Key | Workspace | Purpose |
|-----|-----------|---------|
| `alt-1/2/3` | 1, 2, 3 | General use |
| `alt-t` | T | Terminal (WezTerm) |
| `alt-b` | B | Browser |
| `alt-g` | G | Game/Chill |
| `alt-s` | S | Social (Discord, Slack, Telegram) |
| `alt-p` | P | Linear (Project management) |
| `alt-d` | D | Docker |
| `alt-a` | A | AI/Agents |
| `alt-n` | N | Obsidian (Notes) |

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
