#!/bin/sh
for f in "$@"; do
  mpc -h "$HOME/.config/mpd/socket" insert "${f#"$HOME"/Music/}"
done
