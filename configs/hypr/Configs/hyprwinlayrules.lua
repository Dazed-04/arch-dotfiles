--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Rules are evaluated top to bottom, so order matters: general rules first, global rules last.

local glass = "0.7 0.7"
local soft = "0.8 0.8"

-- Border on every floating window (global border_size stays 0, so tiled windows get none)
hl.window_rule({
	name = "border-floating",
	match = { float = true },
	border_size = 2,
})

-- Floating, centered, decorated window. `extra` adds to or overrides the defaults.
local function float_center(name, match, size, extra)
	local rule = { name = name, match = match, float = true, center = true, decorate = true, size = size }
	for k, v in pairs(extra or {}) do
		rule[k] = v
	end
	hl.window_rule(rule)
end

-- Pinned, floating panel at a fixed position (volume, network, bluetooth menus).
local function panel(name, match, size, pos, extra)
	local rule = {
		name = name,
		match = match,
		float = true,
		pin = true,
		decorate = true,
		opacity = soft,
		size = size,
		move = pos,
	}
	for k, v in pairs(extra or {}) do
		rule[k] = v
	end
	hl.window_rule(rule)
end

local small_panel = { "(monitor_w * 0.25)", "(monitor_h * 0.3)" }

----------------------
--- File managers ----
----------------------

float_center("float-thunar", { initial_class = "thunar" }, { 1000, 700 }, { opacity = glass })
float_center(
	"float-thunar-bulk-rename",
	{ initial_class = "thunar", title = "^(Bulk Rename).*" },
	{ 1000, 700 },
	{ opacity = glass }
)

-- Files through Rofi / Thunar / Yazi (nvim file pickers)
float_center("float-rofi-files", { initial_class = "rofi-nvim" }, { 1100, 800 }, { opacity = soft })
float_center("float-thunar-files", { initial_class = "thunar-nvim" }, { 1100, 800 }, { opacity = soft })
float_center("float-yazi-nvim", { initial_class = "yazi-nvim" }, { 1200, 800 }, { opacity = "0.9 0.9" })

----------------------
--- TUIs and tools ---
----------------------

float_center("float-wlctl", { initial_class = "^(wlctl)$" }, { 1000, 700 })
float_center("float-bluetui", { initial_class = "^(bluetui)$" }, { 1000, 700 })
float_center("float-btop", { initial_class = "^(btop)$" }, { 1400, 800 })
float_center("float-bssh", { initial_class = "bssh" }, { 1000, 700 }, { opacity = glass })
float_center("float-bvnc", { initial_class = "bvnc" }, { 1000, 700 }, { opacity = glass })
float_center(
	"float-java-console",
	{ initial_class = "sun-tools-jconsole-JConsole" },
	{ 1000, 800 },
	{ opacity = glass }
)
float_center("float-cmake", { initial_class = "cmake-gui" }, { 1000, 700 }, { opacity = glass })
float_center("float-localsend", { initial_class = "org.localsend.localsend_app" }, { 1000, 700 }, { opacity = glass })

-- Music (rmpc lives on the music special workspace)
hl.window_rule({
	name = "rmpc-music-workspace",
	match = { initial_class = "rmpc" },
	workspace = "special:music",
	float = false,
	center = true,
	decorate = true,
	opacity = glass,
})

----------------------
--- Theming tools ----
----------------------

float_center("float-kvantum", { initial_class = "kvantummanager" }, { 1000, 700 }, { opacity = glass })
float_center("float-kvantum-preview", { initial_class = "kvantumpreview" }, { 700, 500 }, { opacity = glass })
float_center("float-nwg-look", { initial_class = "nwg-look" }, { 1000, 700 }, { opacity = glass })
float_center("float-qt5ct", { initial_class = "qt5ct" }, { 1000, 700 }, { opacity = glass })
float_center("float-qt6ct", { initial_class = "qt6ct" }, { 1000, 700 }, { opacity = glass })

-- Qt test utilities
float_center("float-qt-test", { initial_class = "qv4l2" }, { 1000, 700 }, { opacity = glass, stay_focused = true })
float_center("float-qt-video", { initial_class = "qvidcap" }, { 1000, 700 })

----------------------
--- Media and docs ---
----------------------

float_center("float-imv", { initial_class = "imv", title = "^(imv -).*" }, { 1536, 864 }, { stay_focused = true })
float_center("float-mpv", { initial_class = "mpv" }, { 1536, 864 })

-- Screenshot editor
float_center(
	"float-satty",
	{ initial_class = "com.gabm.satty", title = "satty" },
	{ 1536, 864 },
	{ stay_focused = true }
)

-- Zathura is kept tiled
hl.window_rule({
	name = "tile-zathura",
	match = { initial_class = "org.pwmt.zathura" },
	-- float = true,
	float = false,
	size = { 1000, 800 },
	center = true,
	decorate = true,
})

-- Rnote only gets opacity
hl.window_rule({
	name = "rnote-opacity",
	match = { initial_class = "com.github.flxzt.rnote" },
})

-- Calculator
hl.window_rule({
	name = "float-qalculate",
	match = { initial_class = "qalculate-gtk", title = "Qalculate!" },
	float = true,
	decorate = true,
	size = { 600, 400 },
	opacity = soft,
})

-- OBS preview window (pinned to the bottom-right corner)
hl.window_rule({
	name = "float-obs-preview",
	match = {
		initial_class = "com.obsproject.Studio",
		title = "^Projector.*Video Capture Device.*",
	},
	float = true,
	pin = true,
	size = { 400, 300 },
	move = "monitor_w-400 monitor_h-300",
})

----------------------
--- GIMP and apps ----
----------------------

float_center("float-gimp-submenus", { initial_class = "script-fu" }, { 600, 500 }, { stay_focused = true })
float_center("float-gimp-pdf", { initial_class = "file-pdf-load", title = "Load PDF Image" }, nil, { opacity = soft })
float_center("float-keepassxc", { initial_class = "org.keepassxc.KeePassXC" }, { 1200, 800 }, { opacity = soft })

float_center(
	"float-xdg-desktop-portal-gtk",
	{ initial_class = "xdg-desktop-portal-gtk" },
	{ 600, 500 },
	{ stay_focused = true }
)

----------------------
--- Zen submenus -----
----------------------

local zen = "^(zen)$"

float_center(
	"float-zen-download-menu",
	{ initial_class = zen, title = "Library" },
	{ 900, 500 },
	{ stay_focused = true, opacity = glass }
)
float_center(
	"float-zen-save-image-as-menu",
	{ initial_class = zen, title = "^(Save Image).*" },
	{ 600, 500 },
	{ stay_focused = true, opacity = glass }
)
float_center(
	"float-zen-file-upload-menu",
	{ initial_class = zen, title = "^(File Upload).*" },
	{ 900, 500 },
	{ stay_focused = true, opacity = glass }
)

-- Picture-in-Picture (any browser): small, pinned, keeps its aspect ratio.
-- Replaces the old Zen-only PiP rule.
hl.window_rule({
	name = "pip",
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	float = true,
	keep_aspect_ratio = true,
	size = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
	pin = true,
})

----------------------
--- Downloads --------
----------------------

-- AB Download Manager: dialogs float, the main window stays tiled
hl.window_rule({
	name = "float-abdownload-menu",
	match = { class = "com-abdownloadmanager-desktop-AppKt" },
	float = true,
	center = true,
	size = { 1200, 800 },
})

-------------------------------
--- Pinned panels (top bar) ---
-------------------------------

panel(
	"float-position-volume-control",
	{ initial_class = "org.pulseaudio.pavucontrol", title = "Volume Control" },
	{ "(monitor_w * 0.35)", "(monitor_h * 0.32)" },
	{ 1050, 42 }
)

-- Network menu
panel("float-position-network-editor", { initial_class = "nm-connection-editor" }, small_panel, { 350, 42 })
panel(
	"float-position-network-editor-secondary",
	{ initial_class = "nm-connection-editor", title = "^(Editing).*" },
	small_panel,
	{ 600, 250 },
	{ stay_focused = true }
)

-- Bluetooth menu
panel(
	"float-position-blueman",
	{ initial_class = "blueman-manager", title = "Bluetooth Devices" },
	small_panel,
	{ 350, 42 }
)
panel(
	"float-position-blueman-info",
	{ initial_class = "blueman-manager", title = "blueman" },
	small_panel,
	{ 500, 240 },
	{ stay_focused = true }
)
panel(
	"float-position-blueman-about",
	{ initial_class = "blueman-manager", title = "About blueman-manager" },
	small_panel,
	{ 350, 90 },
	{ stay_focused = true }
)
panel(
	"float-position-blueman-plugins",
	{ initial_class = "blueman-applet", title = "Plugins" },
	{ 600, 350 },
	{ 500, 195 },
	{ stay_focused = true }
)
panel(
	"float-position-blueman-local-services",
	{ initial_class = "blueman-services", title = "^(Local Services).*" },
	{ 460, 360 },
	{ 470, 180 },
	{ stay_focused = true }
)

------------------------
--- Global and system ---
------------------------

-- Global "are you sure" confirm windows
hl.window_rule({
	name = "global-are-you-sure",
	match = {
		modal = true,
	},
	center = true,
	float = true,
	size = { 400, 300 },
	decorate = true,
	opacity = glass,
})

-- Ignore maximize requests from apps
hl.window_rule({
	name = "suppress-maximize-events",
	match = {
		class = ".*",
	},
	suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
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
	border_size = 0,
})

-- Hyprland-run
hl.window_rule({
	name = "move-hyprland-run",
	match = { initial_class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

-- Hyprland share picker
float_center("float-hyprland-share-picker", { initial_class = "hyprland-share-picker" }, { 800, 500 })

-- Polkit authentication dialog: wider, shorter, slides in from the bottom like rofi
hl.window_rule({
	name = "style-hyprpolkitagent",
	match = { class = "^hyprpolkitagent$" },
	float = true,
	center = true,
	size = { 500, 448 },
	animation = "slide bottom",
	opacity = glass,
})

-------------------
--- Layer rules ---
-------------------

-- Blur layerrules
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

-----------------------
--- Workspace rules ---
-----------------------

hl.workspace_rule({ workspace = "2", layout = "scrolling" })
hl.workspace_rule({ workspace = "special:music", layout = "scrolling" })
