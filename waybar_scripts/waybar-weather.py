#!/usr/bin/env python3

import html
import json
import pathlib
import sys
import time
from datetime import datetime, timedelta, timezone

import requests

# ---------------- CONFIG
FALLBACK_LAT = "28.9611"
FALLBACK_LON = "77.7271"
DISPLAY_NAME = "Meerut"
CACHE_TIMEOUT = 840  # a bit under the 900 s poll interval, so every poll refreshes
LOCATION_TTL = 6 * 3600  # re-run the IP lookup at most every 6 hours
USE_IP_LOOKUP = True  # False = always use the FALLBACK_* coordinates, no lookup at all
FONT = "Liberation Mono"
SOLID_LINE = "─" * 22
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
    except Exception:
        return defaults


COLORS = load_theme_colors()


def c(text, color_hex):
    return f"<span foreground='{color_hex}'>{text}</span>"


# ---------------- DATA FETCHING
CACHE_DIR = pathlib.Path.home() / ".cache"
CACHE_FILE = CACHE_DIR / "waybar_weather_cache.json"
LOCATION_FILE = CACHE_DIR / "waybar_weather_location.json"


def read_json(path):
    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, dict) else None
    except Exception:
        return None


def write_json(path, data):
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(data))
        tmp.replace(path)
    except Exception:
        pass


def get_location():
    """Fresh cache -> IP lookup -> stale cache -> fallback coordinates."""
    fallback = (FALLBACK_LAT, FALLBACK_LON, DISPLAY_NAME)
    if not USE_IP_LOOKUP:
        return fallback

    cached = read_json(LOCATION_FILE)
    if cached and not {"lat", "lon", "city"} <= cached.keys():
        cached = None
    if cached and time.time() - cached.get("timestamp", 0) < LOCATION_TTL:
        return cached["lat"], cached["lon"], cached["city"]

    try:
        # The free ip-api tier is plain HTTP only
        r = requests.get(
            "http://ip-api.com/json/?fields=status,lat,lon,city", timeout=3
        )
        if r.status_code == 200:
            data = r.json()
            if data.get("status") == "success":
                loc = (str(data["lat"]), str(data["lon"]), data["city"])
                write_json(
                    LOCATION_FILE,
                    {
                        "timestamp": time.time(),
                        "lat": loc[0],
                        "lon": loc[1],
                        "city": loc[2],
                    },
                )
                return loc
    except Exception:
        pass

    if cached:  # lookup failed: an old location beats the hard-coded one
        return cached["lat"], cached["lon"], cached["city"]
    return fallback


LAT, LON, ACTUAL_NAME = get_location()
ACTUAL_NAME = html.escape(str(ACTUAL_NAME))

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


def fetch_weather():
    url = (
        f"https://api.open-meteo.com/v1/forecast?latitude={LAT}&longitude={LON}"
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"
        "&hourly=temperature_2m,weather_code,precipitation_probability"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset&timezone=auto"
    )
    r = requests.get(url, timeout=10)
    r.raise_for_status()
    return r.json()


def get_weather_data():
    """Returns (data, fetched_at, is_stale); (None, 0, False) if nothing is available."""
    cached = read_json(CACHE_FILE)
    # A cache only counts if it belongs to the current location
    if not (
        cached
        and cached.get("lat") == LAT
        and cached.get("lon") == LON
        and "data" in cached
    ):
        cached = None

    if cached and time.time() - cached.get("timestamp", 0) < CACHE_TIMEOUT:
        return cached["data"], cached["timestamp"], False

    try:
        data = fetch_weather()
    except Exception:
        if cached:  # offline: show the last good data, marked as stale
            return cached["data"], cached.get("timestamp", 0), True
        return None, 0, False

    fetched_at = time.time()
    write_json(
        CACHE_FILE, {"timestamp": fetched_at, "lat": LAT, "lon": LON, "data": data}
    )
    return data, fetched_at, False


def location_now(data):
    """Current time at the forecast location (naive), from the API's UTC offset."""
    try:
        offset = int(data["utc_offset_seconds"])
        now = datetime.now(timezone.utc) + timedelta(seconds=offset)
        return now.replace(tzinfo=None)
    except Exception:
        return datetime.fromisoformat(data["current"]["time"])


def main():
    data, fetched_at, is_stale = get_weather_data()
    if not data:
        print(json.dumps({"text": "N/A", "tooltip": "Weather unavailable"}))
        sys.exit(0)

    try:
        curr, hourly, daily = data["current"], data["hourly"], data["daily"]
        temp, icon, desc = (
            curr["temperature_2m"],
            *WEATHER_MAP.get(curr["weather_code"], ("❓", "Unknown")),
        )
        now_dt = location_now(data)  # "now" in the forecast location's timezone
        f_span = f"font_family='{FONT}'"

        lines = [
            f"<span {f_span} size='large'>{c('' + NBSP * 2 + ACTUAL_NAME, COLORS['green'])}</span>"
        ]
        lines.append(f"\n<span {f_span}>{icon} {desc}</span>")
        lines.append(
            f"<span {f_span}>{NBSP * 3}{temp}°C (Feels {curr['apparent_temperature']}°C)</span>"
        )
        lines.append(
            f"<span {f_span}>{NBSP * 3}{curr['relative_humidity_2m']}% Humidity</span>"
        )
        lines.append(f"<span {f_span}>󰖝{NBSP * 3}{curr['wind_speed_10m']}km/h</span>")

        # --- Dynamic Sun Schedule ---
        sunset_str = daily["sunset"][0]
        sunset_dt = datetime.fromisoformat(sunset_str)

        if now_dt > sunset_dt:
            sunrise_str = (
                daily["sunrise"][1]
                if len(daily["sunrise"]) > 1
                else daily["sunrise"][0]
            )
            sun_line = (
                f"{NBSP * 3}{sunset_dt.strftime('%H:%M')}{NBSP * 4}"
                f"{NBSP * 3}{datetime.fromisoformat(sunrise_str).strftime('%H:%M')}"
            )
        else:
            sunrise_dt = datetime.fromisoformat(daily["sunrise"][0])
            sun_line = (
                f"{NBSP * 3}{sunrise_dt.strftime('%H:%M')}{NBSP * 4}"
                f"{NBSP * 3}{sunset_dt.strftime('%H:%M')}"
            )

        lines.append(f"<span {f_span}>{sun_line}</span>")

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

        now_hour = now_dt.strftime("%Y-%m-%dT%H:00")
        try:
            start_idx = hourly["time"].index(now_hour)
        except ValueError:
            start_idx = 0

        for i in range(start_idx, min(start_idx + 5, len(hourly["time"]))):
            dt_h = datetime.fromisoformat(hourly["time"][i])
            h_icon, _ = WEATHER_MAP.get(hourly["weather_code"][i], (" ", " "))

            time_str = dt_h.strftime(f"{clocks[dt_h.hour % 12]}{NBSP}%I:%M{NBSP}%p")
            time_padded = time_str.ljust(14, NBSP)
            rain = format_rain(hourly["precipitation_probability"][i])
            temp_val = f"{hourly['temperature_2m'][i]:.1f}".rjust(5, NBSP)

            lines.append(
                f"<span {f_span}>{time_padded}{NBSP * 6}{rain}{NBSP * 2}{temp_val}°C{NBSP * 2}{h_icon}</span>"
            )

        # --- Tomorrow ---
        add_section("Tomorrow", "")
        tomorrow_labels = {
            7: f"󰖜{NBSP}Morning",
            12: f"󰖙{NBSP}Midday",
            17: f"󰖚{NBSP}Afternoon",
            21: f"󰖔{NBSP}Evening",
        }
        for i in range(24, min(48, len(hourly["time"]))):
            dt = datetime.fromisoformat(hourly["time"][i])
            if dt.hour in tomorrow_labels:
                prefix = tomorrow_labels[dt.hour].ljust(14, NBSP)
                t_icon, _ = WEATHER_MAP.get(hourly["weather_code"][i], (" ", " "))
                rain = format_rain(hourly["precipitation_probability"][i])
                temp_val = f"{hourly['temperature_2m'][i]:.1f}".rjust(5, NBSP)

                lines.append(
                    f"<span {f_span}>{prefix}{NBSP * 6}{rain}{NBSP * 2}{temp_val}°C{NBSP * 2}{t_icon}</span>"
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

        stale_note = []
        if is_stale:
            cached_at = datetime.fromtimestamp(fetched_at).strftime("%H:%M")
            stale_note = [
                "<span>       ───────────────────────────</span>",
                f"<span {f_span}>{c(NBSP * 7 + 'cached ' + cached_at + ' (offline)', COLORS['bright_black'])}</span>",
            ]

        print(
            json.dumps(
                {
                    "text": f"<span size='13000'>{icon}</span><span size='11000'>{temp}°C</span> ",
                    "tooltip": "\n".join(lines + stale_note),
                    "markup": "pango",
                    "class": ["weather", "stale"] if is_stale else ["weather"],
                },
                ensure_ascii=False,
            )
        )

    except Exception as e:
        print(json.dumps({"text": "Error", "tooltip": html.escape(str(e))}))


if __name__ == "__main__":
    main()
