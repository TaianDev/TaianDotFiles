--[[
-- Initialize lists for different bind types
local bind_list = {
    -- WINDOWS AND TERMINAL
    "$mainMod, Q, exec, $terminal",
    "$mainMod SHIFT, Q, exec, env IS_FLOATING=1 kitty --class kitty-floating",
    "$mainMod, C, killactive,",
    "$mainMod, V, exec, hyprctl dispatch togglefloating",
    "$mainMod, F, fullscreen, toggle",
    "$mainMod, left, movefocus, l",
    "$mainMod, right, movefocus, r",
    "$mainMod, up, movefocus, u",
    "$mainMod, down, movefocus, d",

    -- SPECIAL WORKSPACES
    "$mainMod, S, togglespecialworkspace, magic",
    "$mainMod SHIFT, S, movetoworkspace, special:magic",
    "SUPER, TAB, exec, qs ipc -c overview call overview toggle",

    -- SCREENSHOTS (HYPRSHOT)
    ", Print, exec, hyprshot -m output -o ~/Imágenes/Screenshots/All_display/",
    "RSHIFT, Print, exec, hyprshot -m region -o ~/Imágenes/Screenshots/Regions/",
    ", Print P, exec, hyprshot -m window -o ~/Imágenes/Screenshot/Windows/",

    -- HYPRWAVE
    "$mainMod SHIFT, W, exec, hyprwave-toggle visibility",
    "$mainMod, W, exec, hyprwave-toggle expand",

    -- OTHER BINDS
    "$mainMod, M, exec, ~/.config/wlogout/launcher.sh",
    "$mainMod SHIFT, M, exit,",
    "$mainMod, E, exec, $fileManager",
    "$mainMod SHIFT, E, exec, zen-browser",
    "$mainMod, R, exec, $menu",
    -- "$mainMod, X, hyprexpo:expo, toggle",
    "$mainMod, Z, exec, kitty --class clipse -e clipse",
    "$mainMod SHIFT, Z, exec, ~/Personal_Scripts/Set_Target/set-target",
    "$mainMod, N, exec, swaync-client -t",
    "$mainMod, L, exec, hyprlock",
    "$mainMod, B, exec, killall -SIGUSR1 waybar"
}

local bindel_list = {
    -- WINDOW RESIZING
    "$mainMod SHIFT, UP, resizeactive, 0 -20",
    "$mainMod SHIFT, DOWN, resizeactive, 0 20",
    "$mainMod SHIFT, LEFT, resizeactive, -20 0",
    "$mainMod SHIFT, RIGHT, resizeactive, 20 0",

    -- SOUND AND BRIGHTNESS
    ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise",
    ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower",
    ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle",
    ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
    ", XF86AudioPlay, exec, playerctl play-pause",
    ", XF86AudioNext, exec, playerctl next",
    ", XF86AudioPrev, exec, playerctl previous",
    ", XF86MonBrightnessUp, exec, swayosd-client --brightness +5",
    ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower",

    -- HYPRSUNSET BLUE LIGHT FILTER
    "SHIFT ALT, D, exec, hyprctl hyprsunset temperature -300 && notify-send -r 555 -t 1000 -h string:x-canonical-private-synchronous:volume_notif -i weather-clear 'Filtro de LUZ AZUL' '> Aumentando intensidad del filtro [+]'",
    "SHIFT ALT, A, exec, hyprctl hyprsunset temperature +300 && notify-send -r 555 -t 1000 -h string:x-canonical-private-synchronous:volume_notif -i weather-clear 'Filtro de LUZ AZUL' '> Disminuyendo intensidad del filtro [-]'",
}

local bindm_list = {
    -- MOUSE BINDS
    "$mainMod, mouse:272, movewindow",
    "$mainMod SHIFT, mouse:272, resizewindow",
}

-- AUTOMATION FOR WORKSPACES 1 TO 10
for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    table.insert(bind_list, "$mainMod, " .. key .. ", workspace, " .. i)
    table.insert(bind_list, "$mainMod SHIFT, " .. key .. ", movetoworkspace, " .. i)
end

-- Apply configuration to Hyprland
hl.config({
    bind = bind_list,
    bindel = bindel_list,
    bindm = bindm_list
})
--]]
local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = "nemo"
local menu        = "rofi -show drun -theme ~/.config/rofi/style-7.rasi"

-- WINDOWS AND TERMINAL
hl.bind(mainMod .. " + Q",       hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("env IS_FLOATING=1 kitty --class kitty-floating"))
hl.bind(mainMod .. " + C",       hl.dsp.window.close())
hl.bind(mainMod .. " + V",       hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",       hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + left",    hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right",   hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",      hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",    hl.dsp.focus({ direction = "d" }))

-- SPECIAL WORKSPACES
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special({ workspace = "magic" }))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind("SUPER + TAB",             hl.dsp.exec_cmd("qs ipc -c overview call overview toggle"))

-- SCREENSHOTS
hl.bind("Print",         hl.dsp.exec_cmd("hyprshot -m output -o ~/Imágenes/Screenshots/All_display/"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Imágenes/Screenshots/Regions/"))

-- HYPRWAVE
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("hyprwave-toggle visibility"))
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("hyprwave-toggle expand"))

-- OTHER BINDS
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("~/.config/wlogout/launcher.sh"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Z",         hl.dsp.exec_cmd("kitty --class clipse -e clipse"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("~/Personal_Scripts/Set_Target/set-target"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

-- WINDOW RESIZING (con repeating)
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -20}), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 20}), { repeating = true })
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ delta = {-20, 0} }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ delta = {20,  0} }), { repeating = true })

-- SOUND AND BRIGHTNESS (con locked + repeating)
local audioOpts = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume raise"),       audioOpts)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("swayosd-client --output-volume lower"),       audioOpts)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),    { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("swayosd-client --brightness +5"),    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })

-- HYPRSUNSET
hl.bind("SHIFT + ALT + D", hl.dsp.exec_cmd("hyprctl hyprsunset temperature -300 && notify-send -r 555 -t 1000 -i weather-clear 'Filtro de LUZ AZUL' '> Aumentando intensidad del filtro [+]'"))
hl.bind("SHIFT + ALT + A", hl.dsp.exec_cmd("hyprctl hyprsunset temperature +300 && notify-send -r 555 -t 1000 -i weather-clear 'Filtro de LUZ AZUL' '> Disminuyendo intensidad del filtro [-]'"))

-- MOUSE BINDS
hl.bind(mainMod .. " + mouse:272",         hl.dsp.window.move())
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize())

-- WORKSPACES 1 AL 10
for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end