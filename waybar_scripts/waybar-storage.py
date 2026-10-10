#!/usr/bin/env python3
# ----------------------------------------------------------------------------
# WAYBAR STORAGE MODULE
# ----------------------------------------------------------------------------
# Auto-detects mounted physical drives and displays usage in a sleek dashboard.
# Features:
# - Dynamic drive detection (ignores snaps, loops, etc.)
# - Real-time I/O speeds (Read/Write)
# - Drive temperature monitoring (requires lm_sensors/smartctl)
# - Health status via smartctl (requires sudo)
# ----------------------------------------------------------------------------

import glob
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
SSD_ICON = ""
CACHE_DIR = pathlib.Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
HISTORY_FILE = CACHE_DIR / "waybar_storage_history.json"
SMART_CACHE_FILE = CACHE_DIR / "waybar_storage_smart.json"
SMARTCTL = "/usr/bin/smartctl"  # absolute path, must match the sudoers rule
SMART_TTL = 600  # health/lifespan/TBW barely change
SMART_RETRY = 300  # back-off after a failed smartctl call
LEFT_PAD = " "
TOOLTIP_FONT = "JetBrainsMono Nerd Font"
GAUGE_ICON = "󰓅"
TEMP_ICON = "\uf2c9"

# ---------------------------------------------------
# THEME & COLORS
# ---------------------------------------------------
try:
    import tomllib
except ImportError:
    tomllib = None


def resolve_disk(device_path):
    """Map a partition/mapper path to its physical disk name (e.g. nvme0n1)."""
    name = os.path.basename(
        os.path.realpath(device_path)
    )  # /dev/mapper/Archmain -> dm-0
    for _ in range(5):  # follow dm/LUKS stacks down to the real device
        slaves = f"/sys/class/block/{name}/slaves"
        if os.path.isdir(slaves) and os.listdir(slaves):
            name = os.listdir(slaves)[0]
        else:
            break
    if name.startswith(("nvme", "mmcblk")):
        return re.sub(r"p\d+$", "", name)
    return re.sub(r"\d+$", "", name)


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
        colors = data.get("colors", {})
        normal = colors.get("normal", {})
        bright = colors.get("bright", {})
        return {**defaults, **normal, **{f"bright_{k}": v for k, v in bright.items()}}
    except Exception:
        return defaults


COLORS = load_theme_colors()


# ---------------------------------------------------
# HISTORY & UTILS
# ---------------------------------------------------
def format_compact(val, suffix=""):
    if val is None:
        return f"0{suffix}"
    try:
        val = float(val)
    except (TypeError, ValueError):
        return f"0{suffix}"
    if val < 1024:
        return f"{val:.0f}{suffix}"
    val /= 1024
    if val < 1024:
        return f"{val:.1f}K{suffix}"
    val /= 1024
    if val < 1024:
        return f"{val:.1f}M{suffix}"
    val /= 1024
    return f"{val:.1f}G{suffix}"


def fmt_size(b):
    gb = b / 1024**3
    return f"{gb / 1024:.1f} TB" if gb >= 1024 else f"{gb:.1f} GB"


def read_json(path, default):
    try:
        data = json.loads(path.read_text())
        if isinstance(data, type(default)):
            return data
    except Exception:
        pass
    return default


def write_json(path, data):
    try:
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(data))
        tmp.replace(path)
    except Exception:
        pass


# ---------------------------------------------------
# HARDWARE SENSORS
# ---------------------------------------------------
def nvme_temp(disk_name):
    """Temperature from the kernel hwmon node: no root, no smartctl."""
    ctrl = re.sub(r"n\d+$", "", disk_name)  # nvme0n1 -> nvme0
    for f in glob.glob(f"/sys/class/nvme/{ctrl}/hwmon*/temp1_input"):
        try:
            return int(pathlib.Path(f).read_text()) // 1000
        except (OSError, ValueError):
            pass
    return None


def get_smart(disk_name):
    """Health, lifespan and TBW via one cached smartctl call per disk."""
    cache = read_json(SMART_CACHE_FILE, {})
    entry = cache.get(disk_name)
    if entry:
        ttl = SMART_TTL if entry["data"]["health"] != "N/A" else SMART_RETRY
        if time.time() - entry["ts"] < ttl:
            return entry["data"]

    result = {"temp": None, "health": "N/A", "lifespan": "N/A", "tbw": "N/A"}
    try:
        proc = subprocess.run(
            ["sudo", "-n", SMARTCTL, "-a", "-j", f"/dev/{disk_name}"],
            check=False,
            text=True,
            capture_output=True,
            timeout=10,
        )
        if proc.stdout:
            data = json.loads(proc.stdout)
            result["temp"] = data.get("temperature", {}).get("current")
            passed = data.get("smart_status", {}).get("passed")
            result["health"] = "OK" if passed else "FAIL" if passed is False else "N/A"
            nvme = data.get("nvme_smart_health_information_log", {})
            used = nvme.get("percentage_used")
            if used is not None:
                result["lifespan"] = f"{max(0, 100 - used)}%"
            duw = nvme.get("data_units_written")
            if duw:
                result["tbw"] = f"{(duw * 512000) / 1e12:.1f} TB"
    except Exception:
        pass

    cache[disk_name] = {"ts": time.time(), "data": result}
    write_json(SMART_CACHE_FILE, cache)
    return result


# ---------------------------------------------------
# MAIN LOGIC
# ---------------------------------------------------
EXCLUDED_MOUNTS = ("/snap", "/boot", "/var", "/run", "/sys", "/proc", "/dev")
FS_TYPES = {"ext4", "btrfs", "xfs", "ntfs", "vfat", "apfs", "zfs", "exfat"}


def get_drives():
    drives, seen = [], set()
    # "/" first so the shared btrfs filesystem is labelled "Root"
    parts = sorted(psutil.disk_partitions(), key=lambda p: p.mountpoint != "/")
    for p in parts:
        mp = p.mountpoint
        if any(mp == x or mp.startswith(x + "/") for x in EXCLUDED_MOUNTS):
            continue
        if "/loop" in p.device or p.fstype not in FS_TYPES or p.device in seen:
            continue
        seen.add(p.device)
        name = "Root" if mp == "/" else os.path.basename(mp)
        drives.append((name, mp, SSD_ICON, p.device))
    return drives


def main():
    history = read_json(HISTORY_FILE, {})
    last_io = history.get("io", {})
    last_time = history.get("timestamp", 0)
    current_time = time.time()

    try:
        current_io = {
            k: [v.read_bytes, v.write_bytes]
            for k, v in psutil.disk_io_counters(perdisk=True).items()
        }
    except Exception:
        current_io = {}

    drives = get_drives()
    storage_entries = []
    root_usage = 0

    for name, mountpoint, icon, device in drives:
        try:
            usage = psutil.disk_usage(mountpoint)
            used_pct = int(usage.percent)

            if mountpoint == "/":
                root_usage = used_pct

            disk = resolve_disk(device)
            smart = get_smart(disk)
            temp = nvme_temp(disk)
            if temp is None:
                temp = smart["temp"]
            health = smart["health"]
            lifespan, tbw = smart["lifespan"], smart["tbw"]

            # I/O speed: /dev/mapper/Archmain -> dm-0, which is the key psutil uses
            r_spd, w_spd = 0, 0
            dev_name = os.path.basename(os.path.realpath(device))
            if dev_name in current_io and dev_name in last_io:
                curr, prev = current_io[dev_name], last_io[dev_name]
                dt = current_time - last_time
                if dt > 0:
                    r_spd = max(0, (curr[0] - prev[0]) / dt)
                    w_spd = max(0, (curr[1] - prev[1]) / dt)
            storage_entries.append(
                {
                    "name": name,
                    "icon": icon,
                    "pct": used_pct,
                    "temp": temp,
                    "health": health,
                    "lifespan": lifespan,
                    "tbw": tbw,
                    "r_spd": r_spd,
                    "w_spd": w_spd,
                    "used_b": usage.used,
                    "total_b": usage.total,
                }
            )
        except Exception:
            continue

    # ---------------------------------------------------
    # TOOLTIP (styled to match the memory module)
    # ---------------------------------------------------
    LIFE_ICON, TBW_ICON = "\uf21e", "\uf1c0"
    READ_ICON, WRITE_ICON = "\uf019", "\uf093"
    SPEED_ICON = "\uf0ec"

    def c(text, color):
        return f"<span foreground='{color}'>{text}</span>"

    def vis_len(s):
        return len(re.sub(r"<[^>]+>", "", s))

    def alert_for(pct):
        if pct >= 85:
            return COLORS["red"]
        if pct >= 65:
            return COLORS["yellow"]
        return None

    white = COLORS["white"]
    nw = max((len(e["name"]) for e in storage_entries), default=4)
    sw = max((len(fmt_size(e["total_b"])) for e in storage_entries), default=6)

    # Build the text rows first so the width can be measured
    root = next((e for e in storage_entries if e["name"] == "Root"), None)
    usage_line = None
    if root:
        a = alert_for(root["pct"])
        used_txt = fmt_size(root["used_b"])
        used_txt = c(used_txt, a) if a else used_txt
        usage_line = (
            f"{GAUGE_ICON} | Usage: {used_txt} of {fmt_size(root['total_b'])} Total"
        )

    entry_rows = []
    for entry in storage_entries:
        t = entry["temp"]
        if t is None:
            temp_display = c("N/A", COLORS["bright_black"])
        elif t >= 70:
            temp_display = c(f"{t}°C", COLORS["red"])
        elif t >= 55:
            temp_display = c(f"{t}°C", COLORS["yellow"])
        else:
            temp_display = f"{t}°C"

        h = entry["health"]
        health_display = f"♥ {h}"
        if h == "FAIL":
            health_display = c(health_display, COLORS["red"])
        elif h == "N/A":
            health_display = c(health_display, COLORS["bright_black"])

            # All three rows follow the same pattern: leading icon | field | field ...
        rows = [
            f"{entry['icon']} | {entry['name']:<{nw}} | "
            f"{fmt_size(entry['total_b']):<{sw}} | {TEMP_ICON} {temp_display} | "
            f"{health_display}"
        ]

        fields = []
        if entry["lifespan"] != "N/A":
            fields.append(f"Life {entry['lifespan']}")
        if entry["tbw"] != "N/A":
            fields.append(f"{TBW_ICON} TBW {entry['tbw']}")
        if fields:
            rows.append(f"{LIFE_ICON} | " + " | ".join(fields))

        rs = format_compact(entry["r_spd"], "/s")
        ws = format_compact(entry["w_spd"], "/s")
        rows.append(f"{SPEED_ICON} | {READ_ICON} {rs} | {WRITE_ICON} {ws}")
        entry_rows.append((entry, rows))

    all_rows = ([usage_line] if usage_line else []) + [
        r for _, rows in entry_rows for r in rows
    ]
    W = max((vis_len(r) for r in all_rows), default=30)
    inner_w = W - 2
    solid = "─" * W

    # Assemble
    lines = [
        f"<span size='4000'>\n</span>{LEFT_PAD}{c(f'{SSD_ICON}  Storage', COLORS['green'])}",
        f"{LEFT_PAD}{solid} ",
    ]
    if usage_line:
        lines += [f"{LEFT_PAD}{usage_line}", f"{LEFT_PAD}{solid} "]

    for i, (entry, rows) in enumerate(entry_rows):
        lines += [f"{LEFT_PAD}{r}" for r in rows]

        filled = round(entry["pct"] / 100 * inner_w)
        bar = c("█" * filled, COLORS["red"]) + c(
            "░" * (inner_w - filled), COLORS["bright_black"]
        )
        lines += [
            "",
            f"{LEFT_PAD}{c('╭' + '─' * inner_w + '╮', white)}",
            f"{LEFT_PAD}{c('│', white)}{bar}{c('│', white)}",
            f"{LEFT_PAD}{c('│', white)}{bar}{c('│', white)}",
            f"{LEFT_PAD}{c('╰' + '─' * inner_w + '╯', white)}",
            "",
            f"{LEFT_PAD}{solid}",
        ]

        legend = (
            f"{c('█', COLORS['red'])} Used {entry['pct']}%    "
            f"{c('█', COLORS['bright_black'])} Free {100 - entry['pct']}%"
        )
        pad = max(0, round((len(LEFT_PAD) + W / 2) * 1.1 - vis_len(legend) / 2))
        lines.append(f"<span size='10000'>{' ' * pad}{legend}</span>")
        if i < len(entry_rows) - 1:
            lines.append("")

    lines.append("<span size='1'>\n</span>")

    write_json(HISTORY_FILE, {"io": current_io, "timestamp": current_time})

    alert = alert_for(root_usage)
    pct_txt = c(f"{root_usage}%", alert) if alert else f"{root_usage}%"
    tooltip = "\n".join(lines)

    print(
        json.dumps(
            {
                "text": f"<span size='10500'>{SSD_ICON}</span> <span size='10000'>{pct_txt}</span>",
                "tooltip": f"<span font='{TOOLTIP_FONT}' size='11000'>{tooltip}</span>",
                "markup": "pango",
                "class": "storage",
            }
        )
    )


if __name__ == "__main__":
    main()
