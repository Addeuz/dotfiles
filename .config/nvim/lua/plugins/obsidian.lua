return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- use latest release, remove to use latest commit
    ft = "markdown",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false, -- this will be removed in 4.0.0
      workspaces = {
        {
          name = "df_notes",
          path = "~/gitrepos/dfmain/notes/df_notes",
        },
      },
      picker = {
        name = "snacks.pick",
      },
    },
  },
}
