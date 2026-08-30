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
          finder = function(opts, ctx)
            return require("config.explorer_git").finder(opts, ctx)
          end,
          transform = function(item)
            return require("config.explorer_git").transform(item)
          end,
          -- include 優先於 hidden/ignored/exclude,用來放行被 .gitignore
          -- 擋掉的密碼/密鑰類檔案,又不必開 ignored 讓 node_modules 灌進側欄
          include = { ".env*", ".vault_pass", ".secrets/**", ".token-override", "*.pem", "*.key" },
          actions = {
            explorer_yazi = function(_, item)
              if item then
                require("yazi").yazi(nil, Snacks.picker.util.path(item))
              end
            end,
            open_image_or_confirm = function(picker, item, action)
              local path = item and Snacks.picker.util.path(item)
              if path and require("config.file_open").openImage(path) then
                return
              end

              require("snacks.explorer.actions").actions.confirm(picker, item, action)
            end,
          },
          win = {
            list = {
              keys = {
                ["o"] = "open_image_or_confirm",
                ["<2-LeftMouse>"] = "open_image_or_confirm",
                ["<CR>"] = "explorer_yazi",
              },
            },
          },
        },
      },
    },
  },
}
