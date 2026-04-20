return {
  "folke/snacks.nvim",
  opts = {
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
