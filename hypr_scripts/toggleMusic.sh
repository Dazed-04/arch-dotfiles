#!/bin/bash
# Toggle the rmpc scratchpad (special:music). Its animation style comes from the
# workspace rule in hyprwinlayrules.lua, so nothing is changed at runtime.

# One run at a time; the lock is released automatically when the script exits
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/rmpc-toggle.lock"
flock -n 9 || exit 0

is_running() {
  hyprctl clients -j | jq -e 'any(.[]; .class == "rmpc")' >/dev/null
}

if ! is_running; then
  hyprctl dispatch exec "[workspace special:music silent] kitty --class rmpc -e rmpc"
  for _ in {1..20}; do # wait up to 2 s for the window to appear
    is_running && break
    sleep 0.1
  done
fi

hyprctl dispatch togglespecialworkspace music
