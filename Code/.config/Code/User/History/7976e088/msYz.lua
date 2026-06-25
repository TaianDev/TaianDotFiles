-- Default workspaces
-- LG UltraGear
hl.workspace_rule({ workspace = "1",  monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "2",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "3",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "4",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "5",  monitor = "HDMI-A-1" })

-- Laptop
hl.workspace_rule({ workspace = "6",  monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "7",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "8",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "9",  monitor = "eDP-1" })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })

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

-- Kitty Floating
hl.window_rule({
    name   = "windowrule-3",
    match  = { class = "^(kitty-floating)$" },
    float  = true,
    center = true,
    size   = { 800, 500 },
})

-- XDG Desktop Portal
hl.window_rule({
    name  = "windowrule-4",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
})

-- Clipse
hl.window_rule({
    name        = "windowrule-5",
    match       = { class = "(clipse)" },
    float       = true,
    stay_focused = true,
    size        = { 495, 450 },
})

-- Brave Browser
hl.window_rule({
    name      = "windowrule-6",
    match     = { class = "^(Brave-browser)$" },
    no_blur   = true,
    no_shadow = true,
    opaque    = true,
})

-- Tidal
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

-- Rofi
hl.layer_rule({
    name         = "layerrule-1",
    match        = { namespace = "rofi" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "popin",
})

-- SwayNotificationCenter

-- Control panel
hl.layer_rule({
    name         = "layerrule-2",
    match        = { namespace = "swaync-control-center" },
    blur         = true,
    ignore_alpha = 0.5,
    animation    = "fade",
})

-- Notifications
hl.layer_rule({
    name         = "layerrule-3",
    match        = { namespace = "swaync-notification-window" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "slide left",
})

-- ── Waybar (Barra) 
hl.layer_rule({
    name         = "layerrule-4",
    match        = { namespace = "waybar" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "fade",
})

-- ── SwayOSD 
hl.layer_rule({
    name      = "layerrule-5",
    match     = { namespace = "swayosd" },
    animation = "fade",
})

-- ── Wlogout (system dialogs)
hl.layer_rule({
    name         = "layerrule-6",
    match        = { namespace = "logout_dialog" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "fade",
})

-- ── Selection tools─────────
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

-- ── Popups Brave ───────────────────────────────
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
