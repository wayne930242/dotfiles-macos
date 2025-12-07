#!/bin/bash

# Cyberpunk macOS Dotfiles Installer
# Usage: ./install.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         CYBERPUNK macOS DOTFILES INSTALLER                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check for Homebrew
if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew found"
fi

# Install dependencies
echo ""
echo "📦 Installing dependencies..."

brew tap FelixKratz/formulae
brew tap nikitabobko/tap

brew install --cask nikitabobko/tap/aerospace || true
brew install sketchybar || true
brew install borders || true
brew install nowplaying-cli || true

# Backup existing configs
echo ""
echo "💾 Backing up existing configs..."

BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

[ -d "$HOME/.config/sketchybar" ] && mv "$HOME/.config/sketchybar" "$BACKUP_DIR/"
[ -d "$HOME/.config/borders" ] && mv "$HOME/.config/borders" "$BACKUP_DIR/"
[ -f "$HOME/.aerospace.toml" ] && mv "$HOME/.aerospace.toml" "$BACKUP_DIR/"

echo "   Backed up to: $BACKUP_DIR"

# Create symlinks
echo ""
echo "🔗 Creating symlinks..."

mkdir -p "$HOME/.config"

ln -sf "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
ln -sf "$DOTFILES_DIR/borders" "$HOME/.config/borders"
ln -sf "$DOTFILES_DIR/.aerospace.toml" "$HOME/.aerospace.toml"

echo "   ✅ sketchybar -> ~/.config/sketchybar"
echo "   ✅ borders -> ~/.config/borders"
echo "   ✅ .aerospace.toml -> ~/.aerospace.toml"

# Make scripts executable
echo ""
echo "🔧 Setting permissions..."

chmod +x "$DOTFILES_DIR/sketchybar/sketchybarrc"
chmod +x "$DOTFILES_DIR/borders/bordersrc"
find "$DOTFILES_DIR/sketchybar" -name "*.sh" -exec chmod +x {} \;

# Start services
echo ""
echo "🚀 Starting services..."

brew services start sketchybar || brew services restart sketchybar
brew services start borders || brew services restart borders

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    INSTALLATION COMPLETE!                     ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  Next steps:                                                  ║"
echo "║  1. Open AeroSpace app                                        ║"
echo "║  2. Grant accessibility permissions when prompted             ║"
echo "║  3. Press alt+shift+; then esc to reload AeroSpace config     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎨 Enjoy your Cyberpunk desktop!"
