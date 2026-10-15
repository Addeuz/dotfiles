-- LazyVim's kind_filter plus Variable/Constant, so `export const fn = () => {}` shows up
local function workspace_symbol_filter()
  local filter = vim.deepcopy(LazyVim.config.kind_filter)
  for ft, kinds in pairs(filter) do
    if type(kinds) == "table" then
      vim.list_extend(kinds, { "Variable", "Constant" })
    end
  end
  return filter
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        exclude = { "svelte" },
      },
      servers = {
        -- installed via mason from a previously-enabled lang.markdown extra;
        -- mason-lspconfig's automatic_enable would otherwise still attach it,
        -- and it indexes the whole workspace root on every markdown buffer
        marksman = { enabled = false },
        -- also installed via mason; attaching next to vtsls doubles every
        -- reference and completion result in TS buffers
        tsgo = { enabled = false },
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "none" },
                parameterTypes = { enabled = false },
                variableTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = false },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
            javascript = {
              inlayHints = {
                parameterNames = { enabled = "none" },
                parameterTypes = { enabled = false },
                variableTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = false },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          },
        },
        tailwindcss = {
          settings = {
            tailwindCSS = {
              -- classAttributes replaces the server defaults, so it must repeat them.
              -- Entries are spliced into a regex, so patterns need no delimiters.
              classAttributes = { "class", "className", "ngClass", "class:list", "data-[a-z-]+" },
              classFunctions = { "tw", "twObj", "clsx", "cn", "tv", "color(Passive|Interactive)" },
            },
          },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    -- lists in opts tables are replaced on merge, so append to the default keys instead
    opts = function(_, opts)
      local keys = vim.tbl_get(opts, "servers", "*", "keys")
      -- stylua: ignore
      table.insert(keys, {
        "<leader>sS", function() Snacks.picker.lsp_workspace_symbols({ filter = workspace_symbol_filter() }) end,
        desc = "LSP Workspace Symbols", has = "workspace/symbols",
      })
    end,
  },
}
