-- scrolloff=999 only centers the cursor when there's real buffer content
-- above/below to scroll into; pad both ends with virtual blank lines so
-- centering still holds at the top/bottom of the file.
local pad_ns = vim.api.nvim_create_namespace("zen_scroll_pad")

local function blank_lines(n)
  local lines = {}
  for _ = 1, n do
    lines[#lines + 1] = { { "", "Normal" } }
  end
  return lines
end

local function pad_buffer(win)
  if not (vim.api.nvim_win_is_valid(win.win) and vim.api.nvim_buf_is_valid(win.buf)) then
    return
  end
  vim.api.nvim_buf_clear_namespace(win.buf, pad_ns, 0, -1)
  local pad = blank_lines(vim.api.nvim_win_get_height(win.win))
  local last_line = vim.api.nvim_buf_line_count(win.buf) - 1
  vim.api.nvim_buf_set_extmark(win.buf, pad_ns, 0, 0, { virt_lines = pad, virt_lines_above = true })
  vim.api.nvim_buf_set_extmark(win.buf, pad_ns, last_line, 0, { virt_lines = pad })
end

return {
  "folke/snacks.nvim",
  opts = {
    zen = {
      on_open = function(win)
        vim.wo.scrolloff = 999
        pad_buffer(win)
        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
          group = win.augroup,
          buffer = win.buf,
          callback = function()
            pad_buffer(win)
          end,
        })
      end,
      on_close = function(win)
        if vim.api.nvim_buf_is_valid(win.buf) then
          vim.api.nvim_buf_clear_namespace(win.buf, pad_ns, 0, -1)
        end
      end,
    },
    styles = {
      zen = {
        backdrop = { blend = 15 },
      },
    },
    -- affects smooth-scroll everywhere, not just zen mode:
    -- Snacks.scroll has no per-buffer animation config.
    scroll = {
      animate = {
        duration = { step = 15, total = 250 },
        easing = "outQuad",
      },
    },
  },
}
