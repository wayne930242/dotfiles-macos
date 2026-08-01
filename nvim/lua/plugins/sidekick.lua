return {
  "folke/sidekick.nvim",
  opts = {
    nes = { enabled = false },
    cli = {
      mux = { enabled = false },
      tools = {
        codex = {
          cmd = { "codex", "--dangerously-bypass-approvals-and-sandbox" },
          -- never adopt codex processes running elsewhere (e.g. other tmux panes)
          is_proc = function()
            return false
          end,
        },
        claude = {
          cmd = { "claude", "--dangerously-skip-permissions" },
          -- the zsh `claude` wrapper sets this; sidekick runs the binary directly
          env = { FORCE_COLOR = "3" },
          -- never adopt claude processes running elsewhere (e.g. Zed's tmux panes)
          is_proc = function()
            return false
          end,
        },
      },
    },
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("sidekick.cli").select({ filter = { attached = true }, focus = true })
      end,
      desc = "Select Running AI Agent",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select({ filter = { installed = true } })
      end,
      desc = "Select AI CLI",
    },
    {
      "<leader>ax",
      function()
        require("sidekick.cli").toggle({ name = "codex", focus = true })
      end,
      desc = "Toggle Codex Agent",
    },
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Toggle Claude Agent",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Close AI Agent",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send Current File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = "x",
      desc = "Send Visual Selection",
    },
    {
      "<C-.>",
      function()
        require("sidekick.cli").focus()
      end,
      mode = { "n", "t", "i", "x" },
      desc = "Focus AI CLI",
    },
  },
}
