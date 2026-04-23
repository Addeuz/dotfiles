-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local utils = require("config.utils")

local CheckAuditState = {
  items = {},
  msg = "",
}

vim.api.nvim_create_user_command("CheckAudit", function()
  vim.notify("Running pnpm audit check...", vim.log.levels.INFO)

  local stdout_data = {}
  local stderr_data = {}

  vim.fn.jobstart("pnpm -F audit run check:machine", {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_data, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.list_extend(stderr_data, data)
      end
    end,
    on_exit = function()
      local all_output = {}
      vim.list_extend(all_output, stdout_data)
      vim.list_extend(all_output, stderr_data)

      local file_diagnostics = utils.parse_machine_output(table.concat(all_output, "\n"))

      local total_errors = 0
      local total_warnings = 0
      local total_hints = 0

      for _, diags in pairs(file_diagnostics) do
        for _, diag in ipairs(diags) do
          if diag.severity == vim.diagnostic.severity.ERROR then
            total_errors = total_errors + 1
          elseif diag.severity == vim.diagnostic.severity.WARN then
            total_warnings = total_warnings + 1
          else
            total_hints = total_hints + 1
          end
        end
      end

      local total_issues = total_errors + total_warnings + total_hints
      if total_issues == 0 then
        vim.notify("Audit check passed!", vim.log.levels.INFO)
        return
      end

      local msg = string.format("%d issues (%dE, %dW, %dH)", total_issues, total_errors, total_warnings, total_hints)
      vim.notify(msg, total_errors > 0 and vim.log.levels.ERROR or vim.log.levels.WARN)

      local items = {}
      for filename, diags in pairs(file_diagnostics) do
        local count_errors = 0
        local count_warnings = 0
        local count_hints = 0

        for _, diag in ipairs(diags) do
          if diag.severity == vim.diagnostic.severity.ERROR then
            count_errors = count_errors + 1
          elseif diag.severity == vim.diagnostic.severity.WARN then
            count_warnings = count_warnings + 1
          else
            count_hints = count_hints + 1
          end
        end

        local severity, icon
        if count_errors > 0 then
          severity, icon = "ERROR", "E"
        elseif count_warnings > 0 then
          severity, icon = "WARN", "W"
        else
          severity, icon = "HINT", "I"
        end

        table.insert(items, {
          file = filename,
          path = filename,
          lnum = diags[1].lnum + 1,
          col = diags[1].col + 1,
          severity = severity,
          icon = icon,
          errors = count_errors,
          warnings = count_warnings,
          hints = count_hints,
          text = string.format("%s %s %d %d %d", icon, filename, count_errors, count_warnings, count_hints),
        })
      end

      table.sort(items, function(a, b)
        local priority = { ERROR = 1, WARN = 2, HINT = 3 }
        if priority[a.severity] ~= priority[b.severity] then
          return priority[a.severity] < priority[b.severity]
        end
        return a.file < b.file
      end)

      CheckAuditState.items = items
      CheckAuditState.msg = msg
      utils.open_picker(CheckAuditState)
    end,
  })
end, { desc = "Run pnpm audit check" })

vim.api.nvim_create_user_command("CheckAuditResume", function()
  if #CheckAuditState.items == 0 then
    vim.notify("No cached audit results. Run :CheckAudit first.", vim.log.levels.WARN)
    return
  end
  utils.open_picker(CheckAuditState)
end, { desc = "Reopen CheckAudit picker" })
