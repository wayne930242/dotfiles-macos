return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
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
