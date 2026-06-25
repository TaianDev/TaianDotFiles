local hl = require("hyprland")


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