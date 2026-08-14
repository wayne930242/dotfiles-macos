-- nvim window 間的 CTRL+h/j/k/l 導航 (Ghostty pane 切換另外轉發給 tmux 用 CMD+hjkl，鍵位不重疊)
-- CTRL+h/j/k/l 的實際 keymap 註冊在 config/keymaps.lua，不是這裡的 keys 表——
-- LazyVim 內建也無條件綁了同一組鍵 (lazyvim.config.keymaps)，兩邊註冊點的載入順序
-- 沒有保證，寫在 plugin spec 的 keys 表裡不保證贏過 LazyVim 預設；只有 config/keymaps.lua
-- 保證在 LazyVim 預設之後載入、能穩定覆蓋掉它
return {
  "mrjones2014/smart-splits.nvim",
  version = ">=1.0.0",
  lazy = false,
}
