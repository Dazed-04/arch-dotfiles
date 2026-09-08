#!/usr/bin/env bash

if hyprctl clients | grep -q 'class: wlctl'; then
  hyprctl dispatch "hl.dsp.window.close({ window = 'class:wlctl' })"
else
  rfkill unblock wifi
  hyprctl dispatch "hl.dsp.exec_raw('kitty --class wlctl wlctl')"
fi
