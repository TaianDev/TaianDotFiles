-- ============================================================================
-- Display & Monitor Layout Configuration
-- ============================================================================

-- Main Monitor (HDMI-A-1): 1080p @ 144Hz on the left (0x0)
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@144.00", position = "0x0", scale = "1" })

-- Secondary Laptop Screen (eDP-1): 768p @ 60Hz on the right (1920x0)
hl.monitor({ output = "eDP-1", mode = "1366x768@60.00", position = "1920x0", scale = "1" })