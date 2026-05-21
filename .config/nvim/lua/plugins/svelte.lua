return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "svelte" then
            return
          end
          -- gp: jump to $props() declaration
          vim.keymap.set("n", "gp", function()
            if vim.fn.search("\\$props(", "w") == 0 then
              vim.notify("No props in file", vim.log.levels.INFO)
            end
          end, { buffer = args.buf, desc = "Go to $props()" })
          -- gm: jump to first markup line after </script>
          vim.keymap.set("n", "gm", function()
            local script_end = vim.fn.search("^</script>", "wn")
            if script_end == 0 then
              vim.notify("No markup in file", vim.log.levels.INFO)
              return
            end
            vim.api.nvim_win_set_cursor(0, { script_end, 0 })
            if vim.fn.search("^<", "") == 0 then
              vim.notify("No markup in file", vim.log.levels.INFO)
            end
          end, { buffer = args.buf, desc = "Go to markup" })
          -- gl: jump to <style> block
          vim.keymap.set("n", "gl", function()
            if vim.fn.search("^<style", "w") == 0 then
              vim.notify("No stylesheet in file", vim.log.levels.INFO)
            end
          end, { buffer = args.buf, desc = "Go to sty[l]esheet" })
        end,
      })
      return opts
    end,
  },
}
