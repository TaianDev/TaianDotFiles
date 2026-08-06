-- ============================================================================
-- Keyboard & Mouse Input Configuration
-- ============================================================================
hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 0, -- Default sensitivity
		touchpad = {
			natural_scroll = false,
		},
	},
})

-- ============================================================================
-- Per-Device Layout Overrides
-- ============================================================================

-- Built-in Laptop Keyboard (Latin American layout)
hl.device({
	name = "at-translated-set-2-keyboard",
	kb_layout = "latam",
})

-- External Wireless Keyboard (US English layout with Compose key mapped to Right Ctrl)
hl.device({
	name = "compx-2.4g-wireless-receiver",
	kb_layout = "us",
	kb_variant = "altgr-intl",
	kb_options = "lv3:switch",
})

-- Aula F75 Mechanical Keyboard (US English layout with Spanish support via Compose key)
hl.device({
	name = "by-tech-gaming-keyboard",
	kb_layout = "us",
	kb_variant = "altgr-intl",
	kb_options = "lv3:switch",
})
