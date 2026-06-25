return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          cmd = { "qmlls" },
          filetypes = { "qml" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("CMakeLists.txt", "*.pro", ".git")(fname) or vim.fn.getcwd() -- fallback al directorio actual
          end,
        },
      },
    },
  },
}
