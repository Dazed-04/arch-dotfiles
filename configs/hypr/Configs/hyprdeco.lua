local colors = require("Configs.hyprcolor")

hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 10,
		border_size = 0,

		col = {
			-- active_border = colors.active_border,
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
			color = "0x1a1a1aee",
		},

		blur = {
			enabled = true,
			size = 4,
			passes = 3,
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
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("Default", {
	type = "bezier",
	points = { { 0, 0.75 }, { 0.15, 1 } },
})

hl.animation({
	leaf = "global",
	enabled = true,
	speed = 4,
	bezier = "Default",
})

hl.config({
	dwindle = {
		preserve_split = true,
		force_split = 0,
	},
})

hl.config({
	master = {
		new_status = "master",
	},
})

hl.config({
	scrolling = {
		direction = "right",
		column_width = 0.8,
		fullscreen_on_one_column = true,
	},
})

----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		vrr = 2,
	},
})

hl.config({
	binds = {
		workspace_back_and_forth = true,
		hide_special_on_workspace_change = true,
	},
})
