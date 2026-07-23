-- ============================================================================
-- Hyprland Core Configuration
-- ============================================================================
hl.config({

	-- ============================================================================
	-- General Layout & Borders
	-- ============================================================================
	general = {
		gaps_in = 5, -- Gaps between adjacent windows
		gaps_out = 9, -- Gaps between windows and screen edges
		border_size = 1, -- Width of the window border
		col = {
			active_border = "rgba(FFFFFF40)", -- Border color for the focused window
			inactive_border = "rgba(595959aa)", -- Border color for unfocused windows
		},
		resize_on_border = false, -- Dragging borders to resize windows
		allow_tearing = false, -- Screen tearing rules (for gaming latency)
		layout = "dwindle", -- Window layout engine (dwindle / master)
	},

	-- ============================================================================
	-- Scrolling & Column Navigation
	-- ============================================================================
	scrolling = {
		fullscreen_on_one_column = true,
		column_width = 0.8,
		focus_fit_method = 1,
		direction = "down",
	},

	-- ============================================================================
	-- Aesthetics, Shadows, & Blur Effects
	-- ============================================================================
	decoration = {
		-- Window Shadows
		shadow = {
			enabled = true,
			range = 20,
			render_power = 15,
			color = "rgba(0, 0, 0, 0.5)",
		},
		-- Background Blur behind transparent windows
		blur = {
			popups = true,
			enabled = true,
			new_optimizations = true,
			size = 4,
			passes = 4,
			contrast = 1,
			vibrancy = 0.2,
			vibrancy_darkness = 0.2,
			ignore_opacity = true,
		},
		-- Window Corner Rounding
		rounding = 4,
		rounding_power = 2,
		active_opacity = 1.0,
	},

	-- ============================================================================
	-- Miscellaneous Settings
	-- ============================================================================
	misc = {
		force_default_wallpaper = 0, -- 0 disables the default anime wallpapers
		disable_hyprland_logo = true, -- Disables the splash logo on startup
	},
})
