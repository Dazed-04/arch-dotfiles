#!/bin/bash
# Manual refresh-rate toggle (HIGH <-> LOW). autorefresh.sh sets the rate from the power
# state on plug/unplug, login and resume; this overrides it until the next of those events.
# Keep MONITOR, RES and the rates in sync with autorefresh.sh.

MONITOR="eDP-1"
RES="1920x1080"
HIGH=144
LOW=60

current_rate() {
  hyprctl monitors -j | jq -r --arg m "$MONITOR" '.[] | select(.name == $m) | .refreshRate | round'
}

fail() {
  notify-send -e -u critical -a "refresh-script" "Display" "$1"
  exit 1
}

current=$(current_rate)
[[ $current =~ ^[0-9]+$ ]] || fail "Monitor $MONITOR not found"

# Closer to the high rate -> go low, otherwise go high
if ((current > (HIGH + LOW) / 2)); then
  target=$LOW
  msg="Switched to ${LOW}Hz (Battery Saver)"
else
  target=$HIGH
  msg="Switched to ${HIGH}Hz (High Performance)"
fi

hyprctl eval "hl.monitor({ output = '$MONITOR', mode = '${RES}@${target}', position = 'auto', scale = 1 })" >/dev/null

# Only announce a switch that actually happened
sleep 0.5
[[ $(current_rate) == "$target" ]] || fail "Could not switch to ${target}Hz"

notify-send -e \
  -h string:x-canonical-private-synchronous:refresh_notif \
  -u low \
  -a "refresh-script" \
  -t 3500 \
  "Display" "$msg"
