#!/usr/bin/env bash
# dependencies: pipewire (pw-dump), jq, psmisc (fuser), procps-ng (pgrep, ps)
# optional: systemd (busctl) for GeoClue app names
set -uo pipefail

JQ_BIN="${JQ:-jq}"
PW_DUMP_CMD="${PW_DUMP:-pw-dump}"

mic=0
cam=0
loc=0
scr=0

mic_app=""
cam_app=""
loc_app=""
scr_app=""

# mic & screen sharing: one pw-dump and one jq pass.
# Only nodes in the "running" state count, so leftover idle streams are ignored.
if command -v "$PW_DUMP_CMD" >/dev/null 2>&1 && command -v "$JQ_BIN" >/dev/null 2>&1; then
  dump="$($PW_DUMP_CMD 2>/dev/null || true)"
  if [[ -n "$dump" ]]; then
    mapfile -t pw < <(
      printf '%s' "$dump" | $JQ_BIN -r '
        def p: (.info.props // {});
        def running: ((.info.state // .state // "") == "running");
        [ .[] | select(.type == "PipeWire:Interface:Node") | select(running) ] as $nodes
        | ( [ $nodes[]
              | select(p["media.class"] == "Audio/Source" or p["media.class"] == "Audio/Source/Virtual")
            ] | length > 0 ) as $mic
        | ( [ $nodes[]
              | select(p["media.class"] == "Stream/Input/Audio")
              | (p["application.name"] // p["node.name"] // "?")
            ] | unique | join(", ") ) as $mic_app
        | ( [ $nodes[]
              | select((p["media.name"] // "") | test("^(xdph-streaming|gsr-default|game capture)"))
            ] | length > 0 ) as $scr
        | ( [ $nodes[]
              | select(p["media.class"] == "Stream/Input/Video"
                       or ((p["media.name"] // "") | test("^(gsr-default_output|game capture)$")))
              | (p["application.name"] // p["media.name"] // "?")
            ] | unique | join(", ") ) as $scr_app
        | (if $mic then 1 else 0 end),
          $mic_app,
          (if $scr then 1 else 0 end),
          (if $scr then $scr_app else "" end)
      ' 2>/dev/null
    )
    if ((${#pw[@]} >= 4)); then
      mic="${pw[0]}"
      mic_app="${pw[1]}"
      scr="${pw[2]}"
      scr_app="${pw[3]}"
    fi
  fi
fi
[[ "$mic" == 1 ]] || mic=0
[[ "$scr" == 1 ]] || scr=0

# camera: processes holding any /dev/video* node open; names de-duplicated
if command -v fuser >/dev/null 2>&1; then
  cam_names=()
  for dev in /dev/video*; do
    [[ -e "$dev" ]] || continue
    pids="$(fuser "$dev" 2>/dev/null || true)"
    for pid in $pids; do
      pid="${pid//[!0-9]/}"
      [[ -n "$pid" ]] || continue
      cam=1
      pname="$(ps -p "$pid" -o comm= 2>/dev/null || true)"
      [[ -n "$pname" ]] && cam_names+=("$pname")
    done
  done
  if ((${#cam_names[@]} > 0)); then
    cam_app="$(printf '%s\n' "${cam_names[@]}" | sort -u | paste -sd, - | sed 's/,/, /g')"
  fi
fi

# location: GeoClue is D-Bus activated, so a running process normally means a
# client is using it. Only ask it for details once it is known to be running
# (asking would otherwise start the service).
if pgrep -x geoclue >/dev/null 2>&1; then
  loc=1
  in_use="$(timeout 1 busctl --system get-property org.freedesktop.GeoClue2 /org/freedesktop/GeoClue2/Manager org.freedesktop.GeoClue2.Manager InUse 2>/dev/null || true)"
  if [[ "$in_use" == "b false" ]]; then
    loc=0
  else
    geo_names=()
    while IFS= read -r obj; do
      [[ -n "$obj" ]] || continue
      id="$(timeout 1 busctl --system get-property org.freedesktop.GeoClue2 "$obj" org.freedesktop.GeoClue2.Client DesktopId 2>/dev/null || true)"
      id="${id#s \"}"
      id="${id%\"}"
      [[ -n "$id" && "$id" != "s" ]] && geo_names+=("$id")
    done < <(timeout 1 busctl --system tree --list org.freedesktop.GeoClue2 2>/dev/null | grep -E '/Client/[0-9]+$' || true)
    if ((${#geo_names[@]} > 0)); then
      loc_app="$(printf '%s\n' "${geo_names[@]}" | sort -u | paste -sd, - | sed 's/,/, /g')"
    else
      loc_app="geoclue"
    fi
  fi
fi

# output
green="#30D158"
orange="#FF9F0A"
blue="#0A84FF"
purple="#9B32FA"

dot() {
  local on="$1" color="$2" symbol="$3"
  if [[ "$on" -eq 1 ]]; then
    printf '<span font="Font Awesome 7 Free Solid" foreground="%s">%s</span>' "$color" "$symbol"
  else
    printf ''
  fi
}

dots=()
mic_dot="$(dot "$mic" "$green" "")"
[[ -n "$mic_dot" ]] && dots+=("$mic_dot")
cam_dot="$(dot "$cam" "$orange" "󰄀 ")"
[[ -n "$cam_dot" ]] && dots+=("$cam_dot")
loc_dot="$(dot "$loc" "$blue" "")"
[[ -n "$loc_dot" ]] && dots+=("$loc_dot")
scr_dot="$(dot "$scr" "$purple" "󰹑 ")"
[[ -n "$scr_dot" ]] && dots+=("$scr_dot")

text="${dots[*]}"

status() { # label, on (0/1), app names
  if [[ "$2" -eq 1 ]]; then
    printf '%s: %s' "$1" "${3:-on}"
  else
    printf '%s: off' "$1"
  fi
}

mic_status="$(status "Mic" "$mic" "$mic_app")"
cam_status="$(status "Cam" "$cam" "$cam_app")"
loc_status="$(status "Location" "$loc" "$loc_app")"
scr_status="$(status "Screen sharing" "$scr" "$scr_app")"

tooltip="$mic_status  |  $cam_status  |  $loc_status  |  $scr_status"

classes=(privacydot)
if [[ "$mic" -eq 1 ]]; then classes+=(mic-on); else classes+=(mic-off); fi
if [[ "$cam" -eq 1 ]]; then classes+=(cam-on); else classes+=(cam-off); fi
if [[ "$loc" -eq 1 ]]; then classes+=(loc-on); else classes+=(loc-off); fi
if [[ "$scr" -eq 1 ]]; then classes+=(scr-on); else classes+=(scr-off); fi

# The tooltip is plain text but Waybar renders it as Pango markup, so escape
# &, < and > in app names (@html). "class" is an array so each one is a real CSS class.
jq -c -n --arg text "$text" --arg tooltip "$tooltip" \
  '{text:$text, tooltip:($tooltip | @html), class:$ARGS.positional}' --args "${classes[@]}"
