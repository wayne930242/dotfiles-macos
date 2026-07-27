return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    {
      "<leader>-",
      mode = { "n", "v" },
      function()
        vim.fn.jobstart({ "open", "-R", vim.fn.expand("%:p") }, { detach = true })
      end,
      desc = "Reveal current file in Finder",
    },
    { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open the file manager in nvim's working directory" },
    { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume the last yazi session" },
  },
  opts = {
    open_for_directories = false,
    keymaps = { show_help = "<f1>" },
  },
}
