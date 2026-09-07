#!/bin/sh
for f in "$@"; do
  mpc -h "$HOME/.config/mpd/socket" add "${f#"$HOME"/Music/}"
done
