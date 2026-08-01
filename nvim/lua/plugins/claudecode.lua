return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  -- eager-load so the WebSocket/lock-file server is already running before
  -- `/ide` is run inside the sidekick terminal; no `keys`/`cmd` here since
  -- sidekick.nvim already owns the terminal toggle and <leader>a* keymaps
  lazy = false,
  opts = {},
}
