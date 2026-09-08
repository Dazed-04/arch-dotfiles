#!/usr/bin/env python3
import json
import os
import pathlib
import subprocess

# ---------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------
GPU_ICON = "󰢮"
LEFT_PAD = " "
SOLID_LINE = "─" * 43

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


def c(text, color):
    return f"<span foreground='{color}'>{text}</span>"


def get_color(value, metric_type):
    table = [
        {"color": COLORS["blue"], "temp": (0, 35), "util": (0, 20)},
        {"color": COLORS["cyan"], "temp": (36, 45), "util": (21, 40)},
        {"color": COLORS["green"], "temp": (46, 54), "util": (41, 60)},
        {"color": COLORS["yellow"], "temp": (55, 65), "util": (61, 75)},
        {"color": COLORS["red"], "temp": (66, 999), "util": (76, 999)},
    ]
    try:
        val = float(value)
        for entry in table:
            low, high = entry[metric_type]
            if low <= val <= high:
                return entry["color"]
    except:
        pass
    return COLORS["white"]


# ---------------------------------------------------
# DATA EXTRACTION
# ---------------------------------------------------
gpu_percent, gpu_temp, gpu_power, fan_speed = 0, 0, 0.0, 0
vram_used, vram_total = 0, 0
gpu_name = "RTX 4060"

try:
    cmd = [
        "nvidia-smi",
        "--query-gpu=utilization.gpu,temperature.gpu,power.draw,fan.speed,memory.used,memory.total",
        "--format=csv,noheader,nounits",
    ]
    output = subprocess.check_output(cmd, text=True).strip()
    m = [x.strip() for x in output.split(",")]

    gpu_percent = int(m[0])
    gpu_temp = int(m[1])
    gpu_power = float(m[2])
    fan_speed = int(m[3]) if m[3] != "[N/A]" else 0
    vram_used = int(m[4])
    vram_total = int(m[5])
except:
    pass

vram_pct = (vram_used / vram_total * 100) if vram_total > 0 else 0


# ---------------------------------------------------
# THRESHOLD LOGIC (Sync with RAM/CPU style)
# ---------------------------------------------------
def get_alert_color(val):
    if val >= 85:
        return COLORS["red"], True
    if val >= 75:
        return COLORS["yellow"], True
    return None, False


# Calculate alerts for main metrics
temp_alert_color, temp_is_alert = get_alert_color(gpu_temp)
util_alert_color, util_is_alert = get_alert_color(gpu_percent)
vram_alert_color, vram_is_alert = get_alert_color(vram_pct)

# Formatting for bar and tooltip
temp_display_bar = (
    c(f"{gpu_temp}°C", temp_alert_color) if temp_is_alert else f"{gpu_temp}°C"
)
temp_display_tt = (
    c(f"{gpu_temp}°C", temp_alert_color) if temp_is_alert else f"{gpu_temp}°C"
)
util_display_tt = (
    c(f"{gpu_percent}%", util_alert_color) if util_is_alert else f"{gpu_percent}%"
)
vram_display_tt = (
    c(f"{vram_used} MB", vram_alert_color) if vram_is_alert else f"{vram_used} MB"
)


# ---------------------------------------------------
# GRAPHIC GENERATOR
# ---------------------------------------------------
def get_bar_segment(val, threshold):
    char_map = {80: "███", 60: "▅▅▅", 40: "▃▃▃", 20: "▂▂▂", 0: "───"}
    if val > threshold:
        color = COLORS["yellow"] if val < 85 else COLORS["red"]
    else:
        color = COLORS["bright_black"]
    return f"<span foreground='{color}'>{char_map[threshold]}</span>"


def get_chip_color(usage, level_threshold):
    # If VRAM usage is higher than this chip's 'level', make it yellow
    if usage > level_threshold:
        color = COLORS["yellow"] if usage < 85 else COLORS["red"]
    else:
        color = COLORS["bright_black"]
    return color


die_temp_color = get_color(gpu_temp, "temp")

# VRAM Chips (external bars)
vc = [c("███", get_chip_color(vram_pct, i * 16.6)) for i in range(6)]
bg = lambda t: f"<span foreground='{die_temp_color}'>{t}</span>"

bars = [
    f"{get_bar_segment(gpu_percent, t)} {get_bar_segment(vram_pct, t)} {get_bar_segment(fan_speed, t)}"
    for t in [80, 60, 40, 20, 0]
]

graphic = [
    f"            {c('╭─────────────────╮', COLORS['white'])}",
    f"       {c('=', COLORS['white'])}{vc[5]}{c('=│', COLORS['white'])}{bg('░░░░░░░░░░░░░░░░░')}{c('│=', COLORS['white'])}{vc[5]}{c('=', COLORS['white'])}",
    f"       {c('=', COLORS['white'])}{vc[4]}{c('=│', COLORS['white'])}{bg('░░')}  󰓅  󰘚  󰈐 <span letter_spacing='-2048'> </span>{bg('░░')}{c('│=', COLORS['white'])}{vc[4]}{c('=', COLORS['white'])}",
    f"            {c('│', COLORS['white'])}{bg('░░')} {bars[0]} {bg('░░')}{c('│', COLORS['white'])}",
    f"       {c('=', COLORS['white'])}{vc[3]}{c('=│', COLORS['white'])}{bg('░░')} {bars[1]} {bg('░░')}{c('│=', COLORS['white'])}{vc[3]}{c('=', COLORS['white'])}",
    f"       {c('=', COLORS['white'])}{vc[2]}{c('=│', COLORS['white'])}{bg('░░')} {bars[2]} {bg('░░')}{c('│=', COLORS['white'])}{vc[2]}{c('=', COLORS['white'])}",
    f"            {c('│', COLORS['white'])}{bg('░░')} {bars[3]} {bg('░░')}{c('│', COLORS['white'])}",
    f"       {c('=', COLORS['white'])}{vc[1]}{c('=│', COLORS['white'])}{bg('░░')} {bars[4]} {bg('░░')}{c('│=', COLORS['white'])}{vc[1]}{c('=', COLORS['white'])}",
    f"       {c('=', COLORS['white'])}{vc[0]}{c('=│', COLORS['white'])}{bg('░░░░░░░░░░░░░░░░░')}{c('│=', COLORS['white'])}{vc[0]}{c('=', COLORS['white'])}",
    f"            {c('╰─────────────────╯', COLORS['white'])}",
]

# ---------------------------------------------------
# PROCESSES EXTRACTION
# ---------------------------------------------------
gpu_procs = []
try:
    proc_out = subprocess.check_output(
        [
            "nvidia-smi",
            "--query-compute-apps=name,used_memory",
            "--format=csv,noheader,nounits",
        ],
        text=True,
    ).strip()
    if proc_out:
        for line in proc_out.split("\n"):
            name, mem = line.split(",")
            gpu_procs.append(
                {"name": os.path.basename(name.strip()), "mem": int(mem.strip())}
            )
    gpu_procs.sort(key=lambda x: x["mem"], reverse=True)
except:
    pass

# ---------------------------------------------------
# ASSEMBLY
# ---------------------------------------------------
text_font = "font='JetBrainsMono Nerd Font' size='11000'"

tooltip_lines = [
    f"<span {text_font}>{LEFT_PAD}{c(f'{GPU_ICON}  GPU - {gpu_name}', COLORS['green'])}</span>",
    f"{LEFT_PAD}{SOLID_LINE}{LEFT_PAD}",
    f"<span {text_font}>{LEFT_PAD}󰘚 | VRAM: {vram_display_tt} of {vram_total} MB Total</span>",
    f"{LEFT_PAD}{SOLID_LINE}{LEFT_PAD}",
    f"<span {text_font}>{LEFT_PAD} | Temp: {temp_display_tt} </span>",
    f"<span {text_font}>{LEFT_PAD} | Power: {gpu_power:.1f}W</span>",
    f"<span {text_font}>{LEFT_PAD}󰓅 | Utilization: {util_display_tt}</span>",
    "",
    "\n".join(graphic),
    f"\n{LEFT_PAD}{SOLID_LINE}{LEFT_PAD}",
    f"<span {text_font}>        Top GPU Processes:</span>",
    "",
]

if not gpu_procs:
    tooltip_lines.append(f"<span {text_font}>{LEFT_PAD}• No active processes</span>")
else:
    for p in gpu_procs[:3]:
        name = (p["name"][:15] + "..") if len(p["name"]) > 16 else p["name"]
        usage_p = (p["mem"] / vram_total * 100) if vram_total > 0 else 0
        if usage_p >= 75:
            tooltip_lines.append(
                f"<span {text_font} foreground='{COLORS['yellow']}'>{LEFT_PAD} • {name:<17}     󰘚 {p['mem']}MB</span>"
            )
        else:
            tooltip_lines.append(
                f"<span {text_font}>{LEFT_PAD} • {name:<17}     󰘚 {p['mem']}MB</span>"
            )

print(
    json.dumps(
        {
            "text": f"<span size='13000'>{GPU_ICON}</span><span rise='700'> {gpu_percent}%</span>",
            "tooltip": "\n".join(tooltip_lines),
            "markup": "pango",
            "class": "gpu",
        }
    )
)
