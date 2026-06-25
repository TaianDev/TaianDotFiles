local hl = require('hyprland')

hl.config({
    exec_once = {
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "nm-applet --indicator",
        "hyprpm reload -n",
        "hyprsunset",
        "clipse -listen",
        "swww-daemon",
        "waybar",
        "swayidle -w before-sleep 'pgrep hyprlock || hyprlock'",
        "GSK_RENDERER=gl swayosd-server --top-margin 0.95",
        "hyprctl setcursor Sunset-cursors 24",
        "systemctl --user start hyprpolkitagent",
        "blueman-applet",
        "kdeconnect-indicator",
        "hyprwave",
        "qs -c overview"
    }
})