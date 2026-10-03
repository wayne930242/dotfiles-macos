#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GHOSTTY_CONFIG="$PROJECT_DIR/ghostty/config"
HERDR_CONFIG="$PROJECT_DIR/herdr/config.toml"
LAZY_CONFIG="$PROJECT_DIR/nvim/lua/config/lazy.lua"
COLORSCHEME_CONFIG="$PROJECT_DIR/nvim/lua/plugins/colorscheme.lua"
SKETCHYBAR_DIR="$PROJECT_DIR/sketchybar"
BORDERS_DIR="$PROJECT_DIR/borders"

assert_contains() {
    local file="$1"
    local expected="$2"

    if [ ! -f "$file" ] || ! grep -Fq "$expected" "$file"; then
        echo "FAIL: expected '$expected' in $file" >&2
        return 1
    fi
}

check_ghostty() {
    assert_contains "$GHOSTTY_CONFIG" 'theme = "Catppuccin Mocha"'
}

check_herdr() {
    assert_contains "$HERDR_CONFIG" 'name = "catppuccin"'
}

check_lazyvim() {
    assert_contains "$COLORSCHEME_CONFIG" 'colorscheme = "catppuccin-mocha"'
    assert_contains "$LAZY_CONFIG" 'install = { colorscheme = { "catppuccin-mocha", "habamax" } }'
}

check_sketchybar() {
    assert_contains "$SKETCHYBAR_DIR/colors.sh" 'THEME="catppuccin-mocha"'
    assert_contains "$SKETCHYBAR_DIR/themes/catppuccin-mocha.sh" 'MOCHA_BASE=1e1e2e'
    assert_contains "$SKETCHYBAR_DIR/themes/cyberpunk.sh" 'export CYAN=0xff00fff7'

    # Colors come only from the theme files, never hard-coded in items or plugins
    local hardcoded
    hardcoded=$(grep -rnE '0x[0-9a-fA-F]{8}' "$SKETCHYBAR_DIR/items" "$SKETCHYBAR_DIR/plugins" "$SKETCHYBAR_DIR/sketchybarrc" || true)
    if [ -n "$hardcoded" ]; then
        echo "FAIL: hard-coded colors outside sketchybar/themes:" >&2
        echo "$hardcoded" >&2
        return 1
    fi
}

check_borders() {
    assert_contains "$BORDERS_DIR/bordersrc" 'THEME="catppuccin-mocha"'
    assert_contains "$BORDERS_DIR/themes/catppuccin-mocha.sh" 'BORDER_ACTIVE_COLOR='
    assert_contains "$BORDERS_DIR/themes/cyberpunk.sh" 'BORDER_ACTIVE_COLOR=0xff00fff7'
}

target="${1:-all}"

case "$target" in
    ghostty) check_ghostty ;;
    herdr) check_herdr ;;
    lazyvim) check_lazyvim ;;
    sketchybar) check_sketchybar ;;
    borders) check_borders ;;
    all)
        check_ghostty
        check_herdr
        check_lazyvim
        check_sketchybar
        check_borders
        ;;
    *)
        echo "usage: $0 [ghostty|herdr|lazyvim|sketchybar|borders|all]" >&2
        exit 2
        ;;
esac

echo "PASS: $target Catppuccin Mocha theme contract"
