#!/usr/bin/env bash
# Toggle the seanime server.
# -x matters: a plain `pgrep seanime` also matches this script ("seanime.sh") when it is
# run directly, so it would always think seanime is running (and pkill would hit itself).
iDIR="$HOME/.config/swaync/icons"

if pgrep -x seanime >/dev/null; then
  pkill -x seanime
  notify-send -e -u low -i "$iDIR/seanime-off.png" "Seanime Stopped"
else
  setsid -f uwsm app -- seanime >/dev/null 2>&1
  sleep 1
  if pgrep -x seanime >/dev/null; then
    notify-send -e -u low -i "$iDIR/seanime-on.png" "Seanime Started"
  else
    notify-send -e -u critical -i "$iDIR/seanime-off.png" "Seanime failed to start"
  fi
fi
