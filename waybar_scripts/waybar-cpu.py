#!/usr/bin/env python3
import glob
import json
import os
import pathlib
import pickle
import subprocess
import time

import psutil

# ---------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------
CPU_ICON_GENERAL = ""
HISTORY_FILE = "/tmp/waybar_cpu_history.pkl"
NAME_COL_WIDTH = 26
GUTTER = " " * 2

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
        "black": "#000000",
        "red": "#ff0000",
        "green": "#00ff00",
        "yellow": "#ffff00",
        "blue": "#0000ff",
        "magenta": "#ff00ff",
        "cyan": "#00ffff",
        "white": "#ffffff",
        "bright_black": "#555555",
        "bright_red": "#ff5555",
        "bright_green": "#55ff55",
        "bright_yellow": "#ffff55",
        "bright_blue": "#5555ff",
        "bright_magenta": "#ff55ff",
        "bright_cyan": "#55ffff",
        "bright_white": "#ffffff",
    }
    if not tomllib or not theme_path.exists():
        return defaults
    try:
        data = tomllib.loads(theme_path.read_text())
        normal = data.get("colors", {}).get("normal", {})
        bright = data.get("colors", {}).get("bright", {})
        return {**defaults, **normal, **{f"bright_{k}": v for k, v in bright.items()}}
    except Exception:
        return defaults


COLORS = load_theme_colors()

COLOR_TABLE = [
    {"color": COLORS["blue"], "cpu_gpu_temp": (0, 35), "cpu_power": (0.0, 30)},
    {"color": COLORS["cyan"], "cpu_gpu_temp": (36, 45), "cpu_power": (31.0, 60)},
    {"color": COLORS["green"], "cpu_gpu_temp": (46, 54), "cpu_power": (61.0, 90)},
    {"color": COLORS["yellow"], "cpu_gpu_temp": (55, 65), "cpu_power": (91.0, 120)},
    {
        "color": COLORS["bright_yellow"],
        "cpu_gpu_temp": (66, 75),
        "cpu_power": (121.0, 150),
    },
    {
        "color": COLORS["bright_red"],
        "cpu_gpu_temp": (76, 85),
        "cpu_power": (151.0, 180),
    },
    {"color": COLORS["red"], "cpu_gpu_temp": (86, 999), "cpu_power": (181.0, 999)},
]


def c(text, color):
    return f"<span foreground='{color}'>{text}</span>"


def get_stealth_color(usage, warn=70, crit=85):
    if usage >= crit:
        return COLORS["red"]
    if usage >= warn:
        return COLORS["yellow"]
    return None


def get_alert_color(val, warn=70, crit=85):
    if val >= crit:
        return COLORS["red"], True
    if val >= warn:
        return COLORS["yellow"], True
    return None, False


def get_rapl_path():
    base = "/sys/class/powercap"
    if not os.path.exists(base):
        return None
    paths = glob.glob(f"{base}/*/energy_uj")
    for p in paths:
        if "intel-rapl:0" in p or "package" in p:
            return p
    return paths[0] if paths else None


# ---------------------------------------------------
# DATA COLLECTION & HISTORY
# ---------------------------------------------------


def get_history():
    defaults = {"energy": 0, "time": 0, "core_samples": [], "peak_temp": 0}
    try:
        with open(HISTORY_FILE, "rb") as f:
            data = pickle.load(f)
            return {**defaults, **data}
    except:
        return defaults


history = get_history()
now = time.time()
cpu_name = "Intel i7 13650HX"

# 1. Temp and Freq
max_cpu_temp = 0
try:
    temps = psutil.sensors_temperatures() or {}
    for label in ["k10temp", "coretemp", "zenpower"]:
        if label in temps:
            max_cpu_temp = int(max(t.current for t in temps[label]))
            break
except:
    pass


# 2. Power
freq = psutil.cpu_freq()
curr_f, max_f = (freq.current / 1000, freq.max / 1000) if freq else (0, 0)
cpu_power = 0.0
rapl_path = get_rapl_path()
if rapl_path:
    try:
        with open(rapl_path, "r") as f:
            curr_energy = int(f.read().strip())
        if history["energy"] > 0 and now > history["time"]:
            energy_delta = curr_energy - history["energy"]
            time_delta = now - history["time"]
            cpu_power = (energy_delta / 1_000_000) / time_delta
        history["energy"] = curr_energy
        history["time"] = now
    except:
        pass

# 3. CPU Utilization
per_core_now = psutil.cpu_percent(interval=None, percpu=True)
history["core_samples"].append(per_core_now)
if len(history["core_samples"]) > 600:
    history["core_samples"].pop(0)
with open(HISTORY_FILE, "wb") as f:
    pickle.dump(history, f)

# Calculate the actual average per core
avg_per_core = [
    sum(c) / len(history["core_samples"]) for c in zip(*history["core_samples"])
]
total_usage = psutil.cpu_percent(interval=None)

# ---------------------------------------------------
# THRESHOLD FORMATTING
# ---------------------------------------------------
t_clr, t_act = get_alert_color(max_cpu_temp, 75, 85)
u_clr, u_act = get_alert_color(total_usage, 70, 85)
p_clr, p_act = get_alert_color(cpu_power, 100, 140)

temp_text = c(f"{max_cpu_temp}°C", t_clr) if t_act else f"{max_cpu_temp}°C"
util_tt = c(f"{total_usage:.0f}%", u_clr) if u_act else f"{total_usage:.0f}%"
temp_tt = c(f"{max_cpu_temp}°C", t_clr) if t_act else f"{max_cpu_temp}°C"
pwr_tt = c(f"{cpu_power:.1f} W", p_clr) if p_act else f"{cpu_power:.1f} W"

# ---------------------------------------------------
# TOOLTIP CONSTRUCTION
# ---------------------------------------------------

tooltip_lines = []
separator = f"<span>{'─' * 35}</span>"
tooltip_lines.append(
    f"<span foreground='{COLORS['green']}'> {CPU_ICON_GENERAL}  CPU - {cpu_name}</span>"
)
tooltip_lines.append(separator)

cpu_rows = [
    (" 󱎫", f"Clock Speed : {curr_f:.2f} / {max_f:.2f} GHz"),
    (" ", f"Temperature : {temp_tt}"),
    (" ", f"Power       : {pwr_tt}"),
    (" 󰓅", f"Utilization : {util_tt}"),
]

for icon, text_row in cpu_rows:
    tooltip_lines.append(f"{icon} | {text_row}")


# Die Visualization
substrate_color = t_clr if t_act else COLORS["cyan"]
border_color = COLORS["white"]
die_pad = "  " * 4

tooltip_lines.append("")
tooltip_lines.append(f"{die_pad} {c('╭──┘└──────┘⠿└──────┘└──╮', border_color)}")
tooltip_lines.append(
    f"{die_pad} {c('┘', border_color)}{c('░' * 23, substrate_color)}{c('└', border_color)}"
)

row_patterns = [("┐", "┌"), ("│", "│"), ("┘", "└"), ("┐", "┌"), ("┘", "└")]
for row in range(5):
    s_char, e_char = row_patterns[row]
    line = [f"{die_pad} {c(s_char, border_color)}{c('░░', substrate_color)}"]
    for col in range(4):
        idx = row * 4 + col
        if idx < len(per_core_now):
            u = per_core_now[idx]
            if u < 10:
                glyph = c("○", COLORS["cyan"])
            else:
                clr = get_stealth_color(u)
                glyph = c("●", clr) if clr else "●"
            line.append(f"{c('[', border_color)}{glyph}{c(']', border_color)}")
        else:
            line.append(c("░░░", substrate_color))
        if col < 3:
            line.append(c("░", substrate_color))
    line.append(f"{c('░░', substrate_color)}{c(e_char, border_color)}")
    tooltip_lines.append("".join(line))

tooltip_lines.append(
    f"{die_pad} {c('┐', border_color)}{c('░' * 23, substrate_color)}{c('┌', border_color)}"
)
tooltip_lines.append(f" {die_pad}{c('╰──┐┌──────┐⣶┌──────┐┌──╯', border_color)}")

# Lists
for title, data, is_proc in [
    ("Active Cores (10 min Avg):", avg_per_core, False),
    ("  Top Current Processes:", None, True),
]:
    tooltip_lines.append(f"\n{separator}\n    {title}\n")
    if is_proc:
        try:
            ps = (
                subprocess.check_output(
                    ["ps", "-eo", "pcpu,comm", "--sort=-pcpu", "--no-headers"],
                    text=True,
                )
                .strip()
                .split("\n")
            )
            for line in ps[:4]:
                parts = line.split(None, 1)
                if len(parts) < 2 or "waybar" in parts[1]:
                    continue
                val, name = float(parts[0]), parts[1][:15]
                clr = get_stealth_color(val)
                val_str = c(f"{val:>5.1f}%", clr) if clr else f"{val:>5.1f}%"
                tooltip_lines.append(
                    f" • {name + ':':<18}{GUTTER}{GUTTER}{GUTTER}{val_str}"
                )
        except:
            pass
    else:
        sorted_cores = sorted(enumerate(data), key=lambda x: x[1], reverse=True)[:3]
        for i, u in sorted_cores:
            clr = get_stealth_color(u)
            u_str = c(f"{u:>5.1f}%", clr) if clr else f"{u:>5.1f}%"
            tooltip_lines.append(
                f" • Core {i + 1:02}:{'':<10}{GUTTER}{GUTTER}{GUTTER}{u_str}"
            )


# ---------------------------------------------------
# OUTPUT
# ---------------------------------------------------
die_start = next(i for i, line in enumerate(tooltip_lines) if "╭──" in line)
die_end = next(i for i, line in enumerate(tooltip_lines) if "╰──┐" in line)

info_block = tooltip_lines[:die_start]
die_block = tooltip_lines[die_start : die_end + 1]
footer_block = tooltip_lines[die_end + 1 :]

final_tooltip = (
    f"<span font='JetBrainsMono Nerd Font' size='11000'>"
    f"{'\n'.join(info_block)}\n"
    f"</span>"
    f"{'\n'.join(die_block)}\n"
    f"<span font='JetBrainsMono Nerd Font' size='11000'>"
    f"{'\n'.join(footer_block)}"
    f"</span>"
)

print(
    json.dumps(
        {
            "text": f"{CPU_ICON_GENERAL} <span rise='-700'>{util_tt}</span>",
            "tooltip": final_tooltip,
            "markup": "pango",
            "class": "cpu",
            "click-events": True,
        }
    )
)
