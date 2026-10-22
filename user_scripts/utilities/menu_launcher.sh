#!/bin/bash

if pgrep -x rofi >/dev/null; then
  pkill -x rofi
  exit 0
fi

rofi -show drun
