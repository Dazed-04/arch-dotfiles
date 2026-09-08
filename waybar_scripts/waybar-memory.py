#!/usr/bin/env python3
import json
import pathlib
import re
import subprocess

import psutil

# ---------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------
MEM_ICON = ""
TOOLTIP_WIDTH = 52  # Provides enough buffer for 1-left, 2-right spacing
LEFT_PAD = " "
HARDWARE_FILE = pathlib.Path.home() / ".config/waybar/scripts/ram_hardware.txt"

# ---------------------------------------------------
# THEME & COLORS
# ---------------------------------------------------
try:
    import tomllib
except ImportError:
    tomllib = None


def load_theme_colors():
    theme_path = pathlib.Path.home() / ".config/waybar/scripts/colors.toml"
    defaults = {
        "red": "#ff0000",
        "green": "#00ff00",
        "yellow": "#ffff00",
        "blue": "#0000ff",
        "cyan": "#00ffff",
        "white": "#ffffff",
        "bright_black": "#555555",
    }
    if not tomllib or not theme_path.exists():
        return defaults
    try:
        data = tomllib.loads(theme_path.read_text())
        colors = data.get("colors", {}).get("normal", {})
        return {**defaults, **colors}
    except:
        return defaults


COLORS = load_theme_colors()


# ---------------------------------------------------
# UTILITIES
# ---------------------------------------------------
def shorten_slot_name(name):
    name = name.replace("Controller", "C").replace("Channel", "").replace("DIMM", "D")
    name = re.sub(r"\s+", "", name)
    return name


def c(text, color):
    return f"<span foreground='{color}'>{text}</span>"


# ---------------------------------------------------
# DATA EXTRACTION
# ---------------------------------------------------
def get_memory_temps():
    temps = []
    try:
        output = subprocess.check_output(
            ["sensors", "-j"], text=True, stderr=subprocess.DEVNULL
        )
        data = json.loads(output)
        for chip, content in data.items():
            if any(x in chip for x in ["jc42", "spd", "dram"]):
                for feature, subfeatures in content.items():
                    if isinstance(subfeatures, dict):
                        for key, val in subfeatures.items():
                            if "input" in key:
                                temps.append(int(val))
    except:
        pass
    return temps


def get_memory_modules():
    detected_modules = []
    real_temps = get_memory_temps()
    if not HARDWARE_FILE.exists():
        return []
    try:
        output = HARDWARE_FILE.read_text()
        current_module = {}
        for line in output.splitlines():
            line = line.strip()
            if line.startswith("Memory Device"):
                size_str = str(current_module.get("size", ""))
                if current_module and "No" not in size_str and size_str != "":
                    detected_modules.append(current_module)
                t_idx = len(detected_modules)
                current_module = {
                    "temp": real_temps[t_idx] if t_idx < len(real_temps) else 0
                }
            elif current_module:
                if line.startswith("Locator:"):
                    current_module["label"] = shorten_slot_name(
                        line.split(":", 1)[1].strip()
                    )
                elif line.startswith("Size:"):
                    current_module["size"] = line.split(":", 1)[1].strip()
                elif line.startswith("Type:"):
                    current_module["type"] = line.split(":", 1)[1].strip()
                elif "Speed" in line and "Unknown" not in line:
                    current_module["speed"] = (
                        line.split(":", 1)[1].strip().replace("MT/s", "MHz")
                    )
        if (
            current_module
            and current_module.get("size")
            and "No" not in str(current_module.get("size", ""))
        ):
            detected_modules.append(current_module)
    except:
        pass
    return detected_modules


# ---------------------------------------------------
# MAIN RENDERING
# ---------------------------------------------------
mem = psutil.virtual_memory()
memory_modules = get_memory_modules()

used_p, cached_p = (mem.used / mem.total) * 100, (mem.cached / mem.total) * 100
buff_p, free_p = (mem.buffers / mem.total) * 100, (mem.free / mem.total) * 100

inner_w = 42
bar_len = inner_w - 2
c_u = round((used_p / 100) * bar_len - 1)
c_c = round(((cached_p / 100) * bar_len) - 3)
c_b = round((buff_p / 100) * bar_len - 1)

total = c_u + c_c + c_b
c_f = bar_len - total - 1

bar_str = (
    c("█" * c_u, COLORS["red"])
    + c("█" * c_c, COLORS["yellow"])
    + c("█" * c_b, COLORS["cyan"])
    + c("█" * c_f, COLORS["bright_black"])
)

graphic_pad = " " * 2
# 49 chars + 1 LEFT_PAD = 50 total. In WIDTH 52, this creates 2 chars of right padding.
solid_line = "─" * 49

# Determine the color based on memory pressure
if mem.percent >= 85:
    alert_color = COLORS["red"]
    is_alert = True
elif mem.percent >= 65:
    alert_color = COLORS["yellow"]
    is_alert = True
else:
    alert_color = None
    is_alert = False

# Apply threshold color to the main bar text (for CSS fallback)
mem_text = c(f"{mem.percent}%", alert_color) if is_alert else f"{mem.percent}%"
usage_val = f"{mem.used / (1024**3):.1f} GB"
usage_display = c(usage_val, alert_color) if is_alert else usage_val

tooltip_lines = [
    f"<span size='4000'>\n</span>{LEFT_PAD}<span  foreground='{COLORS['green']}'>{MEM_ICON}  Memory</span>",
    f"{LEFT_PAD}{solid_line}{LEFT_PAD}",
    f"{LEFT_PAD}󰓅 | Usage: {usage_display} of {mem.total / (1024**3):.1f} GB Total",
    f"{LEFT_PAD}{solid_line}{LEFT_PAD}",
]

for m in memory_modules:
    temp = m.get("temp", 0)
    if temp >= 60:
        temp_display = c(f"{temp}°C", COLORS["red"])
    elif temp >= 50:
        temp_display = c(f"{temp}°C", COLORS["yellow"])
    else:
        temp_display = f"{temp}°C"

    label = m.get("label", "")
    size = m.get("size", "")
    m_type = m.get("type", "")
    speed = m.get("speed", "")

    row = f"{LEFT_PAD}{MEM_ICON} | {label:<8} | {size:<7} | {m_type:<5} | {speed:<9} | {temp_display}{LEFT_PAD}"
    tooltip_lines.append(row)

graphic = [
    f"\n{graphic_pad} {c('╭' + '─' * inner_w + '╮', COLORS['white'])}",
    f"{graphic_pad}{c('╭╯', COLORS['white'])}{c('░' * inner_w, COLORS['green'])}{c('╰╮', COLORS['white'])}",
    f"{graphic_pad}{c('╰╮', COLORS['white'])}{c('░', COLORS['green'])}{bar_str}{c('░', COLORS['green'])}{c('╭╯', COLORS['white'])}",
    f"{graphic_pad} {c('│', COLORS['white'])}{c('░' * inner_w, COLORS['green'])}{c('│', COLORS['white'])}",
    f"{graphic_pad}{c('╭╯', COLORS['white'])}{c('┌' + '┬' * bar_len + '┐', COLORS['white'])}{c('╰╮', COLORS['white'])}",
    f"{graphic_pad}{c('└─', COLORS['white'])}{c('┴' * inner_w, COLORS['white'])}{c('─┘', COLORS['white'])}\n",
]

tooltip_lines.extend(graphic)
tooltip_lines.append(f"{LEFT_PAD}{solid_line}")

legend_colored = (
    f"{c('█', COLORS['red'])} Used {used_p:.1f}%  "
    f"{c('█', COLORS['yellow'])} Cached {cached_p:.1f}%  "
    f"{c('█', COLORS['cyan'])} Buff {buff_p:.1f}%  "
    f"{c('█', COLORS['bright_black'])} Free {free_p:.1f}%"
)

tooltip_lines.append(f"<span size='10000'> {LEFT_PAD}{legend_colored}</span>")
tooltip_lines.append("<span size='1'>\n</span>")

print(
    json.dumps(
        {
            "text": f"<span size='10500'>{MEM_ICON}</span> <span size='10000'>{mem_text}</span>",
            "tooltip": f"<span font='JetBrainsMono Nerd Font' size='11000'>{'\n'.join(tooltip_lines)}</span>",
            "markup": "pango",
            "class": "memory",
        }
    )
)
