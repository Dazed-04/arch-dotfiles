--------------------
--- WINDOW RULES ---
--------------------

-- See https://wiki.hypr.land/Configuring/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Workspace-Rules/ for workspace rules

-- Windowrule for applications

-- File Manager Rules
hl.window_rule({
	name = "float-thunar",
	match = {
		class = "Thunar",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Wlctl Window Rule
hl.window_rule({
	name = "float-wlctl",
	match = {
		class = "^(wlctl)$",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
})

-- Bluetui Window Rule
hl.window_rule({
	name = "float-bluetui",
	match = {
		class = "^(bluetui)$",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
})

-- Btop Window Rule
hl.window_rule({
	name = "float-btop",
	match = {
		class = "^(btop)$",
	},
	float = true,
	size = { 1400, 800 },
	center = true,
	decorate = true,
})

-- Satty Rules
hl.window_rule({
	name = "float-satty",
	match = {
		class = "com.gabm.satty",
		title = "satty",
	},
	float = true,
	size = { 1536, 864 },
	center = true,
	decorate = true,
	stay_focused = true,
})

-- Obs Preview Window Rules
hl.window_rule({
	name = "float-obs-preview",
	match = {
		class = "com.obsproject.Studio",
		title = ".*Video Capture Device.*",
	},
	float = true,
	pin = true,
	size = { 400, 300 },
	no_focus = true,
	move = "monitor_w-410 monitor_h-310",
})

-- Xdg Desktop Portal Rules
hl.window_rule({
	name = "float-xdg-desktop-portal-gtk",
	match = {
		class = "xdg-desktop-portal-gtk",
	},
	float = true,
	size = { 600, 500 },
	center = true,
	decorate = true,
	stay_focused = true,
})

-- Gimp Submenu Rules
hl.window_rule({
	name = "float-gimp-submenus",
	match = {
		class = "script-fu",
		initial_class = "script-fu",
	},
	float = true,
	size = { 600, 500 },
	center = true,
	decorate = true,
	stay_focused = true,
})

-- Gimp PDF viewer
hl.window_rule({
	name = "float-gimp-pdf",
	match = {
		class = "file-pdf-load",
		title = "Load PDF Image",
	},
	float = true,
	center = true,
	decorate = true,
	opacity = "0.8 0.8",
})

-- Zen Submenu Rules

-- Zen Download Submenu Rules
hl.window_rule({
	name = "float-zen-download-menu",
	match = {
		class = "zen",
		title = "Library",
	},
	float = true,
	center = true,
	stay_focused = true,
	decorate = true,
	size = { 900, 500 },
	opacity = "0.7 0.7",
})

-- Zen Save as Image Submenu Rules
hl.window_rule({
	name = "float-zen-save-image-as-menu",
	match = {
		class = "zen",
		title = "^(Save Image).*",
	},
	float = true,
	center = true,
	decorate = true,
	stay_focused = true,
	size = { 600, 500 },
	opacity = "0.7 0.7",
})

-- Zen File Upload Submenu Rules
hl.window_rule({
	name = "float-zen-file-upload-menu",
	match = {
		class = "zen",
		title = "^(File Upload).*",
	},
	float = true,
	center = true,
	decorate = true,
	stay_focused = true,
	size = { 900, 500 },
	opacity = "0.7 0.7",
})

-- Calculator Rules
hl.window_rule({
	name = "float-Qalculate",
	match = {
		class = "qalculate-gtk",
		title = "Qalculate!",
	},
	float = true,
	decorate = true,
	size = { 400, 400 },
	opacity = "0.8 0.8",
})

-- Rnote Rules
hl.window_rule({
	name = "float-Rnote",
	match = {
		class = "com.github.flxzt.rnote",
	},
	opacity = "0.8 0.8",
})

-- Image viewer rules
hl.window_rule({
	name = "float-imv",
	match = {
		class = "imv",
		title = "^(imv -).*",
	},
	float = true,
	center = true,
	decorate = true,
	size = { 1536, 864 },
	stay_focused = true,
})

-- Video Player Rules
hl.window_rule({
	name = "float-mpv",
	match = {
		class = "mpv",
	},
	float = true,
	center = true,
	decorate = true,
	size = { 1536, 864 },
})

-- Files Through Rofi
hl.window_rule({
	name = "float-rofi-files",
	match = {
		class = "rofi-nvim",
	},
	float = true,
	center = true,
	decorate = true,
	size = { 1100, 800 },
	opacity = "0.8 0.8",
})

-- Files through Thunar
hl.window_rule({
	name = "float-thunar-files",
	match = {
		class = "thunar-nvim",
	},
	float = true,
	center = true,
	decorate = true,
	size = { 1100, 800 },
	opacity = "0.8 0.8",
})

-- Files through Yazi
hl.window_rule({
	name = "float-yazi-nvim",
	match = {
		class = "yazi-nvim",
	},
	float = true,
	center = true,
	decorate = true,
	size = { 1200, 800 },
	opacity = "0.9 0.9",
})

-- Volume Control Rules
hl.window_rule({
	name = "float-position-volume-control",
	match = {
		class = "org.pulseaudio.pavucontrol",
		title = "Volume Control",
	},
	float = true,
	size = { "(monitor_w * 0.35)", "(monitor_h * 0.32)" },
	move = { 1050, 42 },
	pin = true,
	stay_focused = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Network Menu Rules
hl.window_rule({
	name = "float-position-networkEditor",
	match = {
		class = "nm-connection-editor",
		initial_class = "nm-connection-editor",
	},
	float = true,
	size = { "(monitor_w * 0.25)", "(monitor_h * 0.3)" },
	move = { 350, 42 },
	pin = true,
	decorate = true,
	opacity = "0.7 0.7",
})

hl.window_rule({
	name = "float-position-networkEditor-secondary",
	match = {
		class = "nm-connection-editor",
		title = "^(Editing).*",
	},
	float = true,
	size = { "(monitor_w * 0.25)", "(monitor_h * 0.3)" },
	move = { 600, 250 },
	pin = true,
	stay_focused = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Bluetooth Menu Rules
hl.window_rule({
	name = "float-position-blueman",
	match = {
		class = "blueman-manager",
		title = "Bluetooth Devices",
	},
	float = true,
	size = { "(monitor_w * 0.25)", "(monitor_h * 0.3)" },
	move = { 350, 42 },
	pin = true,
	decorate = true,
	opacity = "0.7 0.7",
})

hl.window_rule({
	name = "float-position-blueman-info",
	match = {
		class = "blueman-manager",
		title = "blueman",
	},
	float = true,
	size = { "(monitor_w * 0.25)", "(monitor_h * 0.3)" },
	move = { 500, 240 },
	pin = true,
	stay_focused = true,
	decorate = true,
	opacity = "0.7 0.7",
})

hl.window_rule({
	name = "float-position-blueman-about",
	match = {
		class = "blueman-manager",
		title = "About blueman-manager",
	},
	float = true,
	size = { "(monitor_w * 0.25)", "(monitor_h * 0.3)" },
	move = { 350, 90 },
	pin = true,
	stay_focused = true,
	decorate = true,
	opacity = "0.7 0.7",
})

hl.window_rule({
	name = "float-position-blueman-plugin",
	match = {
		class = "blueman-applet",
		title = "Plugins",
	},
	float = true,
	size = { 600, 350 },
	move = { 500, 195 },
	pin = true,
	stay_focused = true,
	decorate = true,
	opacity = "0.7 0.7",
})

hl.window_rule({
	name = "float-position-blueman-local",
	match = {
		class = "blueman-services",
		title = "^(Local Services).*",
	},
	float = true,
	size = { 460, 360 },
	move = { 470, 180 },
	pin = true,
	stay_focused = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Kvantum Rules
hl.window_rule({
	name = "float-kvantum",
	match = {
		class = "kvantummanager",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Kvantum Preview Rules
hl.window_rule({
	name = "float-kvantum-preview",
	match = {
		class = "kvantumpreview",
	},
	float = true,
	size = { 700, 500 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Nwg-look rules
hl.window_rule({
	name = "float-nwg-look",
	match = {
		class = "nwg-look",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Qt test utility rules
hl.window_rule({
	name = "float-qt-test",
	match = {
		class = "qv4l2",
	},
	float = true,
	stay_focused = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Qt video capture rules
hl.window_rule({
	name = "float-qt-video",
	match = {
		class = "qvidcap",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
})

-- Bssh rules
hl.window_rule({
	name = "float-bssh",
	match = {
		class = "bssh",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Bvnc rules
hl.window_rule({
	name = "float-bvnc",
	match = {
		class = "bvnc",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Localsend rules
hl.window_rule({
	name = "float-localsend",
	match = {
		class = "localsend",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Zathura rules
hl.window_rule({
	name = "float-zathura",
	match = {
		class = "org.pwmt.zathura",
	},
	--float = true,
	float = false,
	size = { 1000, 800 },
	center = true,
	decorate = true,
	opacity = "0.8 0.8",
})

-- Java Monitoring Console rules
hl.window_rule({
	name = "float-java-console",
	match = {
		class = "sun-tools-jconsole-JConsole",
	},
	float = true,
	size = { 1000, 800 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- CMake rules
hl.window_rule({
	name = "float-cmake",
	match = {
		class = "cmake-gui",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Bulk Rename rules
hl.window_rule({
	name = "float-bulk-rename",
	match = {
		class = "Thunar",
		title = "^(Bulk Rename).*",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Qt5ct rules
hl.window_rule({
	name = "float-qt5ct",
	match = {
		class = "qt5ct",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

-- Qt6ct rules
hl.window_rule({
	name = "float-qt6ct",
	match = {
		class = "qt6ct",
	},
	float = true,
	size = { 1000, 700 },
	center = true,
	decorate = true,
	opacity = "0.7 0.7",
})

hl.window_rule({
	name = "rmpc",
	match = {
		class = "rmpc",
	},
	workspace = "special:music",
	center = true,
	decorate = true,
	opacity = "0.7 0.6",
})

-- Global are you sure confirm windows
hl.window_rule({
	name = "global-are-you-sure",
	match = {
		modal = true,
	},
	center = true,
	float = true,
	size = { 400, 300 },
	decorate = true,
	opacity = "0.7 0.7",
})

hl.window_rule({
	-- Ignore maximize requests from apps. You'll probably like this.
	name = "suppress-maximize-events",
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
	-- Fix some dragging issues with XWayland
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})

-- Force Hyprland authentication dialog to float true and center
-- hl.window_rule(){
--   name = "float-hyprpolkitagent",
--   match = {
--     class = "hyprpolkitagent",
--     title = "hyprpolkitagent"
--   },
--   float = true,
--   center = true,
--   size = { "(monitor_w * 0.3)", "(monitor_h * 0.533)" },
--   pin = true,
--   stay_focused = true,
-- })

-------------------
--- Layer rules ---
-------------------

-- Blur layerrule
hl.layer_rule({
	match = { namespace = "waybar" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.1,
	animation = "fadeIn",
})

hl.layer_rule({
	match = { namespace = "swaync-control-center" },
	blur = true,
	ignore_alpha = 0.2,
	animation = "slide right",
})

hl.layer_rule({
	match = { namespace = "swaync-notification-window" },
	blur = true,
	ignore_alpha = 0.2,
})

hl.layer_rule({
	match = { namespace = "rofi" },
	blur = true,
	ignore_alpha = 0.1,
	animation = "slide bottom",
})

hl.layer_rule({
	match = { namespace = "hyprpicker" },
	animation = "fadeIn",
})

hl.layer_rule({
	match = { namespace = "logout_dialog" },
	animation = "fadeIn",
})

hl.layer_rule({
	match = { namespace = "selection" },
	animation = "fadeIn",
})

-- Workspace Rules
hl.workspace_rule({ workspace = "special:music", layout = "scrolling" })
hl.workspace_rule({ workspace = "2", layout = "scrolling" })
