#!/bin/bash
# Yazi: insert the selected files right after the current song ("play next").
# Each insert lands directly after the current song, so go through the files in reverse
# to keep the order they were selected in.
export MPD_HOST="${MPD_HOST:-$HOME/.config/mpd/socket}"
music="$HOME/Music/"

added=0
for ((i = $#; i > 0; i--)); do
  f=${!i}
  case $f in
  "$music"*) mpc -q insert "${f#"$music"}" && added=$((added + 1)) ;;
  esac
done

if ((added == 0)); then
  notify-send -u critical "Play Next" "Nothing added: files must be inside $music"
  exit 1
fi
notify-send -u low "Play Next" "Inserted $added track(s)"
