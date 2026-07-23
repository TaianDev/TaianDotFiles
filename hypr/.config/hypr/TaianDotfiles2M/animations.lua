-- ============================================================================
-- Bezier Curves
-- ============================================================================
-- overshot: subtle elastic bounce for the "drop" window entry effect
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.03 } } })
-- md3_decel / md3_accel: smooth Material Design transitions
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
-- menu_decel / menu_accel: responsive menu and layer animations
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.38, 0.04 }, { 1, 0.07 } } })
-- softAcDecel: clean, modern workspace sliding
hl.curve("softAcDecel", { type = "bezier", points = { { 0.26, 0.26 }, { 0.15, 1 } } })

-- ============================================================================
-- Window Animations — "Drop" Effect
-- ============================================================================
-- Windows emerge from the bottom edge with an elastic overshot curve,
-- creating a smooth "drop" / rising panel feel.
-- CORREGIDO: el campo se llama `bezier`, no `curve` (con `curve` la animación
-- caía silenciosamente a la curva "default", más rápida/lineal que "overshot").
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "overshot", style = "slide bottom" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "overshot", style = "slide bottom" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "md3_accel", style = "slide bottom" })

-- ============================================================================
-- Border Animation
-- ============================================================================
-- CORREGIDO: bezier en vez de curve
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })

-- ============================================================================
-- Fade Animations
-- ============================================================================
-- CORREGIDO: bezier en vez de curve
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 3, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 5, bezier = "menu_accel" })

-- ============================================================================
-- Layer Animations
-- ============================================================================
-- CORREGIDO: bezier en vez de curve
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "menu_accel", style = "slide" })

-- ============================================================================
-- Workspace Animations — Horizontal Slide
-- ============================================================================
-- Slide horizontal puro, rápido, con un ligero rebote al llegar (usa la curva
-- "overshot" ya definida arriba, que tiene un leve overshoot elástico).
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "md3_decel", style = "slidevert" })
