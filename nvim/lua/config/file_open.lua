local M = {}

local function getMimeType(path)
  local result = vim.system({ "file", "--brief", "--mime-type", "--", path }, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end

  return vim.trim(result.stdout or "")
end

function M.openImage(path)
  if not vim.startswith(getMimeType(path) or "", "image/") then
    return false
  end

  if vim.fn.executable("chafa") ~= 1 then
    vim.notify("Chafa is required to open images", vim.log.levels.ERROR)
    return true
  end

  local width = math.max(math.floor(vim.o.columns * 0.9), 20)
  local height = math.max(math.floor((vim.o.lines - vim.o.cmdheight) * 0.9), 10)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[buffer].bufhidden = "wipe"
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = (" Image: %s "):format(vim.fn.fnamemodify(path, ":t")),
    title_pos = "center",
  })

  local function closeViewer()
    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end
  end

  vim.keymap.set("n", "q", closeViewer, { buffer = buffer, silent = true, nowait = true })
  vim.keymap.set("n", "<Esc>", closeViewer, { buffer = buffer, silent = true })

  local job = vim.fn.jobstart({ "chafa", "--format", "symbols", "--size", ("%dx%d"):format(width, height), path }, {
    term = true,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify(("Chafa failed to open `%s`"):format(path), vim.log.levels.ERROR)
        end)
      end
    end,
  })

  if job <= 0 then
    closeViewer()
    vim.notify("Failed to start Chafa", vim.log.levels.ERROR)
  end

  return true
end

return M
