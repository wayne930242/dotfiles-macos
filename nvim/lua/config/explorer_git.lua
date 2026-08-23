local M = {
  branches = {},
  pending = {},
}

local CACHE_TTL = 15 * 60

local function error_message(result, fallback)
  local message = vim.trim(result.stderr or "")
  return message ~= "" and message or fallback
end

local function branch_badge(header)
  local ahead = tonumber(header:match("ahead (%d+)"))
  local behind = tonumber(header:match("behind (%d+)"))
  local parts = {}
  if ahead then
    parts[#parts + 1] = "↑" .. ahead
  end
  if behind then
    parts[#parts + 1] = "↓" .. behind
  end
  return #parts > 0 and table.concat(parts, " ") or nil
end

local function parse_status(cwd, output)
  local results = {}
  local branch
  local skip_rename_source = false

  for _, record in ipairs(vim.split(output or "", "\0", { plain = true, trimempty = true })) do
    if record:sub(1, 3) == "## " then
      branch = branch_badge(record)
    elseif skip_rename_source then
      skip_rename_source = false
    else
      local status, file = record:match("^(..) (.+)$")
      if status then
        results[#results + 1] = {
          status = status,
          file = cwd .. "/" .. file,
        }
        skip_rename_source = status:find("R", 1, true) ~= nil or status:find("C", 1, true) ~= nil
      end
    end
  end

  return results, branch
end

local function status_command(untracked)
  return {
    "git",
    "-c",
    "core.quotepath=false",
    "--no-pager",
    "--no-optional-locks",
    "status",
    "--porcelain=v1",
    "--branch",
    "--ignored=matching",
    "-z",
    untracked and "-unormal" or "-uno",
    "--ignore-submodules=dirty",
  }
end

local function notify_error(repository, result)
  Snacks.notify.warn(error_message(result, "Failed to read Git status for " .. repository), {
    title = "Explorer Git Status",
  })
end

function M.update(cwd, opts)
  opts = opts or {}
  local repositories, err = require("config.git_status").repositories(cwd)
  if not repositories then
    Snacks.notify.warn(err, { title = "Explorer Git Status" })
    return
  end

  local root = repositories[1]
  local Git = require("snacks.explorer.git")
  local now = os.time()
  local ttl = opts.force and 0 or opts.ttl or CACHE_TTL
  Git.state[root] = Git.state[root] or { tick = 0, last = 0 }
  local state = Git.state[root]

  if M.pending[root] then
    if opts.on_update then
      M.pending[root][#M.pending[root] + 1] = opts.on_update
    end
    return
  end
  if now - state.last < ttl then
    return
  end

  state.last = now
  state.tick = state.tick + 1
  local tick = state.tick
  local remaining = #repositories
  local results = {}
  local branches = {}
  M.pending[root] = opts.on_update and { opts.on_update } or {}

  local function finish()
    if state.tick == tick then
      Git._update(root, results)
      M.branches[root] = branches
    end
    local callbacks = M.pending[root] or {}
    M.pending[root] = nil
    for _, callback in ipairs(callbacks) do
      callback()
    end
  end

  for _, repository in ipairs(repositories) do
    vim.system(status_command(opts.untracked), { cwd = repository }, function(result)
      vim.schedule(function()
        if result.code == 0 then
          local repo_results, branch = parse_status(repository, result.stdout)
          vim.list_extend(results, repo_results)
          if branch then
            branches[vim.fs.normalize(repository)] = branch
          end
        else
          notify_error(repository, result)
        end

        remaining = remaining - 1
        if remaining == 0 then
          finish()
        end
      end)
    end)
  end
end

function M.finder(opts, ctx)
  local source_opts = Snacks.picker.util.shallow_copy(opts)
  source_opts.git_status = false
  local finder = require("snacks.picker.source.explorer").explorer(source_opts, ctx)

  if opts.git_status and ctx.filter:is_empty() then
    M.update(ctx.filter.cwd, {
      untracked = opts.git_untracked,
      on_update = function()
        if ctx.picker.closed then
          return
        end
        ctx.picker.list:set_target()
        ctx.picker:find()
      end,
    })
  end

  return finder
end

function M.transform(item)
  local path = item.file and vim.fs.normalize(item.file)
  if not path then
    return item
  end

  for _, branches in pairs(M.branches) do
    local badge = branches[path]
    if badge then
      item.comment = item.comment and (item.comment .. " " .. badge) or badge
      break
    end
  end
  return item
end

return M
