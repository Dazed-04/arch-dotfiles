#!/bin/sh

# 1. Update MPC Queue
mpc clear
for f in "$@"; do
  mpc add "${f#"$HOME"/Music/}"
done
mpc play 1

# 2. Hyprland Workspace Logic
~/.config/hypr/scripts/toggleMusic.sh
