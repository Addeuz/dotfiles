local function trim(s)
  return (s:gsub("^%s*%d+%s+", ""):gsub("%s+%d+%s*$", ""))
end

local CheckAuditState = {
  items = {},
  msg = "",
}

local function open_picker()
  local has_snacks, snacks = pcall(require, "snacks")
  if not has_snacks then
    return
  end

  snacks.picker.pick({
    title = string.format("CheckAudit: %s", CheckAuditState.msg),
    items = CheckAuditState.items,
    format_item = function(item)
      return string.format("%s %s", item.icon, item.file)
    end,
    format = function(item)
      local hl = item.severity == "WARN" and "SnacksPickerIconWarning"
        or item.severity == "HINT" and "SnacksPickerIconInfo"
        or "SnacksPickerIconError"
      return {
        { item.icon, hl },
        { " " .. item.file, "SnacksPickerLabel" },
        { string.format(" (%dE, %dW, %dH)", item.errors, item.warnings, item.hints), "SnacksPickerComment" },
      }
    end,
    actions = {
      confirm = function(picker, item)
        picker:close()
        vim.schedule(function()
          for _, selected in ipairs(picker:selected({ fallback = true })) do
            vim.cmd(string.format("edit +%d %s", selected.lnum, selected.file))
          end
        end)
      end,
      vsplit = function(picker, item)
        vim.schedule(function()
          for _, selected in ipairs(picker:selected({ fallback = true })) do
            vim.cmd(string.format("vsplit +%d %s", selected.lnum, selected.file))
          end
        end)
      end,
      split = function(picker, item)
        vim.schedule(function()
          for _, selected in ipairs(picker:selected({ fallback = true })) do
            vim.cmd(string.format("split +%d %s", selected.lnum, selected.file))
          end
        end)
      end,
      tab = function(picker, item)
        vim.schedule(function()
          for _, selected in ipairs(picker:selected({ fallback = true })) do
            vim.cmd(string.format("tabedit +%d %s", selected.lnum, selected.file))
          end
        end)
      end,
    },
  })
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local function parse_machine_output(output)
        local file_diagnostics = {}
        local lines = vim.split(output, "\n")
        local in_check_block = false

        for _, line in ipairs(lines) do
          if line:match("START") then
            in_check_block = true
          elseif line:match("COMPLETED") or line:match("FAILED") then
            in_check_block = false
          elseif in_check_block and line ~= "" then
            local ok, data = pcall(vim.json.decode, trim(line))

            if ok and data then
              local filename = data.filename or data.fn
              filename = "audit/" .. filename
              local msg = data.message
              local dtype = data.type
              local start_pos = data.start
              local code = data.code

              if filename and msg and dtype and start_pos then
                local severity_level = vim.diagnostic.severity.INFO
                if dtype == "ERROR" then
                  severity_level = vim.diagnostic.severity.ERROR
                elseif dtype == "WARNING" then
                  severity_level = vim.diagnostic.severity.WARN
                elseif dtype == "HINT" then
                  severity_level = vim.diagnostic.severity.HINT
                end

                if not file_diagnostics[filename] then
                  file_diagnostics[filename] = {}
                end

                local diag = {
                  lnum = start_pos.line,
                  col = start_pos.character,
                  severity = severity_level,
                  message = msg,
                }

                if data["end"] then
                  diag.end_lnum = data["end"].line
                  diag.end_col = data["end"].character
                end

                if code then
                  diag.code = code
                end

                table.insert(file_diagnostics[filename], diag)
              end
            end
          end
        end

        return file_diagnostics
      end

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

            local file_diagnostics = parse_machine_output(table.concat(all_output, "\n"))

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

            local msg =
              string.format("%d issues (%dE, %dW, %dH)", total_issues, total_errors, total_warnings, total_hints)
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
            open_picker()
          end,
        })
      end, { desc = "Run pnpm audit check" })

      vim.api.nvim_create_user_command("CheckAuditResume", function()
        if #CheckAuditState.items == 0 then
          vim.notify("No cached audit results. Run :CheckAudit first.", vim.log.levels.WARN)
          return
        end
        open_picker()
      end, { desc = "Reopen CheckAudit picker" })
    end,
  },
}
