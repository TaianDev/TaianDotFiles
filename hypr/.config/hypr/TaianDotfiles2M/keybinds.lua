-- ============================================================================
-- Variables & Configuration
-- ============================================================================
local mainMod = "SUPER"

-- ============================================================================
-- Shell Panels & Widgets (Quickshell IPC controls)
-- ============================================================================
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("qs ipc call theme_panel toggle"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs ipc call app_launcher toggle"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("qs ipc call music_popup toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications_panel toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("qs ipc call network_popup toggle"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("qs ipc call date_popup toggle"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("qs ipc -c overview call overview toggle"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("qs ipc -c overview call overview toggle"))
-- ============================================================================
-- Window Management & Focus Control
-- ============================================================================
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("env IS_FLOATING=1 kitty --class kitty-floating"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", function()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end)
--hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
--hl.bind(mainMod .. " + F", function()
--	local w = hl.get_active_window()
--	local c = w ~= nil and w.fullscreen_client or 0
--	hl.dispatch(hl.dsp.window.fullscreen_state({ client = c, internal = 1, action = "toggle" }))
--end)
-- Directional Focus
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Window Resizing & Mouse Actions
hl.bind(
	mainMod .. " + SHIFT + UP",
	hl.dsp.window.resize({ x = 0, y = -20, relative = true }),
	{ repeating = true, locked = true }
)
hl.bind(
	mainMod .. " + SHIFT + DOWN",
	hl.dsp.window.resize({ x = 0, y = 20, relative = true }),
	{ repeating = true, locked = true }
)
hl.bind(
	mainMod .. " + SHIFT + LEFT",
	hl.dsp.window.resize({ x = -20, y = 0, relative = true }),
	{ repeating = true, locked = true }
)
hl.bind(
	mainMod .. " + SHIFT + RIGHT",
	hl.dsp.window.resize({ x = 20, y = 0, relative = true }),
	{ repeating = true, locked = true }
)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ============================================================================
-- Workspaces (Navigation & Window Placement)
-- ============================================================================
-- Dynamically binds keys 1 to 9, and key 0 to Workspace 10
for i = 1, 10 do
	local key = tostring(i % 10) -- Converts 10 to "0", keeping 1-9 as they are.

	-- Focus workspace (SUPER + [1-0])
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))

	-- Move window to workspace (SUPER + SHIFT + [1-0])
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i), follow = true }))
end

-- Special Workspace (Scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.focus({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))

-- ============================================================================
-- Hardware, Media, & Display Controls
-- ============================================================================
-- Audio Controls
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume raise"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
	{ repeating = true, locked = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ repeating = true, locked = true }
)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { repeating = true, locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { repeating = true, locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { repeating = true, locked = true })

-- Brightness Controls
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +5"), { repeating = true, locked = true })
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("swayosd-client --brightness lower"),
	{ repeating = true, locked = true }
)

-- Blue Light Filter
--hl.bind(
--	"SHIFT + ALT + D",
--	hl.dsp.exec_cmd(
--		[[hyprctl hyprsunset temperature -300 && notify-send -r 555 -t 1000 -h string:x-canonical-private-synchronous:volume_notif -i weather-clear "Filtro de LUZ AZUL" "> Aumentando intensidad del filtro [+]"]]
--	),
--	{ repeating = true, locked = true }
--)
--hl.bind(
--	"SHIFT + ALT + A",
--	hl.dsp.exec_cmd(
--		[[hyprctl hyprsunset temperature +300 && notify-send -r 555 -t 1000 -h string:x-canonical-private-synchronous:volume_notif -i weather-clear "Filtro de LUZ AZUL" "> Disminuyendo intensidad del filtro [-]"]]
--	),
--	{ repeating = true, locked = true }
--)

-- ============================================================================
-- Screenshots & Media Capture
-- ============================================================================
-- Fullscreen
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -o ~/Imágenes/Screenshots/All_display/"))
-- Region
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Imágenes/Screenshots/Regions/"))
-- Window
hl.bind("SHIFT + Print + P", hl.dsp.exec_cmd("hyprshot -m window -o ~/Imágenes/Screenshot/Windows/"))

-- ============================================================================
-- System Utilities & Applications
-- ============================================================================
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.config/wlogout/launcher.sh"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nemo"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("kitty --class clipse -e clipse"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("quickshell -c ~/.config/quickshell/modules/lockscreen/"))
