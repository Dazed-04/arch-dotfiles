#!/bin/bash
# autorefresh.sh: sets the refresh rate from the power state
# (AC_RATE on mains, BAT_RATE on battery).
#
# Setup (one time):
#   1. Root must run its own copy, never a file in your home directory:
#        sudo install -m 755 -o root -g root <this file> /etc/acpi/autorefresh.sh
#      Re-run this after editing the script, including MONITOR/RES/rates.
#   2. /etc/acpi/events/power-handler:
#        event=ac_adapter.*
#        action=/etc/acpi/autorefresh.sh
#      then: sudo systemctl restart acpid
#   3. Also run it at login and after resume (it works as a normal user too):
#        hyprland.lua:  hl.exec_cmd("/etc/acpi/autorefresh.sh")   (in hyprland.start)
#        hypridle.conf: after_sleep_cmd = <existing command>; /etc/acpi/autorefresh.sh
#
# Needs: acpid, jq, hyprctl, notify-send.

USER_NAME="Dazed"
MONITOR="eDP-1"
RES="1920x1080"
AC_RATE=144
BAT_RATE=60

USER_ID=$(id -u "$USER_NAME") || exit 1
RUNTIME_DIR="/run/user/$USER_ID"

# Which Hyprland instance? The newest socket wins, so stale dirs from old sessions are ignored.
SIG=$(find "$RUNTIME_DIR/hypr" -maxdepth 2 -type s -name .socket.sock -printf '%T@ %h\n' 2>/dev/null |
  sort -nr | head -n1 | cut -d' ' -f2-)
SIG=${SIG##*/}
[[ -n $SIG ]] || exit 0 # Hyprland isn't running

# Run a command inside the user's session: via runuser when started by acpid (root),
# directly when started by the user.
as_user() {
  local vars=(
    HYPRLAND_INSTANCE_SIGNATURE="$SIG"
    XDG_RUNTIME_DIR="$RUNTIME_DIR"
    DBUS_SESSION_BUS_ADDRESS="unix:path=$RUNTIME_DIR/bus"
  )
  if ((EUID == 0)); then
    runuser -u "$USER_NAME" -- env "${vars[@]}" "$@"
  else
    env "${vars[@]}" "$@"
  fi
}

# Power state straight from sysfs, so it doesn't depend on parsing acpid's event arguments.
on_ac=0
for d in /sys/class/power_supply/*/; do
  [[ -r ${d}type && -r ${d}online ]] || continue # batteries have no "online" file
  [[ $(<"${d}type") == Mains && $(<"${d}online") == 1 ]] && on_ac=1
done

if ((on_ac)); then
  rate=$AC_RATE
  msg="Switched to ${rate}Hz (High Performance)"
else
  rate=$BAT_RATE
  msg="Switched to ${rate}Hz (Battery Saver)"
fi

current_rate() {
  as_user /usr/bin/hyprctl monitors -j |
    jq -r --arg m "$MONITOR" '.[] | select(.name == $m) | .refreshRate | round'
}

# Already at the right rate (duplicate events, resume, login): skip, so no flicker or popup.
[[ $(current_rate) == "$rate" ]] && exit 0

as_user /usr/bin/hyprctl eval \
  "hl.monitor({ output = '$MONITOR', mode = '${RES}@${rate}', position = 'auto', scale = 1 })" >/dev/null

# Verify instead of trusting: only announce a switch that actually happened.
sleep 0.5
now=$(current_rate)
if [[ -n $now && $now != "$rate" ]]; then
  echo "autorefresh: wanted ${rate}Hz on $MONITOR but it is ${now}Hz" >&2
  exit 1
fi

as_user /usr/bin/notify-send -e -a "refresh-script" \
  -h string:x-canonical-private-synchronous:refresh_notif \
  -u low -t 3500 \
  "Display" "$msg"
