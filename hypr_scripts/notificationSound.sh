#!/usr/bin/env bash
# Plays a sound when swaync receives a notification (swaync "scripts", run-on: receive).
# swaync passes the notification in SWAYNC_* environment variables.

# ---- settings ---------------------------------------------------------------
SOUNDS="$HOME/.config/hypr/scripts/sounds.sh"
SKIP_LOW=true                                        # low-urgency notifications (your OSD-style popups) stay silent
SKIP_SUMMARY='^(VOLUME|Volume|Mic-Level|Microphone)' # volume.sh already plays its own sound

# Which sound plays. A name from the sound theme (ls /usr/share/sounds/freedesktop/stereo)
# or the full path of your own file, e.g. "$HOME/.local/share/sounds/ping.ogg".
DEFAULT_SOUND="device-added"
CRITICAL_SOUND="dialog-error"

# One line per app, keyed by app name (the -a of notify-send). Value = sound, or "none" for
# silent. Apps not listed use DEFAULT_SOUND. Names ending in "-silent" are always silent.
declare -A APP_SOUNDS=(
  [rmpc]=none
  [refresh - script]=none
  # [Telegram]="message"
  # [Thunderbird]="complete"
  # [backup]="$HOME/.local/share/sounds/backup-done.ogg"
)
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

# Pick the sound: default, critical override, then the app's own entry
sound=$DEFAULT_SOUND
[[ $urgency == critical ]] && sound=$CRITICAL_SOUND
[[ -n $SWAYNC_APP_NAME && -n ${APP_SOUNDS[$SWAYNC_APP_NAME]} ]] && sound=${APP_SOUNDS[$SWAYNC_APP_NAME]}
[[ $sound == none ]] && exit 0

# Debounce a burst of notifications into one sound
stamp="$state_dir/notif-sound.last"
now=$(date +%s%3N)
last=$(cat "$stamp" 2>/dev/null || echo 0)
((now - last < MIN_GAP_MS)) && exit 0
echo "$now" >"$stamp"

"$SOUNDS" --sound "$sound"
