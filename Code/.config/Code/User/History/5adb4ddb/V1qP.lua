hl.config({
    input = {
        kb_layout    = "latam",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
    device = {
        -- Logitech mouse
        {
            name        = "logitech-g203-lightsync-gaming-mouse",
            sensitivity = 0.6,
        },
        -- Laptop keyboard
        {
            name      = "at-translated-set-2-keyboard",
            kb_layout = "latam",
        },
        -- Aula F75 (USB)
        {
            name       = "compx-2.4g-wireless-receiver",
            kb_layout  = "us",
            kb_options = "compose:rctrl",
        },
        -- Aula F75 (2.4 Ghz)
        {
            name       = "by-tech-gaming-keyboard-1",
            kb_layout  = "us",
            kb_options = "compose:rctrl",
        },
    },
})