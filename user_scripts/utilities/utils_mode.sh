#!/bin/bash

if [[ -z "$@" ]]; then
  # Check night light status for dynamic label
  if pgrep -x hyprsunset >/dev/null; then
    nl_label="󰖔  Night Light (On)"
  else
    nl_label="󰖔  Night Light (Off)"
  fi

  # Check waybar status for dynamic label
  if pgrep -x waybar >/dev/null; then
    wb_label="󰧨  Waybar (Hide)"
  else
    wb_label="󰧨  Waybar (Show)"
  fi

  printf "%s\n" \
    "$nl_label" \
    "󰈋  Hyprpicker" \
    "󰻠  System Monitor (btop)" \
    "$wb_label" \
    "󰄰  Text OCR" \
    "󱐋  Power Saving (PowerTop)"
  exit 0
fi

case "$1" in
*"Hyprpicker")
  pkill rofi
  sleep 0.5 && hyprpicker -a -q >/dev/null 2>&1 &
  disown
  ;;
*"Night Light"*)
  pkill rofi
  sleep 0.2
  env | grep -E "WAYLAND|XDG|HYPR" >>/tmp/nl-debug.log
  bash "$HOME/.config/hypr/scripts/nightlight.sh" &
  disown
  ;;
*"Waybar"*)
  if pgrep -x waybar >/dev/null; then
    pkill -TERM waybar
  else
    waybar &
    disown
    pkill rofi
  fi
  ;;
*"Text OCR")
  pkill rofi
  sleep 0.5
  if ! pgrep tesseract >/dev/null; then
    OCR_TEXT="$(slurp | grim -g - - | tesseract stdin stdout -l eng)"
    if [[ -n "${OCR_TEXT//[[:space:]]/}" ]]; then
      printf "%s" "$OCR_TEXT" | wl-copy
      notify-send "Text Copied using OCR" "$OCR_TEXT"
    else
      notify-send "No Text Detected" "Nothing Copied to Clipboard"
    fi
  fi
  ;;
*"System Monitor"*)
  pkill rofi
  hyprctl dispatch 'hl.dsp.exec_cmd("$HOME/.local/bin/myScripts/utilities/btop.sh")'
  disown
  ;;
*"Power Saving"*)
  pkill rofi
  pkexec powertop --auto-tune >/dev/null
  notify-send "PowerTop" "Auto-tune applied"
  ;;
esac
