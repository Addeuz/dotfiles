-- Set root_spec to not care about `lsp` it is annoying when doing <leader><space> in monorepo
vim.g.root_spec = { { ".git", "lua" }, "cwd" }

vim.opt.scrolloff = 15
