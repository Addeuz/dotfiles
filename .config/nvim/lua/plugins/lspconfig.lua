return {
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
}
