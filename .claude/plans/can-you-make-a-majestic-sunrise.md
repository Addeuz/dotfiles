# Plan: Unified Picker History (grep + files, extensible)

## Context

Replace `grep-history.lua` with a single `picker-history.lua` that drives history for any number of pickers. Adding a new picker's history = one new entry in a config table at the top of the file.

## Design

### Config table (the only thing to edit when adding more pickers)

```lua
local history_configs = {
  { log = "~/.local/state/nvim/grep.log",  sources = { "grep", "grep_word", "grep_buffers", "git_grep" } },
  { log = "~/.local/state/nvim/files.log", sources = { "files" } },
}
```

### Shared state (module-level, not globals)

```lua
local source_log  = {}   -- source_name  → expanded log path (built once at load time)
local log_history = {}   -- log_path     → history list (lazy per-log)
local picker_nav  = {}   -- picker.id    → { log_path, idx } (per-picker-instance nav state)
```

`source_log` is populated at load time by iterating `history_configs`.

### Shared functions

- **`get_log_path(picker)`** — `source_log[picker.opts.source]`, returns nil for unknown sources (all callbacks guard on this)
- **`load_history(log_path)`** — lazy read from file, cached in `log_history[log_path]`
- **`save(log_path, text)`** — mkdir -p, skip if empty or same as last entry, append + update cache
- **`on_close(picker)`** — guard on `get_log_path`; clear nav state; call `save`
- **`hist_prev(picker)`** — guard; if no nav state and input non-empty → `picker:action("list_up")`; otherwise enter/advance history mode, call `picker.input:set(entry, entry)`
- **`hist_next(picker)`** — guard; if no nav state → `picker:action("list_down")`; advance or clear to exit history mode

### Key bindings and Snacks spec

Generic action names `picker_hist_prev` / `picker_hist_next` (no source-specific naming needed).

`sources_config` is built dynamically from `history_configs` at load time:

```lua
local sources_config = {}
for _, cfg in ipairs(history_configs) do
  for _, src in ipairs(cfg.sources) do
    sources_config[src] = { win = { input = { keys = hist_keys } } }
  end
end
```

The returned lazy.nvim spec sets `opts.picker.on_close`, `opts.picker.actions`, and `opts.picker.sources` from `sources_config`.

## Files changed

| File | Action |
|---|---|
| `lua/plugins/grep-history.lua` | **Delete** — replaced entirely |
| `lua/plugins/picker-history.lua` | **Create** — unified implementation |

## Verification

1. Open grep picker, search, close → `~/.local/state/nvim/grep.log` gets the entry
2. Reopen grep picker, `<Up>` with empty input → history loads; `<Up>`/`<Down>` cycle; `<Down>` past end clears input
3. Open files picker, filter a name, close → `~/.local/state/nvim/files.log` gets the entry; history navigation works the same way
4. `<Up>` with non-empty input → falls through to `list_up` (result list navigation)
5. Buffers/recent/other pickers unaffected
6. Missing log file → no crash; history is empty
