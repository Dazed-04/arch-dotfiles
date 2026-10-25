#!/bin/bash
# Rofi script mode "Utilities": no argument prints the entries, otherwise handles the pick.

if (($# == 0)); then
  if pgrep -x hyprsunset >/dev/null; then
    nl_label="󰖔  Night Light (On)"
  else
    nl_label="󰖔  Night Light (Off)"
  fi

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
    "󱐋  Power Saving (Toggle)"
  exit 0
fi

case "$1" in
*"Hyprpicker")
  pkill -x rofi
  sleep 0.5 && hyprpicker -a -q >/dev/null 2>&1 &
  disown
  ;;
*"Night Light"*)
  pkill -x rofi
  sleep 0.2
  bash "$HOME/.config/hypr/scripts/nightlight.sh" &
  disown
  ;;
*"Waybar"*)
  if pgrep -x waybar >/dev/null; then
    pkill -x waybar
  else
    setsid -f uwsm app -- waybar >/dev/null 2>&1
  fi
  pkill -x rofi # also closes the menu when hiding, so the label never goes stale
  ;;
*"Text OCR")
  pkill -x rofi
  sleep 0.5 # let rofi disappear before the screen is captured
  pgrep -x tesseract >/dev/null && exit 0
  region=$(slurp) || exit 0 # Esc in slurp = cancelled, not "no text"
  OCR_TEXT=$(grim -g "$region" - | tesseract stdin stdout -l eng)
  if [[ -n "${OCR_TEXT//[[:space:]]/}" ]]; then
    printf "%s" "$OCR_TEXT" | wl-copy
    # Short, markup-safe preview for the notification
    preview=$(sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' <<<"${OCR_TEXT:0:300}")
    notify-send "Text Copied using OCR" "$preview"
  else
    notify-send "No Text Detected" "Nothing Copied to Clipboard"
  fi
  ;;
*"System Monitor"*)
  pkill -x rofi
  setsid -f "$HOME/.local/bin/myScripts/utilities/btop.sh" >/dev/null 2>&1
  ;;
*"Power Saving"*)
  pkill -x rofi
  if [[ "$(powerprofilesctl get)" == "power-saver" ]]; then
    powerprofilesctl set balanced
    notify-send "Power Saving" "Off: balanced profile"
  else
    powerprofilesctl set power-saver
    # Single quotes on purpose: "$f" must be expanded by the root shell, not this one
    if pkexec sh -c '
      for f in /sys/bus/pci/devices/*/power/control; do echo auto > "$f" 2>/dev/null; done
      echo 1 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null
      exit 0'; then
      notify-send "Power Saving" "On: power-saver profile + PCI/audio power saving"
    else
      notify-send "Power Saving" "Cancelled, only the profile was changed"
    fi
  fi
  ;;
esac
