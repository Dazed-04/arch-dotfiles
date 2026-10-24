#!/bin/bash
# Prints the active keyboard layout (used by hyprlock).
# Uses the main keyboard; virtual devices (power button, etc.) also appear in the list
# and can report a different layout.

layout=$(hyprctl devices -j 2>/dev/null |
  jq -r '.keyboards | ((map(select(.main)) | first) // .[0]) | .active_keymap // empty')

if [[ $layout == *English* ]]; then
  echo "EN ⠀⠀"
elif [[ -n $layout ]]; then
  echo "${layout:0:2}" | tr '[:lower:]' '[:upper:]' | sed 's/$/ ⠀⠀/'
else
  echo "??? ⠀⠀"
fi
