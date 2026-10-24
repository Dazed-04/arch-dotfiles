#!/bin/bash
# Volume and microphone control with notifications.
# Usage: volume.sh [--get | --inc | --dec | --toggle | --toggle-mic | --get-icon |
#                   --get-mic-icon | --mic-inc | --mic-dec]

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"
MIC=(--default-source) # pamixer flag for the microphone; the speakers need none

# "Muted" when muted (or at 0), otherwise "NN%". Takes an optional pamixer device flag.
get_level() {
  local v
  v=$(pamixer "$@" --get-volume) || return 1
  if [[ $v -eq 0 || $(pamixer "$@" --get-mute) == true ]]; then
    echo "Muted"
  else
    echo "$v%"
  fi
}

is_muted() { [[ $(pamixer "$@" --get-mute) == true ]]; }

# Icon for a level as printed by get_level
volume_icon() {
  local n=${1%\%}
  if [[ $1 == Muted ]]; then
    echo "$iDIR/volume-mute.png"
  elif ((n <= 30)); then
    echo "$iDIR/volume-low.png"
  elif ((n <= 60)); then
    echo "$iDIR/volume-mid.png"
  else
    echo "$iDIR/volume-high.png"
  fi
}

mic_icon() {
  local level=${1:-$(get_level "${MIC[@]}")}
  if [[ $level == Muted ]]; then
    echo "$iDIR/microphone-mute.png"
  else
    echo "$iDIR/microphone.png"
  fi
}

# --- Speakers ---------------------------------------------------------------

notify_user() {
  local level
  level=$(get_level)
  if [[ $level == Muted ]]; then
    notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(volume_icon "$level")" "Volume: Muted"
  else
    notify-send -e -h int:value:"${level%\%}" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(volume_icon "$level")" "VOLUME: $level"
    # In the background, so a held key isn't slowed down by the sound playing
    "$sDIR/sounds.sh" --volume >/dev/null 2>&1 &
    disown
  fi
}

inc_volume() {
  if is_muted; then
    toggle_mute
  else
    pamixer -i 5 --allow-boost --set-limit 150 && notify_user
  fi
}

dec_volume() {
  if is_muted; then
    toggle_mute
  else
    pamixer -d 5 && notify_user
  fi
}

toggle_mute() {
  if is_muted; then
    pamixer -u && notify-send -e -u low -i "$(volume_icon "$(get_level)")" "VOLUME Switched ON"
  else
    pamixer -m && notify-send -e -u low -i "$iDIR/volume-mute.png" "Volume Switched OFF"
  fi
}

# --- Microphone -------------------------------------------------------------

notify_mic_user() {
  local level raw
  level=$(get_level "${MIC[@]}")
  raw=${level%\%} # number for the progress bar
  [[ $level == Muted ]] && raw=0
  notify-send -e -h int:value:"$raw" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(mic_icon "$level")" "Mic-Level: $level"
}

toggle_mic() {
  if is_muted "${MIC[@]}"; then
    pamixer "${MIC[@]}" -u && notify-send -e -u low -i "$iDIR/microphone.png" "Microphone Switched ON"
  else
    pamixer "${MIC[@]}" -m && notify-send -e -u low -i "$iDIR/microphone-mute.png" "Microphone Switched OFF"
  fi
}

inc_mic_volume() {
  if is_muted "${MIC[@]}"; then
    toggle_mic
  else
    pamixer "${MIC[@]}" -i 5 && notify_mic_user
  fi
}

dec_mic_volume() {
  if is_muted "${MIC[@]}"; then
    toggle_mic
  else
    pamixer "${MIC[@]}" -d 5 && notify_mic_user
  fi
}

# --- Entry point ------------------------------------------------------------

case "$1" in
--get) get_level ;;
--inc) inc_volume ;;
--dec) dec_volume ;;
--toggle) toggle_mute ;;
--toggle-mic) toggle_mic ;;
--get-icon) volume_icon "$(get_level)" ;;
--get-mic-icon) mic_icon ;;
--mic-inc) inc_mic_volume ;;
--mic-dec) dec_mic_volume ;;
*) get_level ;;
esac
