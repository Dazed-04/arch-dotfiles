#!/usr/bin/env bash
# Toggle wlctl in a kitty window with class "wlctl"
CLASS=wlctl

if hyprctl clients -j | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null; then
  hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = 'class:$CLASS' }))" >/dev/null
else
  rfkill unblock wifi
  setsid -f uwsm app -- kitty --class "$CLASS" wlctl >/dev/null 2>&1
fi
