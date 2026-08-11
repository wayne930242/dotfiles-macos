-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- smart-splits.nvim window 導航：覆蓋 LazyVim 預設的 <C-h/j/k/l> (<C-w>h 那組)。
-- 必須寫在這裡而非 plugin spec 的 keys 表——LazyVim 自己的預設鍵也是在這個
-- VeryLazy 階段設的，兩邊註冊順序沒保證，只有這裡能確定在 LazyVim 預設之後執行
vim.keymap.set("n", "<C-h>", function() require("smart-splits").move_cursor_left() end, { desc = "Move to left split" })
vim.keymap.set("n", "<C-j>", function() require("smart-splits").move_cursor_down() end, { desc = "Move to below split" })
vim.keymap.set("n", "<C-k>", function() require("smart-splits").move_cursor_up() end, { desc = "Move to above split" })
vim.keymap.set("n", "<C-l>", function() require("smart-splits").move_cursor_right() end, { desc = "Move to right split" })

-- 中文段落開 linebreak 會在行尾留大片空白:breakat 只認 ASCII,
-- 整串中文被當成一個單字,塞不下就整團換行。關掉改成逐欄折行,
-- 中文折得滿,代價是英文可能被切開。逐視窗切換,配合 <leader>uw (wrap)。
Snacks.toggle.option("linebreak", { name = "Line Break" }):map("<leader>uW")

vim.keymap.set("n", "<leader>yp", function()
  vim.fn.setreg("+", vim.fn.expand("%:."))
end, { desc = "Yank relative path" })

vim.keymap.set("n", "<leader>yP", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Yank absolute path" })
