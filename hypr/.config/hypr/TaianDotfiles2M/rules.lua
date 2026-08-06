-- ============================================================================
-- Workspace Rules
-- ============================================================================

-- LG UltraGear (workspaces 1-5)
for i = 1, 5 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "HDMI-A-1",
		default = i == 1,
	})
end

-- Laptop (workspaces 6-10)
for i = 6, 10 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "eDP-1",
		default = i == 6,
	})
end

-- ============================================================================
-- Window Rules — System & Corrections
-- ============================================================================

-- Ignore maximization events (Standard XWayland fix)
hl.window_rule({
	name = "windowrule-1",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix "ghost windows" and rendering errors in XWayland
hl.window_rule({
	name = "windowrule-2",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- ============================================================================
-- Window Rules — Floating Windows & Utilities
-- ============================================================================

-- Kitty Floating (Floating terminal)
hl.window_rule({
	name = "windowrule-3",
	match = { class = "^(kitty-floating)$" },
	float = true,
	center = true,
	size = { 800, 500 },
})

-- Btop Floating
hl.window_rule({
	name = "windowrule-3.1",
	match = { class = "^(kitty-floating-btop)$" },
	float = true,
	center = true,
	size = { 1280, 900 },
})

hl.window_rule({
	name = "windowrule-3",
	match = { class = "^(kitty-floating)$" },
	float = true,
	center = true,
	size = { 800, 500 },
})

-- XDG Desktop Portal (File pickers, etc.)
hl.window_rule({
	name = "windowrule-4",
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	float = true,
})

-- Clipse (Clipboard manager)
hl.window_rule({
	name = "windowrule-5",
	match = { class = "(clipse)" },
	float = true,
	stay_focused = true,
	size = { 495, 450 },
})

-- ============================================================================
-- Window Rules — Specific Applications (Aesthetics)
-- ============================================================================

-- Brave Browser
--hl.window_rule({
--    name      = "windowrule-6",
--    match     = { class = "^(Brave-browser)$" },
--   no_blur   = true,
--    no_shadow = true,
--    opaque    = true,
--})

-- Tidal (Transparency)
--hl.window_rule({
--    name    = "windowrule-7",
--   match   = { class = "(tidal-hifi)" },
--    opacity = 0.85,
--})

-- VS Code
-- hl.window_rule({
--     name    = "windowrule-8",
--     match   = { class = "^(code-url-handler)$" },
--     opacity = 1,
-- })

--hl.window_rule({
--    name    = "windowrule-9",
--    match   = { class = "^(code)$" },
--    opacity = 1,
--})

-- ============================================================================
-- Layer Rules
-- ============================================================================

-- Rofi (Launcher)
--hl.layer_rule({
--    name         = "layerrule-1",
--    match        = { namespace = "rofi" },
--    blur         = true,
--    ignore_alpha = 0,
--    animation    = "popin",
--})

-- SwayNotificationCenter — Control center panel
--hl.layer_rule({
--    name         = "layerrule-2",
--    match        = { namespace = "swaync-control-center" },
--    blur         = true,
--    ignore_alpha = 0.5,
--    animation    = "fade",
--})

-- SwayNotificationCenter — Popup notification window
--hl.layer_rule({
--    name         = "layerrule-3",
--    match        = { namespace = "swaync-notification-window" },
--    blur         = true,
--    ignore_alpha = 0,
--    animation    = "slide left",
--})

-- Waybar (Status bar)
--hl.layer_rule({
--    name         = "layerrule-4",
--    match        = { namespace = "waybar" },
--    blur         = true,
--    ignore_alpha = 0,
--    animation    = "fade",
--})

-- Quickshell — Overview blur
hl.layer_rule({
	match = { namespace = "quickshell:overview-blur" },
	blur = true,
	ignore_alpha = 0.2,
})

-- Quickshell / Flare shell — Launcher
hl.layer_rule({
	name = "flare-launcher-blur",
	match = { namespace = "^flare_launcher$" },
	blur = true,
	ignore_alpha = 0.2,
})

hl.layer_rule({
	name = "flare-launcher-anim",
	match = { namespace = "^flare_launcher$" },
	animation = "slide bottom",
})

-- Quickshell / Flare shell — Theme
hl.layer_rule({
	name = "flare-theme-blur",
	match = { namespace = "^flare_theme$" },
	blur = true,
	ignore_alpha = 0.2,
})

hl.layer_rule({
	name = "flare-theme-anim",
	match = { namespace = "^flare_theme$" },
	animation = "slide bottom",
})

-- SwayOSD
hl.layer_rule({
	name = "layerrule-5",
	match = { namespace = "swayosd" },
	animation = "fade",
})

-- System Dialogs (Logout/Wlogout)
hl.layer_rule({
	name = "layerrule-6",
	match = { namespace = "logout_dialog" },
	blur = true,
	ignore_alpha = 0,
	animation = "fade",
})

-- Selection Tools — Signature
hl.layer_rule({
	name = "layerrule-7",
	match = { namespace = "signature" },
	blur = true,
	ignore_alpha = 0,
})

-- Selection Tools — Selection
hl.layer_rule({
	name = "layerrule-8",
	match = { namespace = "selection" },
	animation = "fade",
})

-- Satty
hl.window_rule({
	name = "satty",
	match = { class = "com.gabm.satty" },
	float = true,
	size = "800 500",
})

--hl.layer_rule({
--	name = "layerrule-9b",
--	match = { namespace = "popup" },
--	blur = true,
--	ignore_alpha = 0,
--	no_anim = true,
--})

-- Quickshell notifications panel
hl.layer_rule({
	name = "flare-notifications-anim",
	match = { namespace = "^flare_notifications_" },
	animation = "slide left",
	dim_around = false,
	blur = true,
	ignore_alpha = 0,
})
