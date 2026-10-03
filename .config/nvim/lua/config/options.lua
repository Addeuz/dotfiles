-- Set root_spec to not care about `lsp` it is annoying when doing <leader><space> in monorepo
vim.g.root_spec = { { ".git", "lua" }, "cwd" }

vim.opt.scrolloff = 15

vim.opt.termguicolors = true

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
