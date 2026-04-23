local history_configs = {
  { log = "~/.local/state/nvim/grep.log", sources = { "grep", "grep_word", "grep_buffers", "git_grep" } },
  { log = "~/.local/state/nvim/files.log", sources = { "files" } },
}

local source_log = {}
local log_history = {}
local picker_nav = {}

for _, cfg in ipairs(history_configs) do
  local path = vim.fn.expand(cfg.log)
  for _, src in ipairs(cfg.sources) do
    source_log[src] = path
  end
end

local function get_log_path(picker)
  return source_log[type(picker.opts) == "table" and picker.opts.source or ""]
end

local function load_history(log_path)
  if log_history[log_path] then
    return log_history[log_path]
  end
  local hist = {}
  local f = io.open(log_path, "r")
  if f then
    for line in f:lines() do
      if line ~= "" then
        table.insert(hist, line)
      end
    end
    f:close()
  end
  log_history[log_path] = hist
  return hist
end

local function save(log_path, text)
  if text == "" then
    return
  end
  local hist = load_history(log_path)
  if hist[#hist] == text then
    return
  end
  vim.fn.mkdir(vim.fn.fnamemodify(log_path, ":h"), "p")
  local f = io.open(log_path, "a")
  if f then
    f:write(text .. "\n")
    f:close()
  end
  table.insert(hist, text)
end

local function on_close(picker)
  local log_path = get_log_path(picker)
  if not log_path then
    return
  end
  picker_nav[picker.id] = nil
  save(log_path, picker.input:get())
end

local function hist_prev(picker)
  local log_path = get_log_path(picker)
  if not log_path then
    return
  end
  local nav = picker_nav[picker.id]
  if not nav then
    if picker.input:get() ~= "" then
      picker:action("list_up")
      return
    end
    local hist = load_history(log_path)
    if #hist == 0 then
      return
    end
    nav = { log_path = log_path, idx = #hist }
    picker_nav[picker.id] = nav
  elseif nav.idx > 1 then
    nav.idx = nav.idx - 1
  end
  local hist = load_history(nav.log_path)
  local entry = hist[nav.idx]
  if entry then
    picker.input:set(entry, entry)
  end
end

local function hist_next(picker)
  local log_path = get_log_path(picker)
  if not log_path then
    return
  end
  local nav = picker_nav[picker.id]
  if not nav then
    picker:action("list_down")
    return
  end
  local hist = load_history(nav.log_path)
  if nav.idx < #hist then
    nav.idx = nav.idx + 1
    picker.input:set(hist[nav.idx], hist[nav.idx])
  else
    picker_nav[picker.id] = nil
    picker.input:set("", "")
  end
end

local hist_keys = {
  ["<Up>"] = { "picker_hist_prev", mode = { "i", "n" }, desc = "History prev" },
  ["<Down>"] = { "picker_hist_next", mode = { "i", "n" }, desc = "History next" },
}

local sources_config = {}
for _, cfg in ipairs(history_configs) do
  for _, src in ipairs(cfg.sources) do
    sources_config[src] = { win = { input = { keys = hist_keys } } }
  end
end

return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      on_close = on_close,
      actions = {
        picker_hist_prev = hist_prev,
        picker_hist_next = hist_next,
      },
      sources = sources_config,
    },
  },
}
