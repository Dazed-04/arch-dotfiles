#!/usr/bin/env bash
# Plays a sound when swaync receives a notification (swaync "scripts", run-on: receive).
# swaync passes the notification in SWAYNC_* environment variables.

# ---- settings ---------------------------------------------------------------
SOUNDS="$HOME/.config/hypr/scripts/sounds.sh"
SOUND_ARGS=(--notification)                          # default: every notification makes this sound...
CRITICAL_ARGS=(--error)                              # ...critical ones use this one
SKIP_LOW=true                                        # low-urgency notifications (your OSD-style popups) stay silent
SKIP_SUMMARY='^(VOLUME|Volume|Mic-Level|Microphone)' # volume.sh already plays its own sound
# Silent senders. Anything not listed here (or named "*-silent") makes the default sound.
# To silence a notify-send, give it an app name:  notify-send -a something-silent ...
SKIP_APPS=(rmpc refresh-script)
MIN_GAP_MS=400 # ignore notifications arriving within this time of the last sound
# -----------------------------------------------------------------------------

# Hand off to a detached copy straight away, so swaync never waits on us (the work below
# talks to swaync again, which could otherwise block).
if [[ -z $NOTIF_SOUND_BG ]]; then
  NOTIF_SOUND_BG=1 setsid -f "$0" "$@" </dev/null >/dev/null 2>&1
  exit 0
fi

state_dir="${XDG_RUNTIME_DIR:-/tmp}"

# Debug: `touch $XDG_RUNTIME_DIR/notif-sound.debug` logs what swaync passes in
[[ -e $state_dir/notif-sound.debug ]] &&
  env | grep '^SWAYNC_' >>"$state_dir/notif-sound.log" && echo '---' >>"$state_dir/notif-sound.log"

# Do not disturb: no sound
[[ $(swaync-client -D 2>/dev/null) == true ]] && exit 0

urgency="${SWAYNC_URGENCY,,}"
[[ $SKIP_LOW == true && $urgency == low ]] && exit 0
[[ -n $SKIP_SUMMARY && $SWAYNC_SUMMARY =~ $SKIP_SUMMARY ]] && exit 0
[[ $SWAYNC_APP_NAME == *-silent ]] && exit 0
for app in "${SKIP_APPS[@]}"; do
  [[ $SWAYNC_APP_NAME == "$app" ]] && exit 0
done

# Debounce a burst of notifications into one sound
stamp="$state_dir/notif-sound.last"
now=$(date +%s%3N)
last=$(cat "$stamp" 2>/dev/null || echo 0)
((now - last < MIN_GAP_MS)) && exit 0
echo "$now" >"$stamp"

if [[ $urgency == critical ]]; then
  "$SOUNDS" "${CRITICAL_ARGS[@]}"
else
  "$SOUNDS" "${SOUND_ARGS[@]}"
fi
