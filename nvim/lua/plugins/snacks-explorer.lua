return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          -- include 優先於 hidden/ignored/exclude,用來放行被 .gitignore
          -- 擋掉的 .env*,又不必開 ignored 讓 node_modules 灌進側欄
          include = { ".env*" },
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
