-- Git worktree manager on top of git-worktree.nvim, with a snacks.picker UI (<leader>gw).
-- Each worktree gets its own tab with a tab-local cwd (:tcd), named "<index> <worktree>" in
-- bufferline, and scope.nvim keeps each tab's buffer list separate.
-- New worktrees are bootstrapped so they are ready to use: gitignored .env files are copied
-- from the main worktree, submodules initialised and JS dependencies installed. Switching to
-- a worktree that has a lockfile but no node_modules bootstraps it too. Steps run async.
--
-- git-worktree.nvim's logger is a no-op and its create job emits CREATE even when
-- `git worktree add` fails, so errors are checked and reported here instead.

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Worktree" })
end

---@class WorktreeItem
---@field path string
---@field head string short commit
---@field branch? string nil when detached
---@field main boolean the repo's main checkout
---@field current boolean contains the cwd
---@field tab? integer number of the tab showing this worktree

-- ── Tabs ────────────────────────────────────────────────────────────────────

--- Number of the tab whose tab-local cwd is `path`, if any.
local function tab_for(path)
  for nr = 1, vim.fn.tabpagenr("$") do
    if vim.fn.getcwd(-1, nr) == path then
      return nr
    end
  end
end

--- Name each tab "<index> <worktree>"; bufferline renders `t:name` in its tab indicators.
local function update_tab_names()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local nr = vim.api.nvim_tabpage_get_number(tab)
    local root = vim.fs.root(vim.fn.getcwd(-1, nr), ".git")
    vim.t[tab].name = root and (nr .. " " .. vim.fs.basename(root)) or tostring(nr)
  end
  -- bufferline hides itself when a tab has a single buffer, which would hide the tab names too
  local multi = vim.fn.tabpagenr("$") > 1
  local ok, bufferline = pcall(require, "bufferline.config")
  if ok and bufferline.options then
    bufferline.options.always_show_bufferline = multi
  end
  if multi then
    vim.o.showtabline = 2
  end
  vim.cmd.redrawtabline()
end

--- In a freshly opened worktree tab, open the file the previous tab was showing (if it exists
--- here too), otherwise the dashboard.
local function open_same_file(path, prev_path)
  local prev = vim.fn.tabpagenr("#")
  local buf = prev > 0 and vim.fn.tabpagebuflist(prev)[vim.fn.tabpagewinnr(prev)]
  local name = buf and vim.api.nvim_buf_get_name(buf) or ""
  if prev_path and vim.startswith(name, prev_path .. "/") then
    local target = path .. name:sub(#prev_path + 1)
    if vim.uv.fs_stat(target) then
      return vim.cmd.edit(vim.fn.fnameescape(target))
    end
  end
  -- in the tab's own window; without win/buf it opens as a fullscreen float over the tabline.
  -- Opts inherits Config's non-optional sections/formats, but they are filled from the defaults.
  ---@diagnostic disable-next-line: missing-fields
  Snacks.dashboard({ buf = 0, win = 0 })
end

--- Worktrees of the repo containing the cwd (bare entries skipped), or nil outside a repo.
---@return WorktreeItem[]?
local function list_worktrees()
  local cwd = vim.fn.getcwd()
  local res = vim.system({ "git", "worktree", "list", "--porcelain" }, { cwd = cwd, text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  local toplevel = vim.trim(vim.system({ "git", "rev-parse", "--show-toplevel" }, { cwd = cwd, text = true }):wait().stdout or "")
  local items, item = {}, nil
  for line in (res.stdout or ""):gmatch("[^\n]+") do
    if line:match("^worktree ") then
      item = { path = line:sub(10), head = "", main = #items == 0 }
      table.insert(items, item)
    elseif line:match("^HEAD ") then
      item.head = line:sub(6, 12)
    elseif line:match("^branch ") then
      item.branch = (line:gsub("^branch refs/heads/", ""))
    elseif line == "bare" then
      item.bare = true
    end
  end
  return vim.tbl_map(
    function(wt)
      wt.current = wt.path == toplevel
      wt.tab = tab_for(wt.path)
      wt.text = (wt.branch or "detached") .. " " .. wt.path
      return wt
    end,
    vim.tbl_filter(function(wt)
      return not wt.bare
    end, items)
  )
end

--- Path of the main (first) worktree of the repo that `path` belongs to.
local function main_worktree(path)
  local res = vim.system({ "git", "worktree", "list", "--porcelain" }, { cwd = path, text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  return (res.stdout or ""):match("^worktree ([^\n]+)")
end

-- ── Bootstrap ───────────────────────────────────────────────────────────────

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

-- Repo-specific steps run before installing dependencies, keyed by the main worktree's directory name.
local repo_steps = {
  -- the wasm-pack pkg/ dirs are gitignored workspace members; pnpm install fails without them
  dfmain = { { name = "Stubbing WASM packages", cmd = { "make", "ensure-wasm-pkg-stubs" } } },
}

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
--- `on_done` receives the number of steps that failed.
local function run_steps(steps, cwd, on_done)
  local failed = 0
  local function next_step(i)
    local step = steps[i]
    if not step then
      return on_done(failed)
    end
    if vim.fn.executable(step.cmd[1]) == 0 then
      notify(step.cmd[1] .. " not found on PATH, skipping: " .. step.name, vim.log.levels.WARN)
      return next_step(i + 1)
    end
    notify(step.name .. "...")
    vim.system(step.cmd, { cwd = cwd, text = true }, function(res)
      vim.schedule(function()
        if res.code ~= 0 then
          failed = failed + 1
          -- pnpm prints its errors to stdout, so show the tail of both
          local err = vim.trim((res.stdout or "") .. "\n" .. (res.stderr or ""))
          notify(step.name .. " failed:\n" .. err:sub(-1000), vim.log.levels.ERROR)
        end
        next_step(i + 1)
      end)
    end)
  end
  next_step(1)
end

local bootstrapping = {} ---@type table<string, boolean>

local function bootstrap(path, label)
  if bootstrapping[path] then
    return
  end
  bootstrapping[path] = true
  copy_env_files(path)

  local steps = {}
  if vim.uv.fs_stat(path .. "/.gitmodules") then
    table.insert(steps, { name = "Updating submodules", cmd = { "git", "submodule", "update", "--init", "--recursive" } })
  end
  local main = main_worktree(path)
  vim.list_extend(steps, main and repo_steps[vim.fs.basename(main)] or {})
  local install = install_cmd(path)
  if install then
    table.insert(steps, { name = "Installing dependencies (" .. install[1] .. ")", cmd = install })
  end

  run_steps(steps, path, function(failed)
    bootstrapping[path] = nil
    if failed > 0 then
      notify("Worktree '" .. label .. "' set up with " .. failed .. " failed step(s)", vim.log.levels.WARN)
    else
      notify("Worktree '" .. label .. "' is ready")
    end
  end)
end

--- A JS project whose dependencies were never installed, e.g. a worktree not created from here.
local function needs_bootstrap(path)
  return install_cmd(path) ~= nil and not vim.uv.fs_stat(path .. "/node_modules")
end

--- :WorktreeBootstrap — bootstrap the worktree containing the cwd.
local function bootstrap_current()
  local root = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if root.code ~= 0 then
    return notify("Not inside a git worktree", vim.log.levels.ERROR)
  end
  local branch = vim.trim(vim.system({ "git", "branch", "--show-current" }, { text = true }):wait().stdout or "")
  bootstrap(vim.trim(root.stdout), branch ~= "" and branch or "(detached)")
end

-- ── Create / delete ─────────────────────────────────────────────────────────

--- Create a worktree for `branch` next to the main worktree, e.g. dfmain-feat-foo for feat/foo.
--- `upstream` (e.g. origin/foo) makes a new local branch tracking it; without one, a branch
--- that doesn't exist yet is created from the current HEAD.
local function create_worktree(branch, upstream)
  local worktrees = list_worktrees() or {}
  local in_use = vim.iter(worktrees):find(function(wt)
    return wt.branch == branch
  end)
  if in_use then
    return notify("'" .. branch .. "' is already checked out in " .. vim.fn.fnamemodify(in_use.path, ":~"), vim.log.levels.ERROR)
  end
  local main = worktrees[1].path
  local path = vim.fs.dirname(main) .. "/" .. vim.fs.basename(main) .. "-" .. (branch:gsub("/", "-"))
  if vim.uv.fs_stat(path) then
    return notify(vim.fn.fnamemodify(path, ":~") .. " already exists", vim.log.levels.ERROR)
  end
  notify("Creating worktree for '" .. branch .. "'...")
  require("git-worktree").create_worktree(path, branch, upstream)
end

--- Wipe buffers belonging to a deleted worktree.
local function wipe_buffers(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.startswith(vim.api.nvim_buf_get_name(buf), path .. "/") then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

local function delete_worktree(picker, item)
  local label = item.branch or vim.fs.basename(item.path)
  local function delete(force)
    require("git-worktree").delete_worktree(item.path, force, {
      on_success = function()
        local tab = tab_for(item.path)
        if tab then
          vim.cmd.tabclose(tab)
        end
        wipe_buffers(item.path)
        notify("Deleted worktree '" .. label .. "'")
        picker:find()
      end,
      on_failure = vim.schedule_wrap(function()
        Snacks.picker.util.confirm("Worktree '" .. label .. "' has changes. Force delete?", function()
          delete(true)
        end)
      end),
    })
  end
  Snacks.picker.util.confirm("Delete worktree '" .. label .. "'?", function()
    delete(false)
  end)
end

-- ── Pickers ─────────────────────────────────────────────────────────────────

--- Branch picker for a new worktree: <cr> uses the selected (local or remote) branch,
--- <c-a> creates a new branch from the typed name.
local function pick_branch()
  Snacks.picker.git_branches({
    title = "Worktree Branch (<c-a> new branch)",
    all = true,
    confirm = function(picker, item)
      picker:close()
      if not (item and item.branch) then
        return
      end
      local remote, name = item.branch:match("^remotes/([^/]+)/(.+)$")
      if name then
        create_worktree(name, remote .. "/" .. name)
      else
        create_worktree(item.branch)
      end
    end,
    actions = {
      worktree_new_branch = function(picker)
        Snacks.input.input({ prompt = "New Branch Name", default = picker.input:get() }, function(name)
          name = vim.trim(name or "")
          if name ~= "" then
            picker:close()
            create_worktree(name)
          end
        end)
      end,
    },
    win = { input = { keys = { ["<c-a>"] = { "worktree_new_branch", mode = { "n", "i" } } } } },
  })
end

local function pick_worktree()
  if not list_worktrees() then
    return notify("Not inside a git repository", vim.log.levels.ERROR)
  end
  Snacks.picker.pick({
    source = "git_worktrees",
    title = "Git Worktrees (<c-a> add, <c-x> delete)",
    finder = function()
      return list_worktrees() or {}
    end,
    layout = { preset = "select" },
    format = function(item)
      return {
        { item.current and "* " or item.tab and (item.tab .. " ") or "  ", "SnacksPickerGitBranchCurrent" },
        item.branch and { item.branch, "SnacksPickerGitBranch" } or { "(detached " .. item.head .. ")", "SnacksPickerGitDetached" },
        { "  " .. vim.fn.fnamemodify(item.path, ":~"), "SnacksPickerComment" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if not item or item.current then
        return
      elseif item.tab then
        vim.cmd.tabnext(item.tab)
      else
        -- opens a new tab, see change_directory_command
        require("git-worktree").switch_worktree(item.path)
      end
    end,
    actions = {
      worktree_add = function(picker)
        picker:close()
        pick_branch()
      end,
      worktree_delete = function(picker, item)
        if not item then
          return
        elseif item.main then
          return notify("Can't delete the main worktree", vim.log.levels.WARN)
        elseif item.current then
          return notify("Can't delete the current worktree, switch to another first", vim.log.levels.WARN)
        end
        delete_worktree(picker, item)
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-a>"] = { "worktree_add", mode = { "n", "i" } },
          ["<c-x>"] = { "worktree_delete", mode = { "n", "i" } },
        },
      },
    },
  })
end

return {
  -- per-tab buffer lists, so worktree tabs don't share buffers
  { "tiagovla/scope.nvim", event = "VeryLazy", opts = {} },
  {
    "polarmutex/git-worktree.nvim",
    version = "^2",
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      -- switching opens the worktree in a new tab with a tab-local cwd
      vim.g.git_worktree = { change_directory_command = "tabnew | tcd" }
      vim.api.nvim_create_autocmd({ "VimEnter", "TabNew", "TabEnter", "TabClosed", "DirChanged" }, {
        group = vim.api.nvim_create_augroup("worktree_tab_names", { clear = true }),
        callback = vim.schedule_wrap(update_tab_names),
      })
      vim.api.nvim_create_user_command("WorktreeBootstrap", bootstrap_current, {
        desc = "Copy env files and install dependencies in the current git worktree",
      })
    end,
    keys = {
      { "<leader>gw", pick_worktree, desc = "Git Worktrees" },
    },
    config = function()
      local Hooks = require("git-worktree.hooks")

      Hooks.register(Hooks.type.CREATE, function(path, branch)
        path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
        if not vim.uv.fs_stat(path) then
          return notify("Failed to create worktree for '" .. branch .. "'", vim.log.levels.ERROR)
        end
        bootstrap(path, branch)
      end)

      Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
        path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
        open_same_file(path, prev_path)
        if needs_bootstrap(path) then
          local branch = vim.trim(vim.system({ "git", "branch", "--show-current" }, { cwd = path, text = true }):wait().stdout or "")
          bootstrap(path, branch ~= "" and branch or "(detached)")
        end
      end)
    end,
  },
}
