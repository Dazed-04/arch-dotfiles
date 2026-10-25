#!/usr/bin/env bash
# Toggle btop in a kitty window with class "btop"
CLASS=btop

if hyprctl clients -j | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null; then
  hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = 'class:$CLASS' }))" >/dev/null
else
  setsid -f uwsm app -- kitty --class "$CLASS" btop >/dev/null 2>&1
fi
