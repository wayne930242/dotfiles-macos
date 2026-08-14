#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GHOSTTY_CONFIG="$PROJECT_DIR/ghostty/config"
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

check_ghostty() {
    assert_contains "$GHOSTTY_CONFIG" 'theme = "Dracula"'
}

check_lazyvim() {
    assert_contains "$COLORSCHEME_CONFIG" '"Mofiqul/dracula.nvim"'
    assert_contains "$COLORSCHEME_CONFIG" 'colorscheme = "dracula"'
    assert_contains "$LAZY_CONFIG" 'install = { colorscheme = { "dracula", "habamax" } }'
}

target="${1:-all}"

case "$target" in
    ghostty)
        check_ghostty
        ;;
    lazyvim)
        check_lazyvim
        ;;
    all)
        check_ghostty
        check_lazyvim
        ;;
    *)
        echo "usage: $0 [ghostty|lazyvim|all]" >&2
        exit 2
        ;;
esac

echo "PASS: $target Dracula theme contract"
