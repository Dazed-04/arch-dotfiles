#!/bin/bash
# Opens the utility rofi menu; starts on the Media tab while OBS is recording.
if pgrep -x rofi >/dev/null; then
  pkill -x rofi
  exit 0
fi

START_MODI="Network"
SECRET="$HOME/.config/hypr/.obs-secret"
if pgrep -x obs >/dev/null && [[ -r $SECRET ]]; then
  OBS_PASS=$(tr -d '[:space:]' <"$SECRET")
  # Same "Active: true" check as media_mode.sh; the timeout stops a stuck OBS hanging the menu
  if timeout 2 obs-cmd --websocket "obsws://localhost:4455/${OBS_PASS}" recording status 2>/dev/null |
    grep -q "Active: true"; then
    START_MODI="Media"
  fi
fi

rofi \
  -show "$START_MODI" \
  -theme "$HOME/.config/rofi/launcher-themes/utility-menu.rasi"
