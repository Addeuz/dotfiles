return {
  {
    "ThorstenRhau/brygga.nvim",
    version = "*",
    -- Load at startup, not on the key, so the server is up before Claude connects
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "x" } },
      -- Without a range it sends the whole file, from visual mode only the selected lines
      { "<leader>as", ":Brygga send<cr>", mode = { "n", "x" }, desc = "Send to Claude" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>as", icon = { icon = "󰈔", color = "cyan" }, mode = { "n", "x" } },
      },
    },
  },
}
