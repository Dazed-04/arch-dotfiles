-----------------------
---- LOOK AND FEEL ----
-----------------------

local colors = require("Configs.hyprcolor")

local M = {}

-- Kept in a table so game mode (hyprbinds.lua) can restore these exact values.
M.look = {
	general = {
		gaps_in = 3,
		gaps_out = 10,
		border_size = 0,

		col = {
			active_border = colors.active_border,
			inactive_border = colors.inactive_border,
		},

		resize_on_border = false,
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 4,
		rounding_power = 10,

		active_opacity = 1.0,
		inactive_opacity = 0.9,

		dim_inactive = true,
		dim_strength = 0.15,

		border_part_of_window = true,

		shadow = {
			enabled = false,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a, -- 0xAARRGGBB
		},

		blur = {
			enabled = true,
			size = 6,
			passes = 4,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			popups = true,
			vibrancy = 0.1696,
			noise = 0.0117,
		},
	},

	animations = {
		enabled = true,
	},
}

hl.config(M.look)

-------------------
--- ANIMATIONS ---
-------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

-- Curves (only the ones in use)
hl.curve("smooth", { type = "bezier", points = { { 0, 0.75 }, { 0.15, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeOutCubic", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("easeOutQuart", { type = "bezier", points = { { 0.165, 0.84 }, { 0.44, 1 } } })

-- Springs
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
hl.curve("appleDefault", { type = "spring", mass = 1, stiffness = 600, dampening = 35 })
hl.curve("crispSnap", { type = "spring", mass = 1, stiffness = 300, dampening = 34.6 })
hl.curve("reactDefault", { type = "spring", mass = 1, stiffness = 550, dampening = 45 })
hl.curve("reactStiff", { type = "spring", mass = 1, stiffness = 410, dampening = 28 })
hl.curve("materialNoBounce", { type = "spring", mass = 1, stiffness = 200, dampening = 28.3 })

-- Base for anything not listed below
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "border", enabled = true, speed = 2.5, bezier = "easeOutQuart" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "appleDefault", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, spring = "crispSnap", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.6, spring = "reactDefault" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.7, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.8, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, spring = "reactStiff", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, spring = "materialNoBounce", style = "slide" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.8, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.4, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuart", style = "slidefade 50%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.3, bezier = "easeOutCubic", style = "slidefade 80%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.5, bezier = "easeInOutCubic", style = "slidefade 80%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3.5, bezier = "quick" })
hl.animation({
	leaf = "specialWorkspaceIn",
	enabled = true,
	speed = 6,
	bezier = "easeOutQuart",
	style = "slide top",
})
hl.animation({
	leaf = "specialWorkspaceOut",
	enabled = true,
	speed = 6,
	bezier = "easeOutQuart",
	style = "slide bottom",
})

---------------
--- LAYOUTS ---
---------------

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
	dwindle = {
		preserve_split = true,
		force_split = 0,
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
	master = {
		new_status = "master",
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
hl.config({
	scrolling = {
		direction = "right",
		column_width = 0.8,
		fullscreen_on_one_column = false,
		wrap_focus = true,
		follow_focus = true,
		focus_fit_method = 1,
		follow_min_visible = 0.3,
	},
})

return M
