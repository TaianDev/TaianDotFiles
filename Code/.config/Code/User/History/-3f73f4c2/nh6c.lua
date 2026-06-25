local hl = require("hyprland")

hl.config({
    env = {
        "XCURSOR_THEME,Sunset-cursors",
        "XCURSOR_SIZE,20",
        "GTK_THEME,adw-gtk3-dark",
        "LIBVA_DRIVER_NAME,iHD",
        "XDG_MENU_PREFIX,arch",
        "GDK_BACKEND,wayland,x11,*",
        "QT_QPA_PLATFORM,wayland;xcb",
        "SDL_VIDEODRIVER,wayland",
        "QT_QPA_PLATFORMTHEME,qt6ct",
        "CLUTTER_BACKEND,wayland"
    }
})