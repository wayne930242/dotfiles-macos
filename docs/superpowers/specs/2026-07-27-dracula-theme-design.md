# Dracula Theme Design

## Goal

Apply the standard Dracula palette to WezTerm and LazyVim without changing their navigation, layout, or plugin behavior.

## WezTerm

- Set `color_scheme` to WezTerm's built-in `Dracula (Official)` scheme.
- Remove window opacity and macOS background blur so Dracula's `#282a36` background renders without desktop blending.
- Change the LEADER indicator to Dracula orange (`#ffb86c`) on Dracula background (`#282a36`).
- Preserve fonts, padding, tab layout, mux behavior, and key bindings.

## LazyVim

- Add `Mofiqul/dracula.nvim` in a dedicated `colorscheme.lua` plugin spec.
- Configure `LazyVim/LazyVim` to load the standard `dracula` colorscheme.
- Prefer `dracula` during lazy.nvim bootstrap and keep `habamax` as the fallback.
- Update `lazy-lock.json` with the installed Dracula plugin revision.
- Keep existing editor options and plugin configuration unchanged.

## Verification

- Load `.wezterm.lua` with the installed WezTerm binary and confirm the configuration has no errors.
- Start Neovim headlessly and assert that `vim.g.colors_name` equals `dracula`.
- Validate all changed Lua and JSON files and run `git diff --check`.

## Exclusions

This change does not alter SketchyBar, AeroSpace, Borders, tmux, or application-specific themes outside WezTerm and LazyVim.
