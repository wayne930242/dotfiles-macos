local M = {}

local function git(path, ...)
  local cmd = { "git", "-C", path }
  vim.list_extend(cmd, { ... })
  return vim.system(cmd, { text = true }):wait()
end

local function error_message(result, fallback)
  local message = vim.trim(result.stderr or "")
  return message ~= "" and message or fallback
end

function M.outermost_root(path)
  path = vim.fs.normalize(path or vim.fn.getcwd(0))

  local result = git(path, "rev-parse", "--show-toplevel")
  if result.code ~= 0 then
    return nil, error_message(result, "Not inside a Git repository")
  end

  local root = vim.fs.normalize(vim.trim(result.stdout or ""))
  while true do
    result = git(root, "rev-parse", "--show-superproject-working-tree")
    if result.code ~= 0 then
      return nil, error_message(result, "Failed to resolve the superproject")
    end

    local parent = vim.trim(result.stdout or "")
    if parent == "" then
      return root
    end

    parent = vim.fs.normalize(parent)
    if parent == root then
      return root
    end
    root = parent
  end
end

function M.repositories(path)
  local root, err = M.outermost_root(path)
  if not root then
    return nil, err
  end

  local result = git(root, "submodule", "foreach", "--recursive", "--quiet", [[printf '%s\0' "$toplevel/$sm_path"]])
  if result.code ~= 0 then
    return nil, error_message(result, "Failed to enumerate Git submodules")
  end

  local repositories = { root }
  local seen = { [root] = true }
  for _, repository in ipairs(vim.split(result.stdout or "", "\0", { plain = true, trimempty = true })) do
    repository = vim.fs.normalize(repository)
    if not seen[repository] then
      seen[repository] = true
      repositories[#repositories + 1] = repository
    end
  end
  return repositories
end

local function finder(repositories, root)
  return function(_, ctx)
    return function(cb)
      for _, cwd in ipairs(repositories) do
        local result
        local process = vim.system({
          "git",
          "-c",
          "core.quotepath=false",
          "--no-pager",
          "status",
          "-uall",
          "--porcelain=v1",
          "-z",
          "--ignore-submodules=dirty",
        }, { cwd = cwd }, function(value)
          result = value
          ctx.async:resume()
        end)

        ctx.async:on("abort", function()
          pcall(process.kill, process, 15)
        end)
        while not result do
          ctx.async:suspend()
        end

        if result.code ~= 0 then
          Snacks.notify.error(error_message(result, "Failed to read Git status for " .. cwd), { title = "Git Status" })
        else
          local previous
          for _, record in ipairs(vim.split(result.stdout or "", "\0", { plain = true, trimempty = true })) do
            local status, file = record:match("^(..) (.+)$")
            if status then
              if previous then
                cb(previous)
              end
              previous = {
                cwd = cwd,
                status = status,
                file = file,
                text = vim.fs.relpath(root, cwd .. "/" .. file) or file,
              }
            elseif previous and previous.status:find("R", 1, true) then
              previous.rename = record
            end
          end
          if previous then
            cb(previous)
          end
        end

        if ctx.async:aborted() then
          return
        end
      end
    end
  end
end

function M.open(opts)
  opts = opts or {}
  local repositories, err = M.repositories(opts.cwd or vim.fn.getcwd(0))
  if not repositories then
    Snacks.notify.error(err, { title = "Git Status" })
    return
  end

  local root = repositories[1]
  return Snacks.picker.pick({
    title = "Git Status (All Repositories)",
    cwd = root,
    finder = finder(repositories, root),
    format = "git_status",
    preview = "git_status",
    confirm = "jump",
    show_empty = true,
    win = {
      input = {
        keys = {
          ["<Tab>"] = { "git_stage", mode = { "n", "i" } },
          ["<C-r>"] = { "git_restore", mode = { "n", "i" }, nowait = true },
        },
      },
    },
  })
end

return M
