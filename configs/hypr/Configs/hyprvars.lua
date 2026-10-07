----------------------------------------
--- Variables to use in config files ---
----------------------------------------

local vars = {}

vars.HOME = os.getenv("HOME")

local scripts = vars.HOME .. "/.local/bin/myScripts"
local hyprScripts = vars.HOME .. "/.config/hypr/scripts"

-- Applications (launched through uwsm so they get their own systemd scope)
vars.terminal = "uwsm-app -- kitty"
vars.fileManager = "uwsm-app -- thunar"
vars.stremio = "stremio-enhanced"

-- Launchers and utilities
vars.menu = "bash " .. scripts .. "/utilities/menu_launcher.sh"
vars.emojis = "bash " .. scripts .. "/utilities/emoji_launcher.sh"
vars.utilMenu = "bash " .. scripts .. "/utilities/utility_menu.sh"
vars.clipboard = "bash " .. scripts .. "/clipboard/clipboard.sh"
vars.powerMenu = "bash " .. scripts .. "/wlogout/wlogout.sh"

-- Wallpaper and screenshots (append flags like --menu / --smart where used)
vars.wallpaper = "bash " .. scripts .. "/wallpaperRelated/wallpaperSelect.sh"
vars.screenshot = "bash " .. scripts .. "/screenshots/screenshot.sh"

-- Streaming
vars.seanime = "bash " .. scripts .. "/streaming/seanime.sh"
vars.qbittorrent = "bash " .. scripts .. "/streaming/qbittorrent.sh"

-- Hypr helper scripts
vars.music = "bash " .. hyprScripts .. "/toggleMusic.sh"
vars.blur = "bash " .. hyprScripts .. "/changeBlur.sh"
vars.refreshRate = "bash " .. hyprScripts .. "/toggleRefreshRate.sh"

return vars
