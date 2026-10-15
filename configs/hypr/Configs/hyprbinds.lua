---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Basics/Binds/
local vars = require("Configs.hyprvars")
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

---------------
--- Helpers ---
---------------

-- Run a different action depending on the current workspace's layout
local function layout_bind(bind_table)
	return function()
		local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
		if not workspace then
			return
		end

		local action = bind_table[workspace.tiled_layout]
		if action then
			hl.dispatch(action)
		end
	end
end

-- Toggle float, then size and center the window (used by the keybind and the gesture)
local function toggle_float_centered()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800 }))
	hl.dispatch(hl.dsp.window.center())
end

-- Cursor zoom: zoom(offset) steps by offset, zoom() toggles between 1x and ZOOM_TOGGLE_FACTOR
local MAX_ZOOM = 10
local MIN_ZOOM = 1
local ZOOM_TOGGLE_FACTOR = 1.5

local function zoom(offset)
	local current = hl.get_config("cursor.zoom_factor")
	if offset ~= nil then
		current = current + offset
	elseif current ~= MIN_ZOOM then
		current = MIN_ZOOM
	else
		current = ZOOM_TOGGLE_FACTOR
	end
	current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
	hl.config({ cursor = { zoom_factor = current } })
end

-- Game mode: no gaps, animations, blur, shadows or rounding. Toggling again restores
-- the values from hyprdeco.lua (no config reload, so the monitor refresh rate is untouched).
local game_mode = false

local function toggle_game_mode()
	if game_mode then
		local look = require("Configs.hyprdeco").look
		hl.config({
			general = {
				gaps_in = look.general.gaps_in,
				gaps_out = look.general.gaps_out,
				border_size = look.general.border_size,
			},
			animations = { enabled = look.animations.enabled },
			decoration = {
				rounding = look.decoration.rounding,
				shadow = { enabled = look.decoration.shadow.enabled },
				blur = { enabled = look.decoration.blur.enabled },
			},
		})
	else
		hl.config({
			general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
			animations = { enabled = false },
			decoration = {
				rounding = 0,
				shadow = { enabled = false },
				blur = { enabled = false },
			},
		})
	end
	game_mode = not game_mode
end

-- Cycle the layout of the current workspace
local function cycle_layout()
	local layouts = { "scrolling", "dwindle", "master", "monocle" }
	local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
	if not workspace then
		return
	end

	local next_layout = "dwindle"
	for i = 1, #layouts do
		if layouts[i] == workspace.tiled_layout then
			next_layout = layouts[(i % #layouts) + 1]
			break
		end
	end

	if workspace.special then
		hl.workspace_rule({ workspace = tostring(workspace.name), layout = next_layout })
	else
		hl.workspace_rule({ workspace = tostring(workspace.id), layout = next_layout })
	end
end

-------------------
--- Apps / misc ---
-------------------

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(vars.terminal))
hl.bind(mainMod .. " + K", hl.dsp.window.close())
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(vars.menu))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(vars.blur))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(vars.fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", toggle_float_centered)
hl.bind(mainMod .. " + J", layout_bind({ dwindle = hl.dsp.layout("togglesplit") }))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(vars.refreshRate))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(vars.emojis))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(vars.utilMenu))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(vars.clipboard))

-- For qbit, seanime and stremio
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(vars.seanime))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(vars.qbittorrent))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(vars.stremio))

-- Open wlogout menu
hl.bind("ALT + F4", hl.dsp.exec_cmd(vars.powerMenu))

-----------------------
--- Focus, move, size ---
-----------------------

-- Move focus
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + Tab", hl.dsp.window.cycle_next({}))

-- Move windows
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "down" }))

-- Resize windows
hl.bind(mainMod .. " + ALT + H", hl.dsp.window.resize({ x = -15, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + L", hl.dsp.window.resize({ x = 15, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -15, relative = true }), { repeating = true })
hl.bind(mainMod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y = 15, relative = true }), { repeating = true })

-------------------------------------
--- Scrolling and monocle layouts ---
-------------------------------------

-- Switch focus between columns (scrolling) or windows (monocle)
hl.bind(
	mainMod .. " + comma",
	layout_bind({
		scrolling = hl.dsp.layout("move -col"),
		monocle = hl.dsp.layout("cycleprev"),
	})
)
hl.bind(
	mainMod .. " + period",
	layout_bind({
		scrolling = hl.dsp.layout("move +col"),
		monocle = hl.dsp.layout("cyclenext"),
	})
)

-- Swap columns
hl.bind(mainMod .. " + SHIFT + comma", layout_bind({ scrolling = hl.dsp.layout("swapcol l") }))
hl.bind(mainMod .. " + SHIFT + period", layout_bind({ scrolling = hl.dsp.layout("swapcol r") }))

-- Resize the focused column
hl.bind(
	mainMod .. " + ALT + comma",
	layout_bind({ scrolling = hl.dsp.layout("colresize -0.05") }),
	{ repeating = true }
)
hl.bind(
	mainMod .. " + ALT + period",
	layout_bind({ scrolling = hl.dsp.layout("colresize +0.05") }),
	{ repeating = true }
)

-- Pull the window into the previous/next column, or push it out into its own column
hl.bind(mainMod .. " + bracketleft", layout_bind({ scrolling = hl.dsp.layout("consume_or_expel prev") }))
hl.bind(mainMod .. " + bracketright", layout_bind({ scrolling = hl.dsp.layout("consume_or_expel next") }))

-- Center current window
hl.bind(mainMod .. " + C", layout_bind({ scrolling = hl.dsp.layout("fit active") }))

-- Cycle layouts for the current workspace
hl.bind(mainMod .. " + O", cycle_layout)

---------------------------
--- Wallpaper and shots ---
---------------------------

-- Wallpaper selector
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(vars.wallpaper .. " --menu"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(vars.wallpaper .. " --random"))

-- Screenshots using grim + slurp
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(vars.screenshot .. " --smart")) -- Save without edit
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd(vars.screenshot .. " --smart --edit")) -- Save and exit
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(vars.screenshot .. " --fullscreen")) -- Fullscreen

------------------
--- Workspaces ---
------------------

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace for music
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(vars.music))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:music" }))

-- Special workspace for scratchpad
hl.bind(mainMod .. " + N", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move between workspaces using keyboard keys
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.focus({ workspace = "e-1" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------
--- Zoom, pin and game mode  ---
--------------------------------

hl.bind(mainMod .. " + Z", function()
	zoom()
end)
hl.bind(mainMod .. " + equal", function()
	zoom(0.25)
end, { repeating = true })
hl.bind(mainMod .. " + minus", function()
	zoom(-0.25)
end, { repeating = true })

-- Pin the active window (handy for Picture-in-Picture)
hl.bind(mainMod .. " + P", hl.dsp.window.pin())

-- Game mode / battery saving mode
hl.bind(mainMod .. " + ALT + G", toggle_game_mode)

-----------------
--- Media keys ---
-----------------

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

----------------
--- Gestures ---
----------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/

-- Pinch in to zoom in
hl.gesture({
	fingers = 2,
	direction = "pinchin",
	mods = "SUPER",
	action = "cursor_zoom",
	zoom_level = 1.1,
	mode = "live",
})

-- Pinch out to zoom out
hl.gesture({
	fingers = 2,
	direction = "pinchout",
	mods = "SUPER",
	action = "cursor_zoom",
	zoom_level = 0.9,
	mode = "live",
})

-- Scroll within layout
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "scroll_move",
})

-- Move between workspaces
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	mods = "SUPER",
	scale = 0.4,
	action = "workspace",
})

-- Open app launcher
hl.gesture({
	fingers = 3,
	direction = "up",
	action = function()
		hl.exec_cmd(vars.menu)
	end,
})

-- Switch to float
hl.gesture({
	fingers = 3,
	direction = "up",
	mods = "SUPER",
	action = toggle_float_centered,
})

-- Open music workspace
hl.gesture({
	fingers = 3,
	direction = "down",
	action = function()
		hl.exec_cmd(vars.music)
	end,
})

-- Resize focused window
hl.gesture({
	fingers = 3,
	direction = "down",
	mods = "SUPER",
	action = "resize",
})
