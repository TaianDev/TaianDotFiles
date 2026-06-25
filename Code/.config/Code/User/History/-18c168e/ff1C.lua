--API
local hl = require("hyprland")

-- General variables
TERMINAL = "kitty"
FILE_MANAGER = "nemo"
MENU = "rofi -show drun -theme ~/.config/rofi/style-7.rasi"

-- Modules
require("animations") --Ready
require("autostart") --Ready
require("env") --Ready
require("general") --Reaady
require("input")
require("keybinds")
require("monitors")
require("plugins")
require("rules")


hl.config({
    --General
    general = {
        gaps_in = 5,
        gaps_out = 9,
        border_size = 1,
        ["col.active_border"] = "rgba(FFFFFF40)",
        ["col.inactive_border"] = "rgba(595959aa)",
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle"
    },

    --Decoration
    decoration = {
        rounding = 4,
        rounding_power = 2,
        active_opacity = 1.0,
        --Shadow
        ["shadow:enabled"] = true,
        ["shadow:range"] = 20,
        ["shadow:render_power"] = 15,
        ["shadow:color"] = "rgba(0, 0, 0, 0.5)",

        --Blur
        ["blur:popups"] = true,
        ["blur:enabled"] = true,
        ["blur:new_optimizations"] = true,
        ["blur:size"] = 4,
        ["blur:passes"] = 4,
        ["blur:contrast"] = 1,
        ["blur:vibrancy"] = 0.2,
        ["blur:vibrancy_darkness"] = 0.2,
        ["blur:ignore_opacity"] = true
    },
    --Layout
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.8,
        focus_fit_method = 1,
        direction = "down"
    },
    workspace = {
        "1, layout:scrolling",
        "2, layout:scrolling"
    },
    master = {
        new_status = "master"
    },

    --Misc
    misc =  {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true
    }
})



