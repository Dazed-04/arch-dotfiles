#!/bin/bash
# Rofi script mode "Media": OBS recording controls through obs-cmd (websocket).
# No argument prints the entries for the current OBS state; a pick is run in the
# background via "--exec" so rofi can close straight away.

OBS_PASS=$(tr -d '[:space:]' <"$HOME/.config/hypr/.obs-secret" 2>/dev/null)
WEBSOCKET="obsws://localhost:4455/${OBS_PASS}"
PROJECTOR_RE='.*Projector.*' # Hyprland title regex of the OBS projector window

obsc() { timeout 5 obs-cmd --websocket "$WEBSOCKET" "$@"; }

close_projector() {
  hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = 'title:$PROJECTOR_RE' }))" >/dev/null 2>&1
}

open_preview() {
  # Substring match: jq's contains() is not a regex, so the old "Projector.*" never matched
  if hyprctl clients -j | jq -e 'any(.[]; .title | test("Projector"))' &>/dev/null; then
    return 0
  fi
  obsc source-projector "Video Capture Device (V4L2)" --monitor-index '0'
}

get_obs_status() {
  obsc recording status 2>/dev/null
}

is_recording() {
  grep -q "Active: true" <<<"$(get_obs_status)"
}

# After "recording stop" OBS still needs a moment to finalise the file
wait_until_stopped() {
  for _ in {1..20}; do
    is_recording || return 0
    sleep 0.25
  done
  return 1
}

start_recording() {
  local scene="$1"
  if ! pgrep -x obs >/dev/null; then
    hyprctl eval 'hl.dispatch(hl.dsp.exec_cmd("uwsm app -- obs", { workspace = "8 silent" }))' >/dev/null
    notify-send "OBS" "Starting OBS, please wait..."
    sleep 2
    local retries=0
    while ! obsc scene list &>/dev/null; do
      sleep 2
      ((++retries >= 10)) && {
        notify-send -u critical "OBS" "Failed to connect to OBS WebSocket"
        return 1
      }
    done
  fi

  # Don't restart recording if already recording
  if is_recording; then
    notify-send "OBS" "Already recording"
    return 0
  fi

  obsc scene switch "$scene"
  if obsc recording start; then
    notify-send "OBS" "Recording started: $scene"
  else
    notify-send -u critical "OBS" "Could not start recording"
    return 1
  fi

  # Only open preview for Camera & Mic scene
  if [[ $scene == "Camera & Mic" || $scene == "Recording and Camera" ]]; then
    (
      sleep 1
      open_preview
    ) &
  fi
}

if [[ $1 == "--exec" ]]; then
  case "$2" in
  "Screen Record" | "Recording and Camera" | "Camera & Mic") start_recording "$2" ;;
  "Pause Recording")
    obsc recording pause && notify-send "OBS" "Recording Paused"
    ;;
  "Resume Recording")
    obsc recording resume && notify-send "OBS" "Recording Resumed"
    ;;
  "Stop Recording")
    obsc recording stop >/dev/null 2>&1
    wait_until_stopped
    close_projector
    notify-send "OBS" "Recording Stopped & Saved"
    ;;
  "Close OBS")
    obsc recording stop >/dev/null 2>&1
    wait_until_stopped
    close_projector
    pkill -x obs
    notify-send "OBS" "Closed"
    ;;
  esac
  exit 0
fi

if (($# == 0)); then
  if pgrep -x obs >/dev/null; then
    STATUS=$(get_obs_status)
    if grep -q "Active: true" <<<"$STATUS"; then
      if grep -q "Paused: true" <<<"$STATUS"; then
        printf "%s\n" "󰐊 Resume Recording" "󰓛 Stop Recording" "󰹅 Close OBS"
      else
        printf "%s\n" "󰏤 Pause Recording" "󰓛 Stop Recording" "󰹅 Close OBS"
      fi
    else
      printf "%s\n" "󰑋 Screen Record" "󰑋 Recording and Camera" "󰑋 Camera & Mic" "󰹅 Close OBS"
    fi
  else
    printf "%s\n" "󰑋  Screen Record" "󰑋  Recording and Camera" "󰑋  Camera & Mic"
  fi
  exit 0
fi

case "$1" in
*"Screen Record"*) CMD="Screen Record" ;;
*"Recording and Camera"*) CMD="Recording and Camera" ;;
*"Camera & Mic"*) CMD="Camera & Mic" ;;
*"Pause Recording"*) CMD="Pause Recording" ;;
*"Resume Recording"*) CMD="Resume Recording" ;;
*"Stop Recording"*) CMD="Stop Recording" ;;
*"Close OBS"*) CMD="Close OBS" ;;
esac

if [[ -n $CMD ]]; then
  nohup bash "$0" --exec "$CMD" >/dev/null 2>&1 &
  disown
fi
