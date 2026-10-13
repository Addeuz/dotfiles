return {
  "folke/snacks.nvim",
  opts = {
    lazygit = {
      config = {
        os = {
          -- The "nvim-remote" preset opens files with --remote-tab; open them in the current window instead
          edit = '[ -z "$NVIM" ] && (nvim -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{filename}})',
          editAtLine = '[ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) || (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote {{filename}} && nvim --server "$NVIM" --remote-send ":{{line}}<CR>")',
        },
      },
    },
    picker = {
      sources = {
        grep = {
          args = { "--hidden" },
        },
        files = {
          args = { "--hidden" },
        },
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
    dashboard = {
      preset = {
        -- Delta Corps Priest 1
        header = [[
   ▄████████ ████████▄  ████████▄     ▄████████ 
  ███    ███ ███   ▀███ ███   ▀███   ███    ███ 
  ███    ███ ███    ███ ███    ███   ███    █▀  
  ███    ███ ███    ███ ███    ███  ▄███▄▄▄     
▀███████████ ███    ███ ███    ███ ▀▀███▀▀▀     
  ███    ███ ███    ███ ███    ███   ███    █▄  
  ███    ███ ███   ▄███ ███   ▄███   ███    ███ 
  ███    █▀  ████████▀  ████████▀    ██████████ 
                                                
 ]],
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 2 },
        { section = "recent_files", padding = 1 },
        { section = "startup" },
      },
    },
  },
}
