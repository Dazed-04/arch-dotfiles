#!/usr/bin/env python3
import html
import json
import os
import pathlib
import re
import subprocess
import time

import psutil

# ---------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------
CPU_ICON_GENERAL = ""
GUTTER = " " * 2
CACHE_DIR = pathlib.Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
HISTORY_FILE = CACHE_DIR / "waybar_cpu_history.json"
RAPL_PATH = "/sys/class/powercap/intel-rapl:0/energy_uj"
SAMPLE_SECS = 0.4  # utilisation sampling window
CORE_HISTORY_SECS = 600  # keep the last 10 minutes of per-core samples
SUDO_RETRY_SECS = 300  # back-off after a failed sudo call


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


# ---------------------------------------------------
# DATA COLLECTION & HISTORY
# ---------------------------------------------------


def read_cpu_name(fallback):
    """Model name from /proc/cpuinfo, tidied up for the tooltip header."""
    try:
        for line in pathlib.Path("/proc/cpuinfo").read_text().splitlines():
            if line.startswith("model name"):
                name = line.split(":", 1)[1]
                for junk in ("(R)", "(TM)", "(tm)", " CPU"):
                    name = name.replace(junk, "")
                name = re.sub(r"\s*@.*$", "", name)
                name = re.sub(r"^\d+(st|nd|rd|th) Gen ", "", name.strip())
                return html.escape(" ".join(name.split()))
    except Exception:
        pass
    return fallback


def get_history():
    defaults = {"energy": 0, "time": 0, "samples": [], "sudo_fail": 0}
    try:
        data = json.loads(HISTORY_FILE.read_text())
        if isinstance(data, dict):
            return {**defaults, **data}
    except Exception:
        pass
    return defaults


def save_history(data):
    try:
        tmp = HISTORY_FILE.with_suffix(".tmp")
        tmp.write_text(json.dumps(data))
        tmp.replace(HISTORY_FILE)
    except Exception:
        pass


def read_energy_uj(history, now):
    """RAPL is root-only: try a direct read, then the pinned sudo rule."""
    try:
        return int(pathlib.Path(RAPL_PATH).read_text())
    except PermissionError:
        pass
    except Exception:
        return None
    if now - history["sudo_fail"] < SUDO_RETRY_SECS:
        return None
    try:
        out = subprocess.run(
            ["sudo", "-n", "/usr/bin/cat", RAPL_PATH],
            capture_output=True,
            text=True,
            timeout=3,
        )
        if out.returncode == 0:
            return int(out.stdout.strip())
    except Exception:
        pass
    history["sudo_fail"] = now  # don't hammer sudo (faillock!) if the rule is missing
    return None


history = get_history()
now = time.time()
cpu_name = read_cpu_name("Intel i7 13650HX")

# 1. Temp
max_cpu_temp = 0
try:
    temps = psutil.sensors_temperatures() or {}
    for label in ["k10temp", "coretemp", "zenpower"]:
        if label in temps:
            max_cpu_temp = int(max(t.current for t in temps[label]))
            break
except Exception:
    pass

# 2. Frequency and power
freq = psutil.cpu_freq()
curr_f, max_f = (freq.current / 1000, freq.max / 1000) if freq else (0, 0)
cpu_power = None  # None = unreadable (no sudo rule yet, first run or counter wrap)
curr_energy = read_energy_uj(history, now)
if curr_energy is not None:
    if history["energy"] > 0 and now > history["time"]:
        delta = curr_energy - history["energy"]
        if delta >= 0:  # negative means the counter wrapped
            cpu_power = (delta / 1_000_000) / (now - history["time"])
    history["energy"] = curr_energy
    history["time"] = now

# 3. Utilisation: one shared sampling window for cores and processes
procs = []
for p in psutil.process_iter(["name"]):
    try:
        p.cpu_percent(None)  # first call only sets the baseline
        procs.append(p)
    except psutil.Error:
        pass

per_core_now = psutil.cpu_percent(interval=SAMPLE_SECS, percpu=True)
total_usage = sum(per_core_now) / max(len(per_core_now), 1)

top_procs = []
for p in procs:
    try:
        name = p.info["name"] or ""
        if p.pid == os.getpid() or "waybar" in name:
            continue
        top_procs.append((p.cpu_percent(None), name))
    except psutil.Error:
        pass
top_procs.sort(reverse=True)

history.pop("core_samples", None)  # key from the old history format
# samples are [timestamp, per-core list] pairs, trimmed by age instead of by count
samples = [
    s
    for s in history.get("samples", [])
    if isinstance(s, list)
    and len(s) == 2
    and isinstance(s[0], (int, float))
    and isinstance(s[1], list)
    and now - s[0] <= CORE_HISTORY_SECS
]
samples.append([now, per_core_now])
history["samples"] = samples
save_history(history)
avg_per_core = [sum(col) / len(col) for col in zip(*(s[1] for s in samples))]

# ---------------------------------------------------
# THRESHOLD FORMATTING
# ---------------------------------------------------
t_clr, t_act = get_alert_color(max_cpu_temp, 75, 85)
u_clr, u_act = get_alert_color(total_usage, 70, 85)
p_clr, p_act = get_alert_color(cpu_power or 0, 100, 140)

util_tt = c(f"{total_usage:.0f}%", u_clr) if u_act else f"{total_usage:.0f}%"
temp_tt = c(f"{max_cpu_temp}°C", t_clr) if t_act else f"{max_cpu_temp}°C"
if cpu_power is None:
    pwr_tt = c("N/A", COLORS["bright_black"])
elif p_act:
    pwr_tt = c(f"{cpu_power:.1f} W", p_clr)
else:
    pwr_tt = f"{cpu_power:.1f} W"

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
        for val, name in top_procs[:4]:
            label = html.escape((name[:15] + ":").ljust(18))
            clr = get_stealth_color(val)
            val_str = c(f"{val:>5.1f}%", clr) if clr else f"{val:>5.1f}%"
            tooltip_lines.append(f" • {label:<18}{GUTTER}{GUTTER}{GUTTER}{val_str}")

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
        }
    )
)
