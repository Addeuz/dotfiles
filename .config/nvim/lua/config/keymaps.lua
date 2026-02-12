-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>xaa", "<cmd>CheckAudit<cr>", { desc = "Run audit check" })
vim.keymap.set("n", "<leader>xar", "<cmd>CheckAuditResume<cr>", { desc = "Show latest audit check" })
