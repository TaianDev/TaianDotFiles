return {
  "folke/noice.nvim",
  opts = function(_, opts)
    -- Nos aseguramos de mantener las opciones que ya existan
    opts.views = opts.views or {}

    -- Ajustamos la caja donde escribes (subirla un poco)
    opts.views.cmdline_popup = {
      position = {
        row = 2, -- Fila 2 (bien arriba)
        col = "50%",
      },
    }

    -- Ajustamos el menú de sugerencias (bajarlo un poco)
    opts.views.popupmenu = {
      relative = "editor",
      position = {
        row = 5, -- Fila 5 (deja 3 líneas de espacio con la de arriba)
        col = "50%",
      },
      size = {
        width = 60,
        height = "auto",
      },
    }
  end,
}
