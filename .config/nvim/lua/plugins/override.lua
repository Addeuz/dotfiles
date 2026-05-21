-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
      -- Monkey-patch pretty_path to always use length=10
      local original = LazyVim.lualine.pretty_path
      LazyVim.lualine.pretty_path = function(opts)
        opts = opts or {}
        opts.length = 10
        return original(opts)
      end
    end,
    opts = function(_, opts)
      opts.sections.lualine_y = {}
      opts.sections.lualine_z = {
        { "progress", separator = " ", padding = { left = 1, right = 0 } },
        { "location", padding = { left = 0, right = 1 } },
      }
      return opts
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },
  {
    "folke/todo-comments.nvim",
    opts = {
      highlight = {
        pattern = {
          [[.*<(KEYWORDS)\s*:]],
          [[.*<((KEYWORDS)#[^:\s]+)\s*:]],
        },
      },
      search = {
        pattern = [[\b(KEYWORDS)(#[^\s:]+)?:]],
      },
    },
  },
}
