#!/usr/bin/env python3

import json
import pathlib
import pickle
import sys
import time
from datetime import datetime

import requests

# ---------------- CONFIG
FALLBACK_LAT = "28.9611"
FALLBACK_LON = "77.7271"
DISPLAY_NAME = "Meerut"
CACHE_TIMEOUT = 900
FONT = "Liberation Mono"
SOLID_LINE = "─" * 20
NBSP = "\u00a0"  # Non-breaking space prevents Pango from collapsing spaces

# ---------------- THEME & COLORS
try:
    import tomllib
except ImportError:
    tomllib = None


def load_theme_colors():
    theme_path = pathlib.Path.home() / ".config/waybar/scripts/colors.toml"
    defaults = {
        "red": "#ffb4ab",
        "green": "#c5c0ff",
        "yellow": "#ebb8cf",
        "blue": "#444078",
        "cyan": "#c8c4dc",
        "white": "#e5e1e9",
        "bright_black": "#928f99",
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


def c(text, color_hex):
    return f"<span foreground='{color_hex}'>{text}</span>"


# ---------------- DATA FETCHING
def get_location():
    try:
        response = requests.get("http://ip-api.com/json/", timeout=5)
        response.raise_for_status()
        data = response.json()
        if data.get("status") == "success":
            return str(data["lat"]), str(data["lon"]), data.get("city", DISPLAY_NAME)
    except:
        pass
    return FALLBACK_LAT, FALLBACK_LON, DISPLAY_NAME


LAT, LON, ACTUAL_NAME = get_location()
CACHE_FILE = pathlib.Path.home() / ".cache" / "waybar_weather_cache.pkl"

WEATHER_MAP = {
    0: ("󰖙 ", " Clear sky"),
    1: ("󰖙 ", " Mainly clear"),
    2: ("󰖐 ", " Partly cloudy"),
    3: ("󰖐 ", " Overcast"),
    45: ("󰖑 ", " Fog"),
    48: ("󰖑 ", " Depositing rime fog"),
    51: ("󰖗 ", " Light drizzle"),
    53: ("󰖗 ", " Moderate drizzle"),
    55: ("󰖗 ", " Dense drizzle"),
    56: ("󰖘 ", " Freezing drizzle"),
    57: ("󰖘 ", " Heavy freezing drizzle"),
    61: ("󰖖 ", " Slight rain"),
    63: ("󰖖 ", " Moderate rain"),
    65: ("󰖖 ", " Heavy rain"),
    66: ("󰖘 ", " Freezing rain"),
    67: ("󰖘 ", " Heavy freezing rain"),
    71: ("󰖒 ", " Slight snow"),
    73: ("󰖒 ", " Moderate snow"),
    75: ("󰖒 ", " Heavy snow"),
    77: ("󰖓 ", " Snow grains"),
    80: ("󰖗 ", " Slight showers"),
    81: ("󰖖 ", " Moderate showers"),
    82: ("󰖖 ", " Violent showers"),
    85: ("󰖔 ", " Snow showers"),
    86: ("󰖔 ", " Heavy snow showers"),
    95: ("󰖕 ", " Thunderstorm"),
    96: ("󰖕 ", " Thunderstorm w/ hail"),
    99: ("󰖕 ", " Thunderstorm w/ heavy hail"),
}


def get_weather_data():
    CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if CACHE_FILE.exists():
        try:
            with open(CACHE_FILE, "rb") as f:
                cached = pickle.load(f)
                if time.time() - cached["timestamp"] < CACHE_TIMEOUT:
                    return cached["data"]
        except:
            pass
    url = (
        f"https://api.open-meteo.com/v1/forecast?latitude={LAT}&longitude={LON}"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,uv_index"
        "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset&timezone=auto"
    )
    try:
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        data = r.json()
        with open(CACHE_FILE, "wb") as f:
            pickle.dump({"timestamp": time.time(), "data": data}, f)
        return data
    except:
        return None


def main():
    data = get_weather_data()
    if not data:
        print(json.dumps({"text": "N/A", "tooltip": "Weather unavailable"}))
        sys.exit(0)

    try:
        curr, hourly, daily = data["current"], data["hourly"], data["daily"]
        temp, icon, desc = (
            curr["temperature_2m"],
            *WEATHER_MAP.get(curr["weather_code"], ("❓", "Unknown")),
        )
        now_iso = datetime.now().isoformat()
        f_span = f"font_family='{FONT}'"

        lines = [
            f"<span {f_span} size='large'>{c('' + NBSP * 2 + ACTUAL_NAME, COLORS['green'])}</span>"
        ]
        lines.append(f"\n<span {f_span}>{icon} {desc}</span>")
        lines.append(
            f"<span {f_span}>{NBSP * 3}{temp}°C (Feels {curr['apparent_temperature']}°C)</span>"
        )
        lines.append(
            f"<span {f_span}>{NBSP * 3}{daily['sunrise'][0].split('T')[1]}{NBSP * 2}{NBSP * 2}{daily['sunset'][0].split('T')[1]}</span>"
        )
        lines.append(
            f"<span {f_span}>{NBSP * 3}{curr['relative_humidity_2m']}% Humidity</span>"
        )
        lines.append(f"<span {f_span}>󰖝{NBSP * 3}{curr['wind_speed_10m']}km/h</span>")

        def add_section(title, icon_glyph):
            lines.append(f"<span {f_span}>{SOLID_LINE}</span>")
            lines.append(
                f"<span {f_span}><b>{c(icon_glyph + NBSP * 2 + title, COLORS['yellow'])}</b></span>\n"
            )

        def format_rain(val):
            val_str = str(val).rjust(2, NBSP)
            text = f"{NBSP}{val_str}%"
            return text if val > 0 else c(text, COLORS["bright_black"])

        # --- Today ---
        add_section("Today", "")
        clocks = ["󱑊", "󱐿", "󱑀", "󱑁", "󱑂", "󱑃", "󱑄", "󱑅", "󱑆", "󱑇", "󱑈", "󱑉"]
        for i in range(24):
            if hourly["time"][i] >= now_iso[:13]:
                dt_h = datetime.fromisoformat(hourly["time"][i])
                h_icon, _ = WEATHER_MAP.get(hourly["weather_code"][i], (" ", " "))

                time_str = dt_h.strftime(f"{clocks[dt_h.hour % 12]}{NBSP}%I:%M{NBSP}%p")
                time_padded = time_str.ljust(14, NBSP)
                rain = format_rain(hourly["precipitation_probability"][i])
                temp_val = f"{hourly['temperature_2m'][i]:.1f}".rjust(5, NBSP)

                lines.append(
                    f"<span {f_span}>{time_padded}{NBSP * 5}{rain}{NBSP * 2}{NBSP}{temp_val}°C{NBSP * 2}{h_icon}</span>"
                )

        # --- Tomorrow ---
        add_section("Tomorrow", "")
        tomorrow_labels = {
            7: f"󰖜{NBSP}Morning",
            12: f"󰖙{NBSP}Midday",
            17: f"󰖚{NBSP}Arvo",
            21: f"󰖔{NBSP}Evening",
        }
        for i in range(24, 48):
            dt = datetime.fromisoformat(hourly["time"][i])
            if dt.hour in tomorrow_labels:
                prefix = tomorrow_labels[dt.hour].ljust(14, NBSP)
                t_icon, _ = WEATHER_MAP.get(hourly["weather_code"][i], (" ", " "))
                rain = format_rain(hourly["precipitation_probability"][i])
                temp_val = f"{hourly['temperature_2m'][i]:.1f}".rjust(5, NBSP)

                lines.append(
                    f"<span {f_span}>{prefix}{NBSP * 5}{rain}{NBSP * 2}{NBSP}{temp_val}°C{NBSP * 2}{t_icon}</span>"
                )

        # --- Extended ---
        add_section("Extended Forecast", "")
        for i in range(1, min(7, len(daily["time"]))):
            dt = datetime.fromisoformat(daily["time"][i])
            d_icon, _ = WEATHER_MAP.get(daily["weather_code"][i], (" ", " "))
            rain = format_rain(daily["precipitation_probability_max"][i])

            day_str = dt.strftime("%A")
            date_str = dt.strftime("%d")
            prefix = f"{date_str}{NBSP}{day_str}".ljust(14, NBSP)

            min_t = f"{daily['temperature_2m_min'][i]:.0f}".rjust(2, NBSP)
            max_t = f"{daily['temperature_2m_max'][i]:.0f}".rjust(2, NBSP)

            lines.append(
                f"<span {f_span}>{prefix}{NBSP * 2}{rain}{NBSP * 2}{c('', COLORS['cyan'])}{NBSP}{min_t}°{NBSP * 2}{c('', COLORS['red'])}{NBSP}{max_t}°{NBSP * 2}{d_icon}</span>"
            )

        print(
            json.dumps(
                {
                    "text": f"<span size='13000'>{icon}</span><span size='11000'>{temp}°C</span> ",
                    "tooltip": "\n".join(lines),
                    "markup": "pango",
                    "class": "weather",
                },
                ensure_ascii=False,
            )
        )

    except Exception as e:
        print(json.dumps({"text": "Error", "tooltip": str(e)}))


if __name__ == "__main__":
    main()
