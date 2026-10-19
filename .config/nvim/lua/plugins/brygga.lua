-- One Claude terminal per working directory, so worktree tabs (`tcd`) each get their own session
local terms = {}

local function claude_buf()
  local buf = terms[vim.fn.getcwd()]
  return buf and vim.api.nvim_buf_is_valid(buf) and buf or nil
end

local function claude_win()
  local buf = claude_buf()
  for _, win in ipairs(buf and vim.api.nvim_tabpage_list_wins(0) or {}) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

-- Stopping the job closes Claude's websocket, which brygga sees as the client disconnecting
local function kill_claude()
  vim.fn.jobstop(vim.bo[claude_buf()].channel)
end

-- Only map <leader>ax while there is a session for the current directory, so which-key hides it otherwise
local function sync_kill_map()
  if claude_buf() then
    vim.keymap.set("n", "<leader>ax", kill_claude, { desc = "Kill Claude" })
  else
    pcall(vim.keymap.del, "n", "<leader>ax")
  end
end

local function show_claude()
  local buf = claude_buf()
  vim.cmd("botright vsplit")
  vim.api.nvim_win_set_width(0, 80)
  vim.wo.winfixwidth = true
  if buf then
    vim.api.nvim_win_set_buf(0, buf)
  else
    local cwd = vim.fn.getcwd()
    -- Unlisted, so it stays out of the bufferline and buffer pickers
    buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_win_set_buf(0, buf)
    vim.fn.jobstart({ "claude" }, { term = true })
    vim.bo[buf].buflisted = false
    vim.bo[buf].bufhidden = "hide"
    terms[cwd] = buf
    sync_kill_map()
    for _, dir in ipairs({ "h", "j", "k", "l" }) do
      vim.keymap.set("t", "<C-" .. dir .. ">", "<cmd>wincmd " .. dir .. "<cr>", { buffer = buf })
    end
    -- Back in terminal mode when navigating into it, so you can type right away
    vim.api.nvim_create_autocmd("BufEnter", { buffer = buf, command = "startinsert" })
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = buf,
      once = true,
      callback = function()
        terms[cwd] = nil
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
          sync_kill_map()
        end)
      end,
    })
  end
  vim.cmd.startinsert()
end

return {
  {
    "ThorstenRhau/brygga.nvim",
    version = "*",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      require("brygga").setup(opts)
      Snacks.toggle({
        name = "Claude",
        notify = false,
        wk_desc = { enabled = "Hide ", disabled = "Show " },
        get = function()
          return claude_win() ~= nil
        end,
        set = function(state)
          if state then
            show_claude()
          else
            vim.api.nvim_win_hide(claude_win())
          end
        end,
      }):map("<leader>aa")
      -- Worktree tabs have their own cwd, so the session (and the mapping) can change with the tab
      vim.api.nvim_create_autocmd({ "DirChanged", "TabEnter" }, {
        group = vim.api.nvim_create_augroup("claude_kill_map", { clear = true }),
        callback = sync_kill_map,
      })
    end,
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "x" } },
      { "<leader>ab", "<cmd>Brygga send<cr>", desc = "Send File to Claude" },
      { "<leader>as", ":Brygga send<cr>", mode = "x", desc = "Send Selection to Claude" },
      { "<leader>ai", "<cmd>Brygga status<cr>", desc = "Brygga Status" },
    },
  },
}
