#!/usr/bin/env bash

if hyprctl clients | grep -q 'class: btop'; then
  hyprctl dispatch "hl.dsp.window.close({ window = 'class:btop' })"
else
  hyprctl dispatch "hl.dsp.exec_raw('kitty --class btop btop')"
fi
