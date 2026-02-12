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
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },
}
