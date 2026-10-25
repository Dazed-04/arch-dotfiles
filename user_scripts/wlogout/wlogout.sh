#!/usr/bin/env bash
# Toggle wlogout, with top/bottom margins scaled to the focused monitor.
A_1080=400
B_1080=400

if pgrep -x wlogout >/dev/null; then
  pkill -x wlogout
  exit 0
fi

# One hyprctl call: logical height = height / scale
read -r height scale < <(hyprctl -j monitors | jq -r '.[] | select(.focused) | "\(.height) \(.scale)"')
if [[ -z $height ]]; then
  notify-send -u critical "wlogout" "Could not read the focused monitor"
  exit 1
fi

# base value defined for 1080p, scaled to this monitor (same formula as before)
margin() { awk -v base="$1" -v h="$height" -v s="$scale" 'BEGIN { printf "%.0f", base * 1080 * s / (h / s) }'; }

exec wlogout -C "$HOME/.config/wlogout/style.css" -l "$HOME/.config/wlogout/layout" \
  --protocol layer-shell -b 5 -T "$(margin "$A_1080")" -B "$(margin "$B_1080")"
