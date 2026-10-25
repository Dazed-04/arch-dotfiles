#!/usr/bin/env bash

set -Eeuo pipefail

# === CONFIGURATION ===

# Directories
wallpaperDir="$HOME/Pictures/wallpapers"
themesDir="$HOME/.config/rofi/launcher-themes"
cacheDir="$HOME/.cache/wallpaper-selector"
listCache="$cacheDir/wallpaper_list.txt"
thumbDir="$cacheDir/thumbnails"
currentLink="$cacheDir/current_wallpaper"

# Extras
randomQueueFile="$cacheDir/random_queue.txt"
shuffleMenu=true
versionFile="$cacheDir/.cache_version"
# Bump this whenever the thumbnail naming/size scheme changes, so old caches rebuild
CACHE_VERSION=2

mkdir -p "$thumbDir"

# Transition settings
FPS=60
TYPE="any"
DURATION=1
BEZIER="0.4,0.2,0.4,1.0"
AWWW_PARAMS=(
  --transition-fps "${FPS}"
  --transition-type "${TYPE}"
  --transition-duration "${DURATION}"
  --transition-bezier "${BEZIER}"
)

# === HELPERS ===
check_deps() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      notify-send -u critical "Wallpaper Selector" "Missing dependency: $cmd"
      exit 1
    fi
  done
}

# Thumbnail path rule (used everywhere, inline):
#   "${thumbDir}/${pic//\//_}.png"
# The full path with the extension is kept, so a.jpg and a.png never collide.

# Thumbnail generation (parallel, space-safe, tolerant of bad images)
generate_thumbnails() {
  local list="$1"
  export thumbDir
  tr '\n' '\0' <"$list" | xargs -0 -n1 -P "$(nproc)" bash -c '
    pic="$1"
    thumb="${thumbDir}/${pic//\//_}.png"

    # Skip if the thumbnail exists and is newer than the source image
    [[ -f "$thumb" && "$thumb" -nt "$pic" ]] && exit 0

    # [0] picks the first frame of GIFs (harmless for other formats)
    magick "${pic}[0]" -auto-orient -thumbnail "400x500^" -gravity center -extent 400x500 "$thumb" 2>/dev/null || rm -f "$thumb"
  ' _ || true
}

# === COLLECT WALLPAPERS ===
ensure_cache() {
  if [[ ! -d "$wallpaperDir" ]]; then
    notify-send -u critical "Wallpaper Selector" "Directory not found: $wallpaperDir"
    exit 1
  fi

  local stale=0
  if [[ ! -f "$listCache" || "$(cat "$versionFile" 2>/dev/null || true)" != "$CACHE_VERSION" ]]; then
    stale=1
  elif [[ -n "$(find -L "$wallpaperDir" -newer "$listCache" -print -quit)" ]]; then
    # Includes directories, so deleted/renamed files (which bump the dir mtime) are noticed too
    stale=1
  fi

  ((stale)) || return 0

  local tmpList="${listCache}.tmp"
  find -L "$wallpaperDir" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) |
    LC_ALL=C sort >"$tmpList"

  # Remove orphaned thumbnails (exist on disk but no longer expected)
  LC_ALL=C comm -23 \
    <(find "$thumbDir" -maxdepth 1 -name "*.png" -printf "%f\n" | LC_ALL=C sort) \
    <(sed -e 's|/|_|g' -e 's/$/.png/' "$tmpList" | LC_ALL=C sort) |
    while IFS= read -r orphan; do
      rm -f "${thumbDir}/${orphan}"
    done || true

  generate_thumbnails "$tmpList"

  # Only publish the list after thumbnails are done, so an interrupted run retries next time
  mv "$tmpList" "$listCache"
  echo "$CACHE_VERSION" >"$versionFile"
}

# === RANDOM PICKER (shuffled queue, skips current, avoids GIFs) ===
pick_random_picture() {
  # Called inside $(...), so the lock fd is released when the subshell exits
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$cacheDir/random.lock"
    flock 9
  fi

  local current candidate attempts=0
  current="$(readlink -f "$currentLink" 2>/dev/null || true)"

  while ((attempts++ < 1000)); do
    if [[ ! -s "$randomQueueFile" ]]; then
      grep -iv '\.gif$' "$listCache" | shuf >"$randomQueueFile" || true
      if [[ ! -s "$randomQueueFile" ]]; then
        # Fallback if only GIFs exist
        shuf "$listCache" >"$randomQueueFile"
      fi
    fi

    candidate="$(head -n 1 "$randomQueueFile")"
    tail -n +2 "$randomQueueFile" >"${randomQueueFile}.tmp" && mv "${randomQueueFile}.tmp" "$randomQueueFile"

    [[ -f "$candidate" ]] || continue

    # Compare resolved paths so symlinked wallpapers are handled correctly
    if [[ "$(readlink -f "$candidate")" == "$current" && -s "$randomQueueFile" ]]; then
      echo "$candidate" >>"$randomQueueFile"
      continue
    fi

    echo "$candidate"
    return 0
  done

  notify-send -u critical "Wallpaper Selector" "Could not pick a random wallpaper."
  return 1
}

apply_random() {
  local wp
  wp="$(pick_random_picture)" || exit 1
  executeCommand "$wp"
}

# === DISPLAY ROFI MENU ===
menu() {
  local pic filename name thumb
  for pic in "${PICS[@]}"; do
    filename="${pic##*/}"
    name="${filename%.*}"
    thumb="${thumbDir}/${pic//\//_}.png"
    printf "%s\x00icon\x1f%s\x00info\x1f%s\n" "$name" "$thumb" "$pic"
  done
}

# === WALLPAPER SETTER ===
executeCommand() {
  local wp="$1"

  # 1. Apply wallpaper
  awww img "$wp" "${AWWW_PARAMS[@]}"

  # 2. Update symlinks
  ln -sf "$wp" "$currentLink"
  mkdir -p "$HOME/.config/rofi" "$HOME/.config/hypr"
  ln -sf "$wp" "$HOME/.config/rofi/.current_wallpaper"
  ln -sf "$wp" "$HOME/.config/hypr/.current_wallpaper"

  # 3. Generate color palette via Matugen
  local matugen_output clean_error
  if ! matugen_output=$(matugen --quiet --mode dark --fallback-color "#fa94c3" --prefer saturation image "$wp" 2>&1); then
    clean_error=$(printf "%s" "$matugen_output" | sed 's/\x1b\[[0-9;]*m//g')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $clean_error" >>"$cacheDir/matugen_error.log"
    notify-send -u critical -t 0 "⚠️ Matugen Error" "$clean_error"
  fi

  sleep 0.1

  # 4. Refresh Waybar and other components
  pkill -x waybar || true
  if command -v uwsm-app >/dev/null 2>&1; then
    uwsm-app -- waybar &
  fi

  if command -v swaync-client >/dev/null 2>&1; then
    swaync-client -R -rs
  fi
}

# === MAIN FUNCTION ===
openMenu() {
  # Toggle: close rofi if it's already open
  if pidof rofi >/dev/null 2>&1; then
    pkill -x rofi
    exit 0
  fi

  local choice_index
  choice_index=$(menu | "${rofiCommand[@]}") || exit 0

  # Empty or negative means ESC / nothing selected
  [[ -z "$choice_index" || "$choice_index" -lt 0 ]] && exit 0

  local selected_file="${PICS[$choice_index]:-}"

  if [[ -n "$selected_file" && -f "$selected_file" ]]; then
    executeCommand "$selected_file"
  else
    notify-send -u critical "Wallpaper Selector" "Error: Image not found."
    exit 1
  fi
}

# Loads the wallpaper list into PICS and sets up the rofi command
load_pics() {
  ensure_cache

  # Shuffle the menu order on every launch. Index lookups use this same array,
  # so the selected entry always maps to the right file.
  if [[ "$shuffleMenu" == true ]]; then
    mapfile -t PICS < <(shuf "$listCache")
  else
    mapfile -t PICS <"$listCache"
  fi

  if [[ ${#PICS[@]} -eq 0 ]]; then
    notify-send -u critical "Wallpaper Selector" "No wallpapers found in $wallpaperDir"
    exit 1
  fi

  rofiCommand=(
    rofi
    -dmenu
    -theme "${themesDir}/wallpaper-select.rasi"
    -format i
    -no-custom
  )
}

# === CLI INTERFACE ===
case "${1:---menu}" in
--set)
  shift
  if [[ -z "${1:-}" || ! -f "$1" ]]; then
    echo "Error: Valid file required for --set" >&2
    exit 1
  fi
  # --set needs no cache or thumbnails, so skip the scan entirely
  check_deps awww matugen
  executeCommand "$(readlink -f "$1")"
  ;;
--menu)
  check_deps rofi awww magick matugen
  load_pics
  openMenu
  ;;
--random)
  check_deps awww magick matugen
  load_pics
  apply_random
  ;;
*)
  echo "Usage: $0 [--menu | --set FILE | --random]" >&2
  exit 1
  ;;
esac
