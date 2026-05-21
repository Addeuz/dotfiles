-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<M-h>", function()
  if vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }) then
    vim.lsp.inlay_hint.enable(false, { bufnr = 0 })
  else
    vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter" }, {
      buffer = 0,
      once = true,
      callback = function()
        vim.lsp.inlay_hint.enable(false, { bufnr = 0 })
      end,
    })
  end
end, { desc = "Peek inlay hints" })

vim.keymap.set("n", "<leader>xa", "", { desc = "+audit check" })
vim.keymap.set("n", "<leader>xaa", "<cmd>CheckAudit<cr>", { desc = "Run audit check" })
vim.keymap.set("n", "<leader>xar", "<cmd>CheckAuditResume<cr>", { desc = "Show latest audit check" })
