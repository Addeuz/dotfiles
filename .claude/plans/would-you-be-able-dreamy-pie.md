# Plan: Migrate from LazyVim to Native Neovim (vim.lsp + packpath)

## Context

The current config uses LazyVim as a distribution (providing opinionated defaults for ~40 plugins) and lazy.nvim as the plugin manager. The goal is to remove both dependencies and wire everything manually using:
- **Native Neovim packpath** for plugin storage (plugins cloned into `~/.local/share/nvim/site/pack/plugins/start/`)
- **`vim.lsp.config()` + `vim.lsp.enable()`** (Neovim 0.11+ API) instead of nvim-lspconfig
- **`scripts/install.sh`** shell script to clone/update all plugins via git

Scope: full feature parity with today's config. Eager loading throughout.

---

## New File Structure

```
~/.config/nvim/
├── init.lua                    # rewritten: load order, disable built-ins
├── stylua.toml                 # unchanged
├── snippets/svelte.json        # unchanged
├── scripts/
│   └── install.sh              # NEW: git clone all plugins
└── lua/
    ├── config/
    │   ├── options.lua         # unchanged
    │   ├── keymaps.lua         # unchanged (custom: <leader>xa/xaa/xar)
    │   ├── default-keymaps.lua # NEW: ported LazyVim default keymaps
    │   └── autocmds.lua        # unchanged (empty)
    ├── lsp/
    │   ├── init.lua            # vim.lsp.enable() for all servers
    │   ├── ts_ls.lua           # TypeScript
    │   ├── svelte.lua          # Svelte
    │   ├── pyright.lua         # Python
    │   ├── ruff_lsp.lua        # Python (ruff)
    │   ├── lua_ls.lua          # Lua (+ lazydev integration)
    │   ├── jsonls.lua          # JSON + SchemaStore
    │   └── taplo.lua           # TOML
    └── plugins/
        ├── ui.lua              # snacks, lualine, bufferline, tokyonight, noice, mini.icons
        ├── completion.lua      # blink.cmp + friendly-snippets
        ├── treesitter.lua      # treesitter + context + textobjects + ts-autotag
        ├── git.lua             # gitsigns (current_line_blame=true)
        ├── editing.lua         # flash, which-key, todo-comments, grug-far, ts-comments,
        │                       # mini.ai, mini.pairs, mini.surround, mini.hipatterns
        ├── formatting.lua      # conform (prettier, stylua, ruff)
        ├── linting.lua         # nvim-lint (eslint)
        ├── diagnostics.lua     # trouble
        ├── mason.lua           # mason + ensure_installed list
        ├── lang-rust.lua       # rustaceanvim, crates.nvim
        ├── lang-python.lua     # venv-selector
        ├── lang-json.lua       # SchemaStore (wired into jsonls)
        ├── claudecode.lua      # claudecode.nvim
        └── check-audit.lua     # CheckAudit (adapted — remove lazy spec wrapper)
```

Files to **delete**: `lua/config/lazy.lua`, `lazyvim.json`, `lazy-lock.json`

---

## Key Implementation Decisions

### 1. Plugin installation (`scripts/install.sh`)

Clones ~35 repos into `~/.local/share/nvim/site/pack/plugins/start/`. Each is idempotent (skip if dir exists, otherwise `git clone --depth=1`). Add a `--update` flag to `git pull --rebase` existing ones.

Plugins to include (grouped):
- **UI**: `folke/snacks.nvim`, `nvim-lualine/lualine.nvim`, `akinsho/bufferline.nvim`, `folke/tokyonight.nvim`, `folke/noice.nvim`, `MunifTanjim/nui.nvim`, `echasnovski/mini.icons`
- **Treesitter**: `nvim-treesitter/nvim-treesitter`, `nvim-treesitter/nvim-treesitter-context`, `nvim-treesitter/nvim-treesitter-textobjects`, `windwp/nvim-ts-autotag`
- **Completion**: `saghen/blink.cmp`, `rafamadriz/friendly-snippets`
- **LSP tooling**: `williamboman/mason.nvim`, `williamboman/mason-lspconfig.nvim`, `folke/lazydev.nvim`, `b0o/SchemaStore.nvim`
- **Formatting/Linting**: `stevearc/conform.nvim`, `mfussenegger/nvim-lint`
- **Git**: `lewis6991/gitsigns.nvim`
- **Editing**: `folke/flash.nvim`, `folke/which-key.nvim`, `folke/todo-comments.nvim`, `MagicDuck/grug-far.nvim`, `folke/ts-comments.nvim`, `echasnovski/mini.ai`, `echasnovski/mini.pairs`, `echasnovski/mini.surround`, `echasnovski/mini.hipatterns`, `folke/persistence.nvim`
- **Diagnostics**: `folke/trouble.nvim`
- **Languages**: `mrcjkb/rustaceanvim`, `saecki/crates.nvim`, `linux-cultist/venv-selector.nvim`
- **AI**: `coder/claudecode.nvim`
- **Utils**: `nvim-lua/plenary.nvim`

### 2. `init.lua` — new entry point

```lua
-- Disable unused built-ins
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tohtml = 1
vim.g.loaded_tutor = 1
vim.g.loaded_zipPlugin = 1

require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Colorscheme first (so plugins see correct highlights)
vim.cmd.colorscheme("tokyonight")

-- Plugin setup (plugins are in packpath start/ so already loaded)
require("plugins.mason")
require("plugins.ui")
require("plugins.treesitter")
require("plugins.completion")
require("plugins.git")
require("plugins.editing")
require("plugins.formatting")
require("plugins.linting")
require("plugins.diagnostics")
require("plugins.lang-rust")
require("plugins.lang-python")
require("plugins.claudecode")
require("plugins.check-audit")

-- LSP (after mason so servers are available)
require("lsp")
```

### 3. LSP via `vim.lsp.config()` + `vim.lsp.enable()`

Each `lua/lsp/*.lua` file calls `vim.lsp.config("server_name", { ... })`.  
`lua/lsp/init.lua` calls `vim.lsp.enable({ "ts_ls", "svelte", "pyright", "lua_ls", "jsonls", "taplo" })`.

Neovim 0.11+ ships built-in default configs for common servers in `runtime/lsp/`. Override only what differs from defaults (e.g. jsonls needs SchemaStore schemas, lua_ls needs lazydev workspace libs).

```lua
-- lua/lsp/jsonls.lua
vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

-- lua/lsp/lua_ls.lua
vim.lsp.config("lua_ls", {
  before_init = require("lazydev").get_before_init(),
  settings = { Lua = { workspace = { checkThirdParty = false } } },
})
```

**Note on Rust**: `rustaceanvim` manages `rust_analyzer` itself — do NOT call `vim.lsp.enable("rust_analyzer")`.

### 4. `check-audit.lua` — remove lazy spec wrapper

The current file returns a lazy.nvim spec table `{ { "neovim/nvim-lspconfig", opts = function() ... end } }`. The actual logic (user commands, picker, parser) is 100% reusable.

New version: remove the outer table entirely, execute the setup code directly:
```lua
-- lua/plugins/check-audit.lua
-- ... (trim, CheckAuditState, open_picker unchanged) ...

-- Register commands directly instead of inside opts = function()
local function parse_machine_output(output) ... end

vim.api.nvim_create_user_command("CheckAudit", function() ... end, { desc = "..." })
vim.api.nvim_create_user_command("CheckAuditResume", function() ... end, { desc = "..." })
```

No dependency on nvim-lspconfig or LazyVim.

### 5. `lualine` — replace pretty_path monkey-patch

The `override.lua` monkey-patches `LazyVim.lualine.pretty_path` (LazyVim-specific). Replace with a direct lualine config that uses a custom `filename` component:

```lua
-- in plugins/ui.lua
require("lualine").setup({
  sections = {
    lualine_c = {
      {
        "filename",
        path = 1,           -- relative path
        shorting_target = 40,
        symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" },
      },
    },
    -- ... rest of lualine sections
  },
})
```

### 6. Mason — explicit tool list

Without LazyVim auto-wiring, mason needs an explicit `ensure_installed` list:

```lua
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "ts_ls", "svelte-language-server", "pyright", "ruff",
    "lua-language-server", "json-lsp", "taplo",
  },
})
-- Also install formatters/linters via mason-tool-installer or manual ensure_installed:
-- prettier, stylua, eslint_d
```

### 7. `conform.nvim` — explicit formatter config

```lua
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    svelte = { "prettier" },
    json = { "prettier" },
    python = { "ruff_format" },
  },
})
```

### 8. `nvim-lint` — explicit linter config

```lua
require("lint").setup({ linters_by_ft = { javascript = { "eslint_d" }, typescript = { "eslint_d" } } })
-- Add autocmd for ModeChanged/BufWritePost to trigger linting
```

### 9. Root detection — keep as-is in options.lua

`vim.g.root_spec` is a LazyVim concept, not native. Replace with the standard approach:
- Use `vim.lsp` built-in `root_markers` in each LSP config (`.git`, `package.json`, `tsconfig.json`, etc.)
- Set `vim.g.root_spec` only if some plugin (e.g., snacks) still reads it; otherwise remove.

### 10. Default keymaps (`lua/config/default-keymaps.lua`)

Port all LazyVim defaults verbatim. Grouped sections:

**Motion & editing**
- `j`/`k` → `gj`/`gk` when `v:count == 0` (wrapped line nav)
- `<A-j>`/`<A-k>` → move line/selection up/down
- `<C-s>` → `:w<cr><esc>` (save)
- `<esc>` → `:noh<cr><esc>` (clear highlights)
- `<`/`>` in visual → indent and keep selection

**Window & buffer**
- `<C-h/j/k/l>` → window nav
- `<C-Up/Down/Left/Right>` → resize splits
- `<S-h>`/`<S-l>` → prev/next buffer
- `[b`/`]b` → prev/next buffer
- `<leader>bd` → `Snacks.bufdelete()`
- `<leader>bo` → `Snacks.bufdelete.other()`
- `<leader>bb`/`` <leader>` `` → alternate buffer
- `<leader>ww/wd/w-/w|` + `<leader>-`/`<leader>|` → window actions

**Tabs**
- `<leader><tab>` group: new, close, next, prev, first, last, only

**LSP** (registered in the `LspAttach` autocmd)
- `gd` → definition, `gr` → references, `gI` → implementation, `gy` → type def, `gD` → declaration
- `K` → hover, `gK` → signature help, `<C-k>` → sig help (insert)
- `<leader>ca` → code action, `<leader>cr` → rename, `<leader>cf` → format

**Diagnostics**
- `<leader>cd` → open float, `]d`/`[d` → next/prev, `]e`/`[e` → errors, `]w`/`[w` → warnings

**Snacks pickers** (full set)
- `<leader>space` → smart find
- `<leader>ff`/`fF` → files, `<leader>fr`/`fR` → recent, `<leader>fg` → git files
- `<leader>gg`/`gG` → lazygit, `<leader>gl`/`gL` → git log
- `<leader>gc`/`gC` → git commits, `<leader>gs`/`gS`/`gb` → status/stash/branches, `<leader>gB` → blame
- `<leader>sg`/`sG` → grep, `<leader>sw`/`sW` → grep word
- `<leader>sd`/`sD` → diagnostics, `<leader>ss`/`sS` → LSP symbols
- `<leader>sb/sc/sC/sh/sH/si/sj/sk/sl/sm/sM/so/sq/sR/st/sT/su` → other pickers
- `<leader>e`/`E` → explorer, `<leader>n` → notifications, `<leader>un` → dismiss
- `<C-/>` / `<C-_>` → toggle terminal

**Trouble**
- `<leader>xx`/`xX` → diagnostics, `<leader>cs`/`cS` → symbols/LSP
- `<leader>xL`/`xQ` → loclist/qflist

**Todo-comments**
- `]t`/`[t` → next/prev todo, `<leader>xt`/`xT` → trouble todos, `<leader>st`/`sT` → search todos

**Flash**
- `s` → flash, `S` → treesitter, `r` (op-pending) → remote, `R` → treesitter search

**UI toggles** (`<leader>u*`)
- background, conceallevel, inlay hints, line numbers, spell, wrap, etc.

**Which-key group labels**
- Register all `<leader>` group names so which-key shows correct headers

Note: `<leader>l` (`:Lazy`) is replaced with `<leader>L` → `:Mason` since lazy.nvim is gone.

### 11. Snacks — configure directly

```lua
require("snacks").setup({ picker = { ... }, dashboard = { ... } })
```
All current opts in `lua/plugins/snacks.lua` map 1:1 to this call.

---

## Files Changed Summary

| File | Action |
|------|--------|
| `init.lua` | Rewrite (new bootstrap) |
| `lua/config/lazy.lua` | Delete |
| `lua/config/options.lua` | Minor: remove `root_spec` if unused |
| `lua/config/keymaps.lua` | Unchanged (custom keymaps only) |
| `lua/config/default-keymaps.lua` | New: all ported LazyVim defaults |
| `lua/config/autocmds.lua` | Add lint autocmd, LSP attach if needed |
| `lua/plugins/snacks.lua` | Rewrite (remove lazy spec wrapper, call setup directly) |
| `lua/plugins/override.lua` | Delete (merged into ui.lua) |
| `lua/plugins/colorscheme.lua` | Delete (handled in init.lua) |
| `lua/plugins/check-audit.lua` | Rewrite (remove lazy spec wrapper) |
| `lua/lsp/` | New directory (8 files) |
| `lua/plugins/ui.lua` | New |
| `lua/plugins/completion.lua` | New |
| `lua/plugins/treesitter.lua` | New |
| `lua/plugins/git.lua` | New |
| `lua/plugins/editing.lua` | New |
| `lua/plugins/formatting.lua` | New |
| `lua/plugins/linting.lua` | New |
| `lua/plugins/diagnostics.lua` | New |
| `lua/plugins/mason.lua` | New |
| `lua/plugins/lang-rust.lua` | New |
| `lua/plugins/lang-python.lua` | New |
| `lua/plugins/claudecode.lua` | New |
| `scripts/install.sh` | New |
| `lazyvim.json`, `lazy-lock.json` | Delete |

---

## Verification

1. Run `bash scripts/install.sh` — all repos clone without error
2. Run `nvim` — starts without errors, tokyonight loads, dashboard appears
3. Open a `.ts` file — treesitter highlights, `ts_ls` attaches (`:checkhealth lsp`)
4. Open a `.svelte` file — svelte LSP attaches
5. Open a `.rs` file — rustaceanvim LSP attaches
6. `<leader>xa` → audit menu, `<leader>xaa` → runs CheckAudit
7. Format a file (`<leader>cf`) — prettier/stylua runs via conform
8. `:Mason` — opens mason UI, servers show as installed
9. `:Trouble` — diagnostics panel opens
10. `<leader>gg` → snacks gitlog or similar — snacks picker works
