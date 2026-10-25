#!/bin/sh
# Yazi: append the selected files to the end of the queue.
export MPD_HOST="${MPD_HOST:-$HOME/.config/mpd/socket}"
music="$HOME/Music/"

added=0
for f in "$@"; do
  case $f in
  "$music"*) mpc -q add "${f#"$music"}" && added=$((added + 1)) ;;
  esac
done

if [ "$added" -eq 0 ]; then
  notify-send -u critical "Add to Queue" "Nothing added: files must be inside $music"
  exit 1
fi
notify-send -u low "Add to Queue" "Added $added track(s)"
