#!/bin/bash

# Cyberpunk macOS Dotfiles Installer
# Usage: ./install.sh [install|uninstall|restore]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_BASE="$HOME/.dotfiles-backup"

print_header() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║         CYBERPUNK macOS DOTFILES                              ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

install_deps() {
    # Check for Homebrew
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "✅ Homebrew found"
    fi

    echo ""
    echo "📦 Installing dependencies..."

    brew tap FelixKratz/formulae 2>/dev/null || true
    brew tap nikitabobko/tap 2>/dev/null || true

    brew install --cask nikitabobko/tap/aerospace 2>/dev/null || echo "   AeroSpace already installed or skipped"
    brew install sketchybar 2>/dev/null || echo "   SketchyBar already installed or skipped"
    brew install borders 2>/dev/null || echo "   Borders already installed or skipped"
    brew install nowplaying-cli 2>/dev/null || echo "   nowplaying-cli already installed or skipped"
}

backup_configs() {
    echo ""
    echo "💾 Backing up existing configs..."

    BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    if [ -d "$HOME/.config/sketchybar" ] && [ ! -L "$HOME/.config/sketchybar" ]; then
        cp -r "$HOME/.config/sketchybar" "$BACKUP_DIR/"
        echo "   ✅ Backed up sketchybar"
    fi

    if [ -d "$HOME/.config/borders" ] && [ ! -L "$HOME/.config/borders" ]; then
        cp -r "$HOME/.config/borders" "$BACKUP_DIR/"
        echo "   ✅ Backed up borders"
    fi

    if [ -f "$HOME/.aerospace.toml" ] && [ ! -L "$HOME/.aerospace.toml" ]; then
        cp "$HOME/.aerospace.toml" "$BACKUP_DIR/"
        echo "   ✅ Backed up .aerospace.toml"
    fi

    if [ -f "$HOME/.wezterm.lua" ] && [ ! -L "$HOME/.wezterm.lua" ]; then
        cp "$HOME/.wezterm.lua" "$BACKUP_DIR/"
        echo "   ✅ Backed up .wezterm.lua"
    fi

    # Check if backup dir is empty
    if [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        rmdir "$BACKUP_DIR"
        echo "   No existing configs to backup"
    else
        echo "   📁 Backed up to: $BACKUP_DIR"
    fi
}

create_symlinks() {
    echo ""
    echo "🔗 Creating symlinks..."

    mkdir -p "$HOME/.config"

    # Remove existing symlinks or directories
    [ -L "$HOME/.config/sketchybar" ] && rm "$HOME/.config/sketchybar"
    [ -L "$HOME/.config/borders" ] && rm "$HOME/.config/borders"
    [ -L "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml"
    [ -L "$HOME/.wezterm.lua" ] && rm "$HOME/.wezterm.lua"
    [ -d "$HOME/.config/sketchybar" ] && rm -rf "$HOME/.config/sketchybar"
    [ -d "$HOME/.config/borders" ] && rm -rf "$HOME/.config/borders"
    [ -f "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml"
    [ -f "$HOME/.wezterm.lua" ] && rm "$HOME/.wezterm.lua"

    ln -sf "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
    ln -sf "$DOTFILES_DIR/borders" "$HOME/.config/borders"
    ln -sf "$DOTFILES_DIR/.aerospace.toml" "$HOME/.aerospace.toml"
    ln -sf "$DOTFILES_DIR/.wezterm.lua" "$HOME/.wezterm.lua"

    echo "   ✅ sketchybar -> ~/.config/sketchybar"
    echo "   ✅ borders -> ~/.config/borders"
    echo "   ✅ .aerospace.toml -> ~/.aerospace.toml"
    echo "   ✅ .wezterm.lua -> ~/.wezterm.lua"
}

set_permissions() {
    echo ""
    echo "🔧 Setting permissions..."

    chmod +x "$DOTFILES_DIR/sketchybar/sketchybarrc"
    chmod +x "$DOTFILES_DIR/borders/bordersrc"
    find "$DOTFILES_DIR/sketchybar" -name "*.sh" -exec chmod +x {} \;

    echo "   ✅ Permissions set"
}

start_services() {
    echo ""
    echo "🚀 Starting services..."

    brew services restart sketchybar 2>/dev/null && echo "   ✅ SketchyBar started" || echo "   ⚠️  SketchyBar failed to start"
    brew services restart borders 2>/dev/null && echo "   ✅ Borders started" || echo "   ⚠️  Borders failed to start"
}

stop_services() {
    echo ""
    echo "🛑 Stopping services..."

    brew services stop sketchybar 2>/dev/null && echo "   ✅ SketchyBar stopped" || true
    brew services stop borders 2>/dev/null && echo "   ✅ Borders stopped" || true
}

do_install() {
    print_header
    echo "📥 Installing Cyberpunk dotfiles..."

    install_deps
    backup_configs
    create_symlinks
    set_permissions
    start_services

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
}

do_uninstall() {
    print_header
    echo "🗑️  Uninstalling Cyberpunk dotfiles..."

    stop_services

    echo ""
    echo "🔗 Removing symlinks..."

    [ -L "$HOME/.config/sketchybar" ] && rm "$HOME/.config/sketchybar" && echo "   ✅ Removed sketchybar symlink"
    [ -L "$HOME/.config/borders" ] && rm "$HOME/.config/borders" && echo "   ✅ Removed borders symlink"
    [ -L "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml" && echo "   ✅ Removed .aerospace.toml symlink"
    [ -L "$HOME/.wezterm.lua" ] && rm "$HOME/.wezterm.lua" && echo "   ✅ Removed .wezterm.lua symlink"

    echo ""
    echo "✅ Uninstall complete!"
    echo ""
    echo "💡 To restore from backup, run: ./install.sh restore"
    echo "💡 Backups are stored in: $BACKUP_BASE"
}

do_restore() {
    print_header
    echo "🔄 Restore from backup..."

    if [ ! -d "$BACKUP_BASE" ]; then
        echo "❌ No backups found at $BACKUP_BASE"
        exit 1
    fi

    echo ""
    echo "Available backups:"
    echo ""

    BACKUPS=($(ls -1 "$BACKUP_BASE" 2>/dev/null | sort -r))

    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo "❌ No backups found"
        exit 1
    fi

    for i in "${!BACKUPS[@]}"; do
        BACKUP_DATE=$(echo "${BACKUPS[$i]}" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
        echo "  [$i] $BACKUP_DATE"
        ls -1 "$BACKUP_BASE/${BACKUPS[$i]}" 2>/dev/null | sed 's/^/      - /'
    done

    echo ""
    read -p "Select backup to restore [0]: " SELECTION
    SELECTION=${SELECTION:-0}

    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -ge ${#BACKUPS[@]} ]; then
        echo "❌ Invalid selection"
        exit 1
    fi

    RESTORE_DIR="$BACKUP_BASE/${BACKUPS[$SELECTION]}"

    echo ""
    echo "🔄 Restoring from: ${BACKUPS[$SELECTION]}"

    stop_services

    # Remove current symlinks
    [ -L "$HOME/.config/sketchybar" ] && rm "$HOME/.config/sketchybar"
    [ -L "$HOME/.config/borders" ] && rm "$HOME/.config/borders"
    [ -L "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml"
    [ -L "$HOME/.wezterm.lua" ] && rm "$HOME/.wezterm.lua"

    # Restore from backup
    [ -d "$RESTORE_DIR/sketchybar" ] && cp -r "$RESTORE_DIR/sketchybar" "$HOME/.config/" && echo "   ✅ Restored sketchybar"
    [ -d "$RESTORE_DIR/borders" ] && cp -r "$RESTORE_DIR/borders" "$HOME/.config/" && echo "   ✅ Restored borders"
    [ -f "$RESTORE_DIR/.aerospace.toml" ] && cp "$RESTORE_DIR/.aerospace.toml" "$HOME/" && echo "   ✅ Restored .aerospace.toml"
    [ -f "$RESTORE_DIR/.wezterm.lua" ] && cp "$RESTORE_DIR/.wezterm.lua" "$HOME/" && echo "   ✅ Restored .wezterm.lua"

    start_services

    echo ""
    echo "✅ Restore complete!"
}

show_help() {
    print_header
    echo "Usage: ./install.sh [command]"
    echo ""
    echo "Commands:"
    echo "  install     Install dotfiles (default)"
    echo "  uninstall   Remove symlinks and stop services"
    echo "  restore     Restore from a previous backup"
    echo "  help        Show this help message"
    echo ""
    echo "Backup location: $BACKUP_BASE"
}

# Main
case "${1:-install}" in
    install)
        do_install
        ;;
    uninstall)
        do_uninstall
        ;;
    restore)
        do_restore
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
