-- LazyVim 內建的 persistence.nvim(<leader>qs/ql/qS/qd)已經會存 buffer 和
-- 視窗版面,這裡補兩塊它原生沒做的:
--
-- 1. 開 nvim 沒帶檔名參數時自動載入該目錄上次的 session,不用手動按鍵。
--
-- 2. Snacks explorer 側欄的視窗(buftype=nofile 的 snacks_layout_box,外加
--    疊在上面的浮動清單/輸入框)不在目前的 sessionoptions 範圍內,
--    :mksession 會直接跳過整個側欄,不會復原。讀檔後用 Snacks.explorer()
--    重新開一個。
return {
  "folke/persistence.nvim",
  init = function()
    local stdin_used = false
    vim.api.nvim_create_autocmd("StdinReadPre", {
      once = true,
      callback = function()
        stdin_used = true
      end,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
      nested = true,
      callback = function()
        if vim.fn.argc(-1) == 0 and not stdin_used then
          require("persistence").load()
        end
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistenceLoadPost",
      callback = function()
        Snacks.explorer()
      end,
    })
  end,
}
