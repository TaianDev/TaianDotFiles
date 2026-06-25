-- ============================================================
--  WINDOW RULES
-- ============================================================

-- Ignorar eventos de maximización (Standard XWayland fix)
hl.window_rule({
    name  = "windowrule-1",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Reparar "ghost windows" y errores de dibujado en XWayland
hl.window_rule({
    name  = "windowrule-2",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- ── Ventanas Flotantes y Utilitarios ──────────────────────────

-- Kitty Floating (Terminal flotante)
hl.window_rule({
    name   = "windowrule-3",
    match  = { class = "^(kitty-floating)$" },
    float  = true,
    center = true,
    size   = { 800, 500 },
})

-- XDG Desktop Portal (Selectores de archivos, etc.)
hl.window_rule({
    name  = "windowrule-4",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
})

-- Clipse (Portapapeles)
hl.window_rule({
    name        = "windowrule-5",
    match       = { class = "(clipse)" },
    float       = true,
    stay_focused = true,
    size        = { 495, 450 },
})

-- ── Aplicaciones Específicas (Estética) ──────────────────────

-- Brave Browser
-- Nota: Al aplicar a la clase general ya cubre ventanas normales y popups/flotantes.
hl.window_rule({
    name      = "windowrule-6",
    match     = { class = "^(Brave-browser)$" },
    no_blur   = true,
    no_shadow = true,
    opaque    = true,
})

-- Tidal (Transparencia)
hl.window_rule({
    name    = "windowrule-7",
    match   = { class = "(tidal-hifi)" },
    opacity = 0.85,
})

-- VS-Code
-- hl.window_rule({
--     name    = "windowrule-8",
--     match   = { class = "^(code-url-handler)$" },
--     opacity = 1,
-- })

hl.window_rule({
    name    = "windowrule-9",
    match   = { class = "^(code)$" },
    opacity = 1,
})


-- ============================================================
--  LAYER RULES
-- ============================================================

-- ── Rofi (Lanzador) ──────────────────────────────────────────
hl.layer_rule({
    name         = "layerrule-1",
    match        = { namespace = "rofi" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "popin",
})

-- ── SwayNotificationCenter (Notificaciones) ──────────────────

-- Panel de control
hl.layer_rule({
    name         = "layerrule-2",
    match        = { namespace = "swaync-control-center" },
    blur         = true,
    ignore_alpha = 0.5,
    animation    = "fade",
})

-- Ventana de notificación emergente
hl.layer_rule({
    name         = "layerrule-3",
    match        = { namespace = "swaync-notification-window" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "slide left",
})

-- ── Waybar (Barra) ───────────────────────────────────────────
hl.layer_rule({
    name         = "layerrule-4",
    match        = { namespace = "waybar" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "fade",
})

-- ── SwayOSD (Volumen/Brillo en pantalla) ─────────────────────
hl.layer_rule({
    name      = "layerrule-5",
    match     = { namespace = "swayosd" },
    animation = "fade",
})

-- ── Diálogos de Sistema (Logout/Wlogout) ─────────────────────
hl.layer_rule({
    name         = "layerrule-6",
    match        = { namespace = "logout_dialog" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "fade",
})

-- ── Herramientas de Selección (Slurp/Grim) ───────────────────
hl.layer_rule({
    name         = "layerrule-7",
    match        = { namespace = "signature" },
    blur         = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    name      = "layerrule-8",
    match     = { namespace = "selection" },
    animation = "fade",
})

-- ── Popups Específicos de Brave ───────────────────────────────
-- NOTA: La regla original tenía dos match:namespace en un solo bloque,
-- lo cual es inválido. Se divide en dos reglas separadas.
hl.layer_rule({
    name         = "layerrule-9a",
    match        = { namespace = "^(Brave-browser)$" },
    blur         = true,
    ignore_alpha = 0,
    no_anim      = true,
})

hl.layer_rule({
    name         = "layerrule-9b",
    match        = { namespace = "popup" },
    blur         = true,
    ignore_alpha = 0,
    no_anim      = true,
})

-- ── Hyprwave ─────────────────────────────────────────────────
hl.layer_rule({
    name         = "layerrule-10",
    match        = { namespace = "hyprwave" },
    blur         = true,
    ignore_alpha = 0,
    no_anim      = true,
})

-- hl.layer_rule({
--     name         = "layerrule-11",
--     match        = { namespace = "gtk-layer-shell" },
--     blur         = true,
--     blur_popups  = true,
--     ignore_alpha = 1,
-- })
