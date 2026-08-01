-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

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
