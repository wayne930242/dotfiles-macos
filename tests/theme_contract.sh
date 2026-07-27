#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEZTERM_CONFIG="$PROJECT_DIR/.wezterm.lua"
LAZY_CONFIG="$PROJECT_DIR/nvim/lua/config/lazy.lua"
COLORSCHEME_CONFIG="$PROJECT_DIR/nvim/lua/plugins/colorscheme.lua"

assert_contains() {
    local file="$1"
    local expected="$2"

    if [ ! -f "$file" ] || ! grep -Fq "$expected" "$file"; then
        echo "FAIL: expected '$expected' in $file" >&2
        return 1
    fi
}

assert_absent() {
    local file="$1"
    local unexpected="$2"

    if grep -Fq "$unexpected" "$file"; then
        echo "FAIL: unexpected '$unexpected' in $file" >&2
        return 1
    fi
}

check_wezterm() {
    assert_contains "$WEZTERM_CONFIG" 'config.color_scheme = "Dracula (Official)"'
    # 只斷言色碼本身，不綁 `Color = ` 前綴：色碼可能出現在共用 badge helper
    # 的參數位置而非 wezterm.format 字面表格內，綁前綴會讓純重構誤報 FAIL
    assert_contains "$WEZTERM_CONFIG" '"#ffb86c"'
    assert_contains "$WEZTERM_CONFIG" '"#282a36"'
    assert_absent "$WEZTERM_CONFIG" 'config.window_background_opacity'
    assert_absent "$WEZTERM_CONFIG" 'config.macos_window_background_blur'
}

check_lazyvim() {
    assert_contains "$COLORSCHEME_CONFIG" '"Mofiqul/dracula.nvim"'
    assert_contains "$COLORSCHEME_CONFIG" 'colorscheme = "dracula"'
    assert_contains "$LAZY_CONFIG" 'install = { colorscheme = { "dracula", "habamax" } }'
}

target="${1:-all}"

case "$target" in
    wezterm)
        check_wezterm
        ;;
    lazyvim)
        check_lazyvim
        ;;
    all)
        check_wezterm
        check_lazyvim
        ;;
    *)
        echo "usage: $0 [wezterm|lazyvim|all]" >&2
        exit 2
        ;;
esac

echo "PASS: $target Dracula theme contract"
