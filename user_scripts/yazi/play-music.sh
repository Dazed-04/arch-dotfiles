#!/bin/sh
# Yazi: replace the queue with the selected files, play from the start, show rmpc.
export MPD_HOST="${MPD_HOST:-$HOME/.config/mpd/socket}"
music="$HOME/Music/"

# mpc wants paths relative to MPD's music directory; anything outside it can't be added.
# Check first, so a bad selection doesn't wipe the current queue.
valid=0
for f in "$@"; do
  case $f in "$music"*) valid=1 ;; esac
done
if [ "$valid" -eq 0 ]; then
  notify-send -u critical "Play Music" "Nothing added: files must be inside $music"
  exit 1
fi

mpc -q clear
for f in "$@"; do
  case $f in
  "$music"*) mpc -q add "${f#"$music"}" ;;
  esac
done

mpc -q play 1

# Show rmpc, but don't toggle it away if it is already visible
shown=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')
[ "$shown" = "special:music" ] || "$HOME/.config/hypr/scripts/toggleMusic.sh"
