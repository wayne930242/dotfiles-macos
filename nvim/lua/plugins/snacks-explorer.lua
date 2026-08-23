return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>gR",
      function()
        require("config.git_status").open()
      end,
      desc = "Git Status (All Repositories)",
    },
  },
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          git_status_open = true,
          -- include 優先於 hidden/ignored/exclude,用來放行被 .gitignore
          -- 擋掉的密碼/密鑰類檔案,又不必開 ignored 讓 node_modules 灌進側欄
          include = { ".env*", ".vault_pass", ".secrets/**", ".token-override", "*.pem", "*.key" },
          actions = {
            explorer_yazi = function(_, item)
              if item then
                require("yazi").yazi(nil, Snacks.picker.util.path(item))
              end
            end,
          },
          win = {
            list = {
              keys = {
                ["o"] = "confirm",
                ["<CR>"] = "explorer_yazi",
              },
            },
          },
        },
      },
    },
  },
}
