-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 拼字檢查跳過 CJK 字元，中文不再被標紅線（英文照常檢查）
vim.opt.spelllang = { "en", "cjk" }

-- linebreak 折行點移除 "-"，避免 "Why-啟發法" 這類詞在連字號後被切開
vim.opt.breakat = " \t!@*+;:,./?"
