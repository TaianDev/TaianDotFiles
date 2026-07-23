-- ============================================================================
-- Hyprland Startup Applications & Daemons
-- ============================================================================

hl.on("hyprland.start", function()
	-- System & D-Bus Environment
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("gnome-keyring-daemon --start")

	-- Wallpaper & Visuals
	hl.exec_cmd("swww-daemon")
	hl.exec_cmd("hyprctl setcursor Sunset-cursors 24")

	-- System Trays & Indicators
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("blueman-applet")
	--hl.exec_cmd("kdeconnect-indicator")

	-- Utilities & Daemons (Fixed swayidle syntax here)
	--hl.exec_cmd("hyprpm reload -n")
	hl.exec_cmd("swayidle -w")
	hl.exec_cmd("GSK_RENDERER=gl swayosd-server --top-margin 0.95")
	hl.exec_cmd("clipse -listen")

	-- Shell & Panels
	hl.exec_cmd("qs -c overview")
	hl.exec_cmd("quickshell")
end)
