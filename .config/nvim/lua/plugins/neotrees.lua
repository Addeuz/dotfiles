-- Git worktree manager. `after_create` bootstraps each new worktree so it is
-- ready to use: copies gitignored .env files from the main worktree, initialises
-- submodules and installs JS dependencies. Steps run async so the UI never blocks.

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "neotrees" })
end

--- Path of the main (first) worktree of the repo that `path` belongs to.
local function main_worktree(path)
  local res = vim.system({ "git", "worktree", "list", "--porcelain" }, { cwd = path, text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  return (res.stdout or ""):match("^worktree ([^\n]+)")
end

--- Copy gitignored `.env*` files (at any depth) from the main worktree into `path`.
local function copy_env_files(path)
  local main = main_worktree(path)
  if not main or main == path then
    return
  end
  local res = vim
    .system({ "git", "ls-files", "--others", "--ignored", "--exclude-standard", "--directory" }, { cwd = main, text = true })
    :wait()
  local copied = {}
  for file in (res.stdout or ""):gmatch("[^\n]+") do
    if vim.fs.basename(file):match("^%.env") and not file:match("/$") then
      local dest = path .. "/" .. file
      if not vim.uv.fs_stat(dest) then
        vim.fn.mkdir(vim.fs.dirname(dest), "p")
        if vim.uv.fs_copyfile(main .. "/" .. file, dest) then
          table.insert(copied, file)
        end
      end
    end
  end
  if #copied > 0 then
    notify("Copied env files: " .. table.concat(copied, ", "))
  end
end

--- Pick the install command based on the lockfile present in the worktree root.
local function install_cmd(path)
  local exists = function(f)
    return vim.uv.fs_stat(path .. "/" .. f) ~= nil
  end
  if exists("pnpm-lock.yaml") then
    return { "pnpm", "install" }
  elseif exists("bun.lock") or exists("bun.lockb") then
    return { "bun", "install" }
  elseif exists("yarn.lock") then
    return { "yarn", "install" }
  elseif exists("package-lock.json") then
    return { "npm", "ci" }
  elseif exists("package.json") then
    return { "npm", "install" }
  end
end

--- Run `steps` sequentially and asynchronously in `cwd`, notifying on progress.
local function run_steps(steps, cwd, on_done)
  local function next_step(i)
    local step = steps[i]
    if not step then
      return on_done()
    end
    if vim.fn.executable(step.cmd[1]) == 0 then
      notify(step.cmd[1] .. " not found on PATH, skipping: " .. step.name, vim.log.levels.WARN)
      return next_step(i + 1)
    end
    notify(step.name .. "...")
    vim.system(step.cmd, { cwd = cwd, text = true }, function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          local err = vim.trim(res.stderr ~= "" and res.stderr or res.stdout or "")
          notify(step.name .. " failed:\n" .. err:sub(-1000), vim.log.levels.ERROR)
        end
        next_step(i + 1)
      end)
    end)
  end
  next_step(1)
end

local function after_create(path, branch)
  copy_env_files(path)

  local steps = {}
  if vim.uv.fs_stat(path .. "/.gitmodules") then
    table.insert(steps, { name = "Updating submodules", cmd = { "git", "submodule", "update", "--init", "--recursive" } })
  end
  local install = install_cmd(path)
  if install then
    table.insert(steps, { name = "Installing dependencies (" .. install[1] .. ")", cmd = install })
  end

  run_steps(steps, path, function()
    notify("Worktree '" .. branch .. "' is ready")
  end)
end

return {
  "gsilvapt/neotrees.nvim",
  cmd = { "Neotrees", "NeotreesAdd", "NeotreesDelete", "NeotreesLog" },
  keys = {
    {
      "<leader>gw",
      function()
        require("neotrees").open()
      end,
      desc = "Git Worktrees",
    },
  },
  opts = {
    after_create = after_create,
  },
}
