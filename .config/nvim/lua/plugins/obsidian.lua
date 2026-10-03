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
      -- obsidian.nvim hardcodes its own colors; link them to the colorscheme instead
      ui = {
        hl_groups = {
          ObsidianTodo = { link = "DiagnosticWarn" },
          ObsidianDone = { link = "DiagnosticOk" },
          ObsidianRightArrow = { link = "Operator" },
          ObsidianTilde = { link = "Comment" },
          ObsidianImportant = { link = "DiagnosticError" },
          ObsidianBullet = { link = "@markup.list" },
          ObsidianRefText = { link = "@markup.link.url" },
          ObsidianExtLinkIcon = { link = "@markup.link" },
          ObsidianTag = { link = "@tag" },
          ObsidianBlockID = { link = "Comment" },
          ObsidianHighlightText = { link = "Search" },
        },
      },
    },
  },
}
