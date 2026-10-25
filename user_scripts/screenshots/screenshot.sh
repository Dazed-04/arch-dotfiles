#!/bin/bash
# Screenshot helper.
# Usage: screenshot.sh [--smart | --region | --window | --fullscreen] [--edit]
#   --edit opens the shot in satty instead of saving straight away. Default mode: --smart.

SAVE_DIR="$HOME/Pictures/Screenshots"
FILENAME="screenshot-$(date +'%Y%m%d-%H%M%S').png"
FULL_PATH="$SAVE_DIR/$FILENAME"

# Pressing the keybind again cancels a running selection
pkill -x slurp && exit 0

mkdir -p "$SAVE_DIR" || {
  notify-send -u critical -t 3000 "Cannot create screenshot directory: $SAVE_DIR"
  exit 1
}

MODE="${1:---smart}"
EDIT="$2"
PICKER_PID=

# Freeze the screen while selecting. It must be gone before grim runs, so the overlay
# is not captured; the trap covers cancelled/aborted runs.
freeze() {
  hyprpicker -n -r -z -d &
  PICKER_PID=$!
  sleep 0.1
}
unfreeze() {
  [[ -n $PICKER_PID ]] && kill "$PICKER_PID" 2>/dev/null
  PICKER_PID=
}
trap unfreeze EXIT

# Rectangles of the focused workspace's monitor(s) and visible windows, "x,y WxH"
get_rectangles() {
  local ws
  ws=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace.id')
  hyprctl monitors -j | jq -r --argjson ws "$ws" \
    '.[] | select(.activeWorkspace.id == $ws) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
  hyprctl clients -j | jq -r --argjson ws "$ws" \
    '.[] | select(.mapped != false and .workspace.id == $ws) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

case "$MODE" in
--region)
  freeze
  SELECTION=$(slurp -w 0 -d 2>/dev/null)
  unfreeze
  ;;
--window)
  freeze
  SELECTION=$(get_rectangles | slurp -w 0 -d -r 2>/dev/null)
  unfreeze
  ;;
--fullscreen)
  SELECTION=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"')
  ;;
--smart)
  RECTS=$(get_rectangles)
  freeze
  SELECTION=$(slurp -w 0 -d 2>/dev/null <<<"$RECTS")
  unfreeze

  # A tiny selection (area < 20, i.e. a click) means "the window or output under the
  # click", to avoid accidental 2px screenshots. The smallest rectangle containing the
  # click wins, so a window beats the monitor it sits on.
  if [[ $SELECTION =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]] &&
    ((BASH_REMATCH[3] * BASH_REMATCH[4] < 20)); then
    click_x=${BASH_REMATCH[1]}
    click_y=${BASH_REMATCH[2]}
    best_area=
    while IFS= read -r rect; do
      if [[ $rect =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
        rx=${BASH_REMATCH[1]} ry=${BASH_REMATCH[2]} rw=${BASH_REMATCH[3]} rh=${BASH_REMATCH[4]}
        area=$((rw * rh))
        if ((click_x >= rx && click_x < rx + rw && click_y >= ry && click_y < ry + rh)) &&
          { [[ -z $best_area ]] || ((area < best_area)); }; then
          best_area=$area
          SELECTION="$rx,$ry ${rw}x${rh}"
        fi
      fi
    done <<<"$RECTS"
  fi
  ;;
*)
  echo "Usage: $0 [--smart | --region | --window | --fullscreen] [--edit]"
  echo "  --smart       region, or a click selects the window/output under it (default)"
  echo "  --region      capture a region"
  echo "  --window      capture a window"
  echo "  --fullscreen  capture the focused monitor"
  echo "  --edit        (second argument) edit with satty"
  exit 1
  ;;
esac

[[ -z $SELECTION ]] && exit 0

if [[ $EDIT == --edit ]]; then
  grim -g "$SELECTION" - | env \
    __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json \
    VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.json \
    GSK_RENDERER=ngl \
    satty --filename - \
    --output-filename "$FULL_PATH" \
    --early-exit \
    --actions-on-enter save-to-clipboard \
    --save-after-copy \
    --copy-command 'wl-copy'
elif grim -g "$SELECTION" "$FULL_PATH" && [[ -f $FULL_PATH ]]; then
  wl-copy -t image/png <"$FULL_PATH" &&
    notify-send -i "$FULL_PATH" "📸 Screenshot Taken" "$FILENAME copied to clipboard."
else
  notify-send -u critical "Error" "Failed to capture screenshot."
  exit 1
fi
