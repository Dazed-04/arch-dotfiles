#!/bin/bash

rofi_cmd=(rofi -dmenu -theme "$HOME/.config/rofi/launcher-themes/utility-menu.rasi")

if pgrep -x hyprsunset >/dev/null; then
  action=$(printf "󰔄  Change Temperature\n󰤄 Turn Off" | "${rofi_cmd[@]}" -p "Night Light")
  case "$action" in
  *"Change Temperature") ;;
  *"Turn Off")
    pkill hyprsunset
    exit 0
    ;;
  *) exit 0 ;;
  esac
fi

temp=$(printf "󰈈  Very Warm (3000K)\n󰅼  Warm (3500K)\n󰖙  Comfortable (4500K)\n󰖨  Neutral (5500K)\n󰏰 Custom" |
  "${rofi_cmd[@]}" -p "Select Temperature")

case "$temp" in
*"Very Warm"*) t=3000 ;;
*"Warm"*) t=3500 ;;
*"Comfortable"*) t=4500 ;;
*"Neutral"*) t=5500 ;;
*"Custom"*)
  t=$(rofi -dmenu -p "Enter temperature (1000-6500)" \
    -theme "$HOME/.config/rofi/launcher-themes/utility-menu.rasi")
  if ! [[ "$t" =~ ^[0-9]+$ ]] || [[ "$t" -lt 1000 ]] || [[ "$t" -gt 6500 ]]; then
    notify-send "Night Light" "Invalid temperature. Must be between 1000 and 6500."
    exit 1
  fi
  ;;
*) exit 0 ;;
esac

pkill hyprsunset 2>/dev/null
sleep 0.1
nohup hyprsunset -t "$t" >/dev/null 2>&1 &
disown
notify-send "Night Light" "Temperature set to ${t}K"
