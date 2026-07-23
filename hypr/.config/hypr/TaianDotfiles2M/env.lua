-- ============================================================================
-- Theme & Appearance (Cursors, GTK, and Qt styling)
-- ============================================================================
hl.env("XCURSOR_THEME", "Sunset-cursors")
hl.env("XCURSOR_SIZE", "20")
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- ============================================================================
-- Hardware Acceleration & Graphics Drivers
-- ============================================================================
hl.env("LIBVA_DRIVER_NAME", "iHD")

-- ============================================================================
-- Wayland & Toolkit Backends (Forces applications to run natively on Wayland)
-- ============================================================================
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- ============================================================================
-- Desktop Environment & System Integration
-- ============================================================================
hl.env("XDG_MENU_PREFIX", "arch-")
