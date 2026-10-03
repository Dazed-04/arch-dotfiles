----------------
--- MONITORS ---
----------------

-- See https://wiki.hypr.land/Configuring/Monitors/
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@144",
	position = "auto",
	scale = "1",
})

-------------------
--- MY PROGRAMS ---
-------------------

-- See https://wiki.hypr.land/Configuring/Keywords/

-- Set programs that you use
Terminal = "kitty"
FileManager = "thunar"
Menu = "bash $HOME/.local/bin/myScripts/utilities/menu_launcher.sh"
Music = "bash $HOME/.config/hypr/scripts/toggleMusic.sh"

-----------------
--- AUTOSTART ---
-----------------

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:

hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm app -- awww-daemon")
	hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store") -- Stores only text data
	hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store") -- Stores only image data
	hl.exec_cmd("uwsm app -- waybar")
	hl.exec_cmd("uwsm app -- playerctld")
	hl.exec_cmd("uwsm app -- hypridle")
	hl.exec_cmd("sleep 1 && uwsm app -- keepassxc")
	--hl.exec_cmd("uwsm app –- swaync")
end)

-------------
--- INPUT ---
-------------

-- https://wiki.hypr.land/Configuring/Variables/#input
hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		repeat_rate = 35,
		repeat_delay = 250,

		follow_mouse = 1,

		-- Disables mouse acceleration
		accel_profile = "flat",
		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs for more
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

----------------
--- Gestures ---
----------------

-- Pinch in to zoom in
hl.gesture({
	fingers = 2,
	direction = "pinchin",
	mods = "SUPER",
	action = "cursorZoom",
	---@diagnostic disable-next-line: assign-type-mismatch
	zoom_level = "1.1",
	mode = "live",
})

-- Pinch out to zoom out
hl.gesture({
	fingers = 2,
	direction = "pinchout",
	mods = "SUPER",
	action = "cursorZoom",
	---@diagnostic disable-next-line: assign-type-mismatch
	zoom_level = "0.9",
	mode = "live",
})

-- move between workspaces
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	mods = "SUPER",
	scale = 0.5,
	action = "workspace",
})

-- scroll within layout
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "scroll_move",
})

-- open app launcher
hl.gesture({
	fingers = 3,
	direction = "up",
	action = function()
		hl.exec_cmd(Menu)
	end,
})

-- switch to Full screen
hl.gesture({
	fingers = 3,
	direction = "up",
	mods = "SUPER",
	action = "fullscreen",
})

-- open music workspace
hl.gesture({
	fingers = 3,
	direction = "down",
	action = function()
		hl.exec_cmd(Music)
	end,
})

-- switch to Float
hl.gesture({
	fingers = 3,
	direction = "down",
	mods = "SUPER",
	action = function()
		hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
		hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800 }))
		hl.dispatch(hl.dsp.window.center())
	end,
})

-------------------
--- PERMISSIONS ---
-------------------

-- See https://wiki.hypr.land/Configuring/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------

-- Set them in ~/.config/uwsm/env & env-hyprland
-- In env put majority of environment variables
-- In env-hyprland put hyprland related environment variables (cursors, themes etc.)

-- See https://wiki.hypr.land/Configuring/Environment-variables/
--hl.env("XDG_CURRENT_DESKTOP",  "Hyprland")
--hl.env("XDG_SESSION_TYPE",    "wayland")
--hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Environment-variables for themes
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
hl.env("XCURSOR_SIZE", "27")
hl.env("HYPRCURSOR_SIZE", "27")

-------------------------------------------
--- Rules to make apps work with nvidia ---
-------------------------------------------

-- Environment-variables needed for Nvidia GPU
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("GBM_BACKEND",               "nvidia-drm")

-- To enable native Wayland support for most Electron apps
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- To enable hardware video acceleration
hl.env("NVD_BACKEND", "direct")

-- To disable GSYNC
hl.env("__GL_GSYNC_ALLOWED", "0")

-- Qt style override
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- Obs Wayland support
hl.env("OBS_USE_EGL", "1")
