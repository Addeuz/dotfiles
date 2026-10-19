-- Set root_spec to not care about `lsp` it is annoying when doing <leader><space> in monorepo
vim.g.root_spec = { { ".git", "lua" }, "cwd" }

vim.opt.scrolloff = 15

vim.opt.termguicolors = true

-- Wider insert-mode cursor (default is ver25, i.e. 25% of the cell width)
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver40,r-cr-o:hor20"

-- Spellcheck against both English and Swedish dictionaries.
-- LazyVim only turns `spell` on buffer-locally (text, plaintex, typst, gitcommit, markdown),
-- so this just widens the language list for those buffers.
vim.opt.spelllang = { "en", "sv" }

-- `:restart` sources its session while did_filetype() is still set, so filetype detection (`:setf`) is a no-op
-- and restored buffers get no filetype (and no LSP). Set it directly instead, which `:setf` can't block.
-- Lives here rather than in autocmds.lua because that only loads on VeryLazy, after the session is restored.
vim.api.nvim_create_autocmd("SessionLoadPost", {
  group = vim.api.nvim_create_augroup("session_filetype", { clear = true }),
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].filetype == "" then
        local ft = vim.filetype.match({ buf = buf })
        if ft then
          vim.bo[buf].filetype = ft
        end
      end
    end
  end,
})

-- A `:restart` session aborts on its first error (e.g. `tcd` into a deleted worktree), after it has set
-- winwidth=1/winminwidth=0 but before restoring them. The next `:restart` then saves winwidth=1 and fails with
-- E592 when it restores LazyVim's winminwidth=5, so every restart after that breaks. Reset them once the session ran.
local win_sizes = { "winwidth", vim.o.winwidth, "winminwidth", vim.o.winminwidth }
local win_heights = { "winheight", vim.o.winheight, "winminheight", vim.o.winminheight }
vim.api.nvim_create_autocmd("UIEnter", {
  group = vim.api.nvim_create_augroup("session_win_sizes", { clear = true }),
  callback = function()
    vim.schedule(function()
      for _, o in ipairs({ win_sizes, win_heights }) do
        vim.o[o[3]] = 0
        vim.o[o[1]] = o[2]
        vim.o[o[3]] = o[4]
      end
    end)
  end,
})
