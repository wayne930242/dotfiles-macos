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
    brew install --cask hammerspoon 2>/dev/null || echo "   Hammerspoon already installed or skipped"
    brew install sketchybar 2>/dev/null || echo "   SketchyBar already installed or skipped"
    brew install borders 2>/dev/null || echo "   Borders already installed or skipped"
    brew install nowplaying-cli 2>/dev/null || echo "   nowplaying-cli already installed or skipped"
    brew install neovim 2>/dev/null || echo "   Neovim already installed or skipped"
    brew install yazi 2>/dev/null || echo "   Yazi already installed or skipped"
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

    if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        cp -r "$HOME/.config/nvim" "$BACKUP_DIR/"
        echo "   ✅ Backed up nvim"
    fi

    if [ -f "$HOME/.aerospace.toml" ] && [ ! -L "$HOME/.aerospace.toml" ]; then
        cp "$HOME/.aerospace.toml" "$BACKUP_DIR/"
        echo "   ✅ Backed up .aerospace.toml"
    fi

    if [ -d "$HOME/.hammerspoon" ] && [ ! -L "$HOME/.hammerspoon" ]; then
        cp -r "$HOME/.hammerspoon" "$BACKUP_DIR/"
        echo "   ✅ Backed up .hammerspoon"
    fi

    if [ -d "$HOME/.config/ghostty" ] && [ ! -L "$HOME/.config/ghostty" ]; then
        cp -r "$HOME/.config/ghostty" "$BACKUP_DIR/"
        echo "   ✅ Backed up ghostty"
    fi

    if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$BACKUP_DIR/"
        echo "   ✅ Backed up .tmux.conf"
    fi

    if [ -f "$HOME/.config/herdr/config.toml" ] && [ ! -L "$HOME/.config/herdr/config.toml" ]; then
        mkdir -p "$BACKUP_DIR/herdr"
        cp "$HOME/.config/herdr/config.toml" "$BACKUP_DIR/herdr/"
        echo "   ✅ Backed up herdr config.toml"
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
    [ -L "$HOME/.config/nvim" ] && rm "$HOME/.config/nvim"
    [ -L "$HOME/.config/ghostty" ] && rm "$HOME/.config/ghostty"
    [ -L "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml"
    [ -L "$HOME/.tmux.conf" ] && rm "$HOME/.tmux.conf"
    [ -L "$HOME/.hammerspoon" ] && rm "$HOME/.hammerspoon"
    [ -L "$HOME/.config/herdr/config.toml" ] && rm "$HOME/.config/herdr/config.toml"
    [ -d "$HOME/.config/sketchybar" ] && rm -rf "$HOME/.config/sketchybar"
    [ -d "$HOME/.config/borders" ] && rm -rf "$HOME/.config/borders"
    [ -d "$HOME/.config/nvim" ] && rm -rf "$HOME/.config/nvim"
    [ -d "$HOME/.config/ghostty" ] && rm -rf "$HOME/.config/ghostty"
    [ -d "$HOME/.hammerspoon" ] && rm -rf "$HOME/.hammerspoon"
    [ -f "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml"
    [ -f "$HOME/.tmux.conf" ] && rm "$HOME/.tmux.conf"
    [ -f "$HOME/.config/herdr/config.toml" ] && rm "$HOME/.config/herdr/config.toml"

    ln -sf "$DOTFILES_DIR/sketchybar" "$HOME/.config/sketchybar"
    ln -sf "$DOTFILES_DIR/borders" "$HOME/.config/borders"
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    ln -sf "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"
    ln -sf "$DOTFILES_DIR/.aerospace.toml" "$HOME/.aerospace.toml"
    ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
    ln -sf "$DOTFILES_DIR/hammerspoon" "$HOME/.hammerspoon"
    mkdir -p "$HOME/.config/herdr"
    ln -sf "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"

    echo "   ✅ sketchybar -> ~/.config/sketchybar"
    echo "   ✅ borders -> ~/.config/borders"
    echo "   ✅ nvim -> ~/.config/nvim"
    echo "   ✅ ghostty -> ~/.config/ghostty"
    echo "   ✅ .aerospace.toml -> ~/.aerospace.toml"
    echo "   ✅ .tmux.conf -> ~/.tmux.conf"
    echo "   ✅ hammerspoon -> ~/.hammerspoon"
    echo "   ✅ herdr config.toml -> ~/.config/herdr/config.toml"
}

set_permissions() {
    echo ""
    echo "🔧 Setting permissions..."

    chmod +x "$DOTFILES_DIR/sketchybar/sketchybarrc"
    chmod +x "$DOTFILES_DIR/borders/bordersrc"
    find "$DOTFILES_DIR/sketchybar" -name "*.sh" -exec chmod +x {} \;

    echo "   ✅ Permissions set"
}

restart_aerospace() {
    echo ""
    echo "🚀 Restarting AeroSpace..."

    if pgrep -x AeroSpace &>/dev/null; then
        osascript -e 'tell application "AeroSpace" to quit' 2>/dev/null || {
            echo "   ⚠️  AeroSpace could not be stopped"
            return 0
        }

        for ((restart_attempt = 0; restart_attempt < 20; restart_attempt++)); do
            pgrep -x AeroSpace &>/dev/null || break
            sleep 0.5
        done
    fi

    if ! open -a AeroSpace >/dev/null 2>&1; then
        echo "   ⚠️  AeroSpace could not be opened"
        return 0
    fi

    for ((readiness_attempt = 0; readiness_attempt < 30; readiness_attempt++)); do
        if aerospace list-modes &>/dev/null; then
            echo "   ✅ AeroSpace restarted"
            return 0
        fi
        sleep 0.5
    done

    echo "   ⚠️  AeroSpace started but its server is not responding"
}

start_services() {
    echo ""
    echo "🚀 Starting services..."

    brew services restart sketchybar 2>/dev/null && echo "   ✅ SketchyBar started" || echo "   ⚠️  SketchyBar failed to start"
    brew services restart borders 2>/dev/null && echo "   ✅ Borders started" || echo "   ⚠️  Borders failed to start"
    restart_aerospace
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
    echo "║  1. Grant accessibility permissions when prompted             ║"
    echo "║  2. Press alt+shift+; then esc to reload AeroSpace config     ║"
    echo "║  3. Open Hammerspoon once, grant Accessibility permission,    ║"
    echo "║     then enable 'Launch at Login' from its menu bar icon      ║"
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
    [ -L "$HOME/.config/nvim" ] && rm "$HOME/.config/nvim" && echo "   ✅ Removed nvim symlink"
    [ -L "$HOME/.config/ghostty" ] && rm "$HOME/.config/ghostty" && echo "   ✅ Removed ghostty symlink"
    [ -L "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml" && echo "   ✅ Removed .aerospace.toml symlink"
    [ -L "$HOME/.tmux.conf" ] && rm "$HOME/.tmux.conf" && echo "   ✅ Removed .tmux.conf symlink"
    [ -L "$HOME/.hammerspoon" ] && rm "$HOME/.hammerspoon" && echo "   ✅ Removed hammerspoon symlink"
    [ -L "$HOME/.config/herdr/config.toml" ] && rm "$HOME/.config/herdr/config.toml" && echo "   ✅ Removed herdr config.toml symlink"

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
    [ -L "$HOME/.config/nvim" ] && rm "$HOME/.config/nvim"
    [ -L "$HOME/.config/ghostty" ] && rm "$HOME/.config/ghostty"
    [ -L "$HOME/.aerospace.toml" ] && rm "$HOME/.aerospace.toml"
    [ -L "$HOME/.tmux.conf" ] && rm "$HOME/.tmux.conf"
    [ -L "$HOME/.hammerspoon" ] && rm "$HOME/.hammerspoon"
    [ -L "$HOME/.config/herdr/config.toml" ] && rm "$HOME/.config/herdr/config.toml"

    # Restore from backup
    [ -d "$RESTORE_DIR/sketchybar" ] && cp -r "$RESTORE_DIR/sketchybar" "$HOME/.config/" && echo "   ✅ Restored sketchybar"
    [ -d "$RESTORE_DIR/borders" ] && cp -r "$RESTORE_DIR/borders" "$HOME/.config/" && echo "   ✅ Restored borders"
    [ -d "$RESTORE_DIR/nvim" ] && cp -r "$RESTORE_DIR/nvim" "$HOME/.config/" && echo "   ✅ Restored nvim"
    [ -d "$RESTORE_DIR/ghostty" ] && cp -r "$RESTORE_DIR/ghostty" "$HOME/.config/" && echo "   ✅ Restored ghostty"
    [ -d "$RESTORE_DIR/.hammerspoon" ] && cp -r "$RESTORE_DIR/.hammerspoon" "$HOME/" && echo "   ✅ Restored .hammerspoon"
    [ -f "$RESTORE_DIR/.aerospace.toml" ] && cp "$RESTORE_DIR/.aerospace.toml" "$HOME/" && echo "   ✅ Restored .aerospace.toml"
    [ -f "$RESTORE_DIR/.tmux.conf" ] && cp "$RESTORE_DIR/.tmux.conf" "$HOME/" && echo "   ✅ Restored .tmux.conf"
    [ -f "$RESTORE_DIR/herdr/config.toml" ] && mkdir -p "$HOME/.config/herdr" && cp "$RESTORE_DIR/herdr/config.toml" "$HOME/.config/herdr/" && echo "   ✅ Restored herdr config.toml"

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
