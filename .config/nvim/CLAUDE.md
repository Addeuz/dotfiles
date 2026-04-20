# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Neovim configuration built on top of [LazyVim](https://www.lazyvim.org/), using [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. Custom code lives in `lua/config/` and `lua/plugins/`.

## Code Style

Lua is formatted with **stylua**: 2-space indentation, 120-character line width (`stylua.toml`).

## Architecture

### Entry Point

`init.lua` is minimal — it just calls `require("config.lazy")`, which bootstraps lazy.nvim and loads everything else.

### Loading Order

1. `lua/config/lazy.lua` — bootstraps lazy.nvim, imports LazyVim core + extras, auto-loads all files in `lua/plugins/`
2. `lua/config/options.lua` — vim options (loaded by LazyVim at startup)
3. `lua/config/keymaps.lua` — custom keymaps (loaded by LazyVim at startup)
4. `lua/config/autocmds.lua` — custom autocommands (loaded by LazyVim at startup)

### LazyVim Extras

Selected extras are declared in `lazyvim.json`. Adding a new extra means adding an entry there rather than writing a plugin spec manually.

### Plugin Customization Pattern

Files in `lua/plugins/` are lazy.nvim specs. The pattern for overriding a LazyVim plugin is to return a table with just `name` and `opts`:

```lua
return {
  { "plugin/name", opts = { key = value } }
}
```

lazy.nvim merging rules for spec fields:
- `opts` — deep-merged with defaults; a plain table is sufficient for most overrides
- `cmd`, `event`, `ft`, `keys`, `dependencies` — extended (your entries are appended)
- any other field (e.g. `config`, `init`) — replaces the default entirely

For `opts`, `ft`, `event`, `keys`, and `cmd` you can pass a function `(_, defaults)` instead of a table when you need to mutate the existing values (e.g. appending to an array inside opts).

`override.lua` uses `opts` as a function to monkey-patch LazyVim defaults (e.g., `lualine` pretty_path, `gitsigns` current_line_blame).

### Custom Plugins

**`lua/plugins/check-audit.lua`** — the main custom plugin. It:
- Registers `:CheckAudit` and `:CheckAuditResume` commands
- Runs `pnpm -F audit run check:machine`, parses JSON diagnostic output
- Feeds results into Neovim's diagnostic system (`vim.diagnostic`)
- Opens results in a `snacks.picker` with file-open actions
- Caches state in a `CheckAuditState` module between invocations

**`lua/plugins/snacks.lua`** — configures the Snacks.nvim dashboard (custom ASCII header, recent files, keybindings).

### Keymaps for Audit Commands

| Keymap | Action |
|--------|--------|
| `<leader>xa` | Open audit check menu |
| `<leader>xaa` | Run `:CheckAudit` |
| `<leader>xar` | Show `:CheckAuditResume` (last results) |

### Root Directory Detection

`options.lua` sets `vim.g.root_spec = { ".git", "lua", "lsp" }` to avoid LSP confusion in monorepos — root is detected by `.git` or `lua/` presence rather than LSP markers alone.

### Snippets

`snippets/svelte.json` — Svelte snippets all prefixed with `s-` (e.g., `s-component`, `s-each`, `s-mount`, `s-state`).
