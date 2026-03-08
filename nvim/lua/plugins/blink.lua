return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      menu = {
        -- Esto añade un pequeño margen entre la cmdline y el menú
        offset = { 10, 0 },
        draw = {
          columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
        },
      },
    },
  },
}
