--------------------------------------------------------------------
--- Core settings: monitor, autostart, input, misc, permissions, env ---
--------------------------------------------------------------------

----------------
--- MONITORS ---
----------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Runs at 144Hz by default. A script drops it to 60Hz on battery (ACPI events),
-- so avoid `hyprctl reload` on battery: it re-applies 144Hz.
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@144",
	position = "auto",
	scale = "1",
})

-----------------
--- AUTOSTART ---
-----------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- hyprpolkitagent, mpd and mpDris2 are managed by systemd user services, not started here.
hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm-app -- awww-daemon")
	hl.exec_cmd("uwsm-app -- hypridle")
	hl.exec_cmd("uwsm-app -- playerctld")
	hl.exec_cmd("uwsm-app -- waybar")
	hl.exec_cmd("uwsm-app -- wl-paste --type text --watch cliphist store") -- Stores only text data
	hl.exec_cmd("uwsm-app -- wl-paste --type image --watch cliphist store") -- Stores only image data
	hl.exec_cmd("sleep 2 && uwsm-app -- keepassxc")
	-- hl.exec_cmd("uwsm-app -- swaync")
end)

-------------
--- INPUT ---
-------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		-- kb_options = "caps:swapescape", -- Caps/Esc swap is done at kernel level instead
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
	render = {
		direct_scanout = 2,
	},
	xwayland = {
		force_zero_scaling = true,
	},
})

------------
--- MISC ---
------------

hl.config({
	ecosystem = {
		no_donation_nag = true,
		no_update_news = true,
	},
	misc = {
		enable_swallow = false,
		swallow_regex = "(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)",
		middle_click_paste = true,
		force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background
		disable_splash_rendering = true,
		vrr = 2,
	},
	binds = {
		workspace_back_and_forth = true,
		hide_special_on_workspace_change = true,
	},
})

-------------------
--- PERMISSIONS ---
-------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------

-- These can also live in ~/.config/uwsm/env (general) and ~/.config/uwsm/env-hyprland (Hyprland-only,
-- e.g. cursors). They are kept here for now.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
-- hl.env("XDG_SESSION_TYPE", "wayland")
-- hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Cursor and theme
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
hl.env("XCURSOR_SIZE", "27")
hl.env("HYPRCURSOR_SIZE", "27")

-- Hybrid graphics: Intel video decoding, NVIDIA for GLX
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("VK_DRIVER_FILES", "/usr/share/vulkan/icd.d/intel_icd.json")
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")

-- Force Aquamarine to exclusively use the DRM KMS backend
hl.env("AQ_FORCE_BACKEND", "drm")

-- Native Wayland support for most Electron apps
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Hardware video acceleration
-- hl.env("NVD_BACKEND", "direct")

-- Disable GSYNC
hl.env("__GL_GSYNC_ALLOWED", "0")

-- Qt style override
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- OBS Wayland support
hl.env("OBS_USE_EGL", "1")
