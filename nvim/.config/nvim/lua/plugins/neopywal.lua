return {
  {
    "RedsXDD/neopywal.nvim",
    name = "neopywal",
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = true,
      dim_inactive = true,
      terminal_colors = true,
      show_split_lines = true,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        keywords = { "bold" },
        functions = { "bold" },
        includes = { "italic" },
        types = { "italic" },
        variables = { "italic" },
        loops = {},
        strings = {},
        numbers = {},
        booleans = {},
        operators = {},
      },
      custom_highlights = function(C)
        return {
          NormalFloat = { bg = C.none },
          FloatBorder = { bg = C.none },
          Pmenu = { bg = C.none },
          PmenuSel = { bg = C.none, style = { "bold", "reverse" } },
          CursorLine = { bg = C.none, style = { "underline" } },
          SignColumn = { bg = C.none },
          LineNr = { bg = C.none },
          CursorLineNr = { bg = C.none, style = { "bold" } },
        }
      end,
      plugins = {
        telescope = { enabled = true },
        nvim_cmp = true,
        gitsigns = true,
        treesitter = true,
        lazy = true,
        indent_blankline = { enabled = true, colored_indent_levels = false },
        which_key = true,
        noice = true,
        notify = true,
        nvimtree = true,
        neotree = true,
        lsp = {
          enabled = true,
          virtual_text = {
            errors = { "bold", "italic" },
            hints = { "italic" },
            warnings = { "bold", "italic" },
          },
          underlines = {
            errors = { "undercurl" },
            warnings = { "undercurl" },
            hints = { "undercurl" },
          },
          inlay_hints = {
            background = true,
            style = { "italic" },
          },
        },
      },
    },
    config = function(_, opts)
      require("neopywal").setup(opts)
      vim.cmd.colorscheme("neopywal")

      -- Fix del hueco transparente en lualine:
      -- Se aplica ahora y cada vez que cambie el colorscheme.
      local function fix_lualine_gap()
        local ok, neopywal = pcall(require, "neopywal")
        if not ok then
          return
        end
        local C = neopywal.get_colors()
        local bg = C.background

        vim.api.nvim_set_hl(0, "StatusLine", { bg = bg })
        vim.api.nvim_set_hl(0, "StatusLineNC", { bg = bg })

        local modes = { "normal", "insert", "visual", "replace", "command", "terminal", "inactive" }
        for _, mode in ipairs(modes) do
          vim.api.nvim_set_hl(0, "lualine_c_" .. mode, { bg = bg, fg = C.foreground })
        end
      end

      -- Aplica inmediatamente después del colorscheme
      fix_lualine_gap()

      -- Re-aplica si se recarga el colorscheme (ej: pywal regenera colores)
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = fix_lualine_gap,
      })
    end,
  },
}
