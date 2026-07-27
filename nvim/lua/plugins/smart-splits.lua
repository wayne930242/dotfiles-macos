-- wezterm 無縫 pane 導航：CTRL+h/j/k/l 通吃 nvim window 與 wezterm pane
-- 官方建議不要 lazy-load（需在啟動時設定 IS_NVIM user var 供 wezterm 偵測）
return {
  "mrjones2014/smart-splits.nvim",
  version = ">=1.0.0",
  lazy = false,
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move to left split" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move to below split" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move to above split" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
  },
}
