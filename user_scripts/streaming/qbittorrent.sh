#!/usr/bin/env bash
# Toggle the qbittorrent-nox daemon.
# First run only: start `qbittorrent-nox` once in a terminal and accept the legal notice,
# otherwise it waits for a keypress and exits when started from here.
iDIR="$HOME/.config/swaync/icons"

if pgrep -x qbittorrent-nox >/dev/null; then
  pkill -x qbittorrent-nox
  notify-send -e -u low -i "$iDIR/qbittorrent-off.png" "Torrent Stopped"
else
  setsid -f uwsm app -- qbittorrent-nox >/dev/null 2>&1
  sleep 1 # only claim success if it is still alive
  if pgrep -x qbittorrent-nox >/dev/null; then
    notify-send -e -u low -i "$iDIR/qbittorrent-on.png" "Torrent Started"
  else
    notify-send -e -u critical -i "$iDIR/qbittorrent-off.png" "Torrent failed to start"
  fi
fi
