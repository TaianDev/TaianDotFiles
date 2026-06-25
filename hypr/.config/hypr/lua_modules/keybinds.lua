local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = "nemo"
local menu        = "rofi -show drun -theme ~/.config/rofi/style-7.rasi"

-- WINDOWS AND TERMINAL (checked)
hl.bind(mainMod .. " + Q",       hl.dsp.exec_cmd(terminal)) 
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd(terminal, {float = true, size = { width = 0.6, height = 0.5 }})) -- HERE
hl.bind(mainMod .. " + C",       hl.dsp.window.close())
hl.bind(mainMod .. " + V",       hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",       hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + left",    hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right",   hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",      hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",    hl.dsp.focus({ direction = "d" }))

-- SPECIAL WORKSPACES (CHECKED)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special({ workspace = "magic" }))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + TAB",             hl.dsp.exec_cmd("qs ipc -c overview call overview toggle"))

-- SCREENSHOTS
hl.bind("Print",         hl.dsp.exec_cmd("hyprshot -m output -o ~/Imágenes/Screenshots/All_display/"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Imágenes/Screenshots/Regions/"))

-- HYPRWAVE (CHECKED)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("hyprwave-toggle visibility"))
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("hyprwave-toggle expand"))

-- OTHER BINDS
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("~/.config/wlogout/launcher.sh"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Z",         hl.dsp.exec_cmd(terminal .. "clipse", { float = true, size = { width = 0.35, height = 0.4 }}))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("~/Personal_Scripts/Set_Target/set-target"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

-- WINDOW RESIZING (con repeating)
local function resize(x, y)
    return function() hl.dispatch(hl.dsp.window.resize({ x = x, y = y })) end
end

hl.bind(mainMod .. " + SHIFT + up",    resize(0, -20), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  resize(0, 20),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + left",  resize(-20, 0), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", resize(20, 0),  { repeating = true })

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
hl.bind(mainMod .. " + mouse:272",         hl.dsp.window.drag())
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize())

-- WORKSPACES 1 AL 10
for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end