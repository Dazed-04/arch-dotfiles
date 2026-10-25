#!/usr/bin/env bash
# Toggle bluetui in a kitty window with class "bluetui"
CLASS=bluetui

if hyprctl clients -j | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null; then
  hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = 'class:$CLASS' }))" >/dev/null
else
  rfkill unblock bluetooth
  setsid -f uwsm app -- kitty --class "$CLASS" bluetui >/dev/null 2>&1
fi
