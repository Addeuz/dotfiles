local M = {}

function M.trim(s)
  return (s:gsub("^%s*%d+%s+", ""):gsub("%s+%d+%s*$", ""))
end

function M.open_picker(state)
  local has_snacks, snacks = pcall(require, "snacks")
  if not has_snacks then
    return
  end

  snacks.picker.pick({
    title = string.format("CheckAudit: %s", state.msg),
    items = state.items,
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

function M.parse_machine_output(output)
  local file_diagnostics = {}
  local lines = vim.split(output, "\n")
  local in_check_block = false

  for _, line in ipairs(lines) do
    if line:match("START") then
      in_check_block = true
    elseif line:match("COMPLETED") or line:match("FAILED") then
      in_check_block = false
    elseif in_check_block and line ~= "" then
      local ok, data = pcall(vim.json.decode, M.trim(line))

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

return M
