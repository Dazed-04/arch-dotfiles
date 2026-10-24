#!/bin/bash

notif="$HOME/.config/swaync/images/bell.png"
SAVE="${XDG_RUNTIME_DIR:-/tmp}/opacity_toggle_saved"

ALT_ACTIVE="1.0"
ALT_INACTIVE="1.0"
ALT_BLUR="false"

get() {
  hyprctl getoption "$1" -j | jq -r '.bool // .float // .int'
}

apply() {
  local active="$1"
  local inactive="$2"
  local blur="$3"

  # Normalize blur strictly to true or false for Lua
  if [[ "$blur" == "true" || "$blur" == "1" ]]; then
    blur_bool="true"
  else
    blur_bool="false"
  fi

  hyprctl eval "hl.config({ decoration = { active_opacity = ${active}, inactive_opacity = ${inactive}, blur = { enabled = ${blur_bool} } } })" >/dev/null
}

if [[ -f "$SAVE" ]]; then
  # Snapshot exists -> Restore normal mode
  read -r a i b <"$SAVE"

  [[ -z "$a" || "$a" == "null" ]] && a="1.0"
  [[ -z "$i" || "$i" == "null" ]] && i="0.9"
  [[ "$b" != "true" && "$b" != "false" ]] && b="true"

  apply "$a" "$i" "$b"
  rm -f "$SAVE"
  notify-send -e -u low -i "$notif" "Transparency and blur on"
else
  # Normal mode -> Save snapshot and enter clear mode
  cur_a=$(get decoration:active_opacity)
  cur_i=$(get decoration:inactive_opacity)
  cur_b=$(get decoration:blur:enabled)

  [[ -z "$cur_a" || "$cur_a" == "null" ]] && cur_a="1.0"
  [[ -z "$cur_i" || "$cur_i" == "null" ]] && cur_i="0.9"
  [[ "$cur_b" != "true" && "$cur_b" != "false" ]] && cur_b="true"

  echo "$cur_a $cur_i $cur_b" >"$SAVE"
  apply "$ALT_ACTIVE" "$ALT_INACTIVE" "$ALT_BLUR"
  notify-send -e -u low -i "$notif" "Clear mode"
fi
