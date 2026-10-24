#!/usr/bin/env bash
# Prints the path of a small cover image for the song MPD is playing.
# Prints nothing (or $FALLBACK) when there is no art, so callers can handle it.

set -o pipefail

MUSIC_DIR="${MUSIC_DIR:-$HOME/Music}" # must match music_directory in mpd.conf
CACHE_DIR="${CACHE_DIR:-$HOME/.cache/albumart}"
SIZE=256
PER_ALBUM="${PER_ALBUM:-false}" # true = one cached image per album folder (fewer extractions)
FALLBACK=""                     # optional image to print when a song has no art

mkdir -p "$CACHE_DIR"

no_art() {
  [[ -n $FALLBACK && -f $FALLBACK ]] && printf '%s\n' "$FALLBACK"
  exit 0
}

rel=$(mpc -f '%file%' current 2>/dev/null)
[[ -n $rel ]] || exit 0 # nothing playing

src="$MUSIC_DIR/$rel"
[[ -f $src ]] || no_art # stream, or MUSIC_DIR doesn't match MPD's

# Cache key: hash of the full path (or of the album folder), so two files with
# the same name in different folders never share an image.
if [[ $PER_ALBUM == true ]]; then key_src=${rel%/*}; else key_src=$rel; fi
key=$(printf '%s' "$key_src" | md5sum | cut -d' ' -f1)
out="$CACHE_DIR/$key.png"
none="$CACHE_DIR/$key.none" # marker: "already tried, this song has no art"

# Fast path: answer from the cache (also used again after taking the lock)
answer_from_cache() {
  if [[ -f $out ]]; then
    printf '%s\n' "$out"
    exit 0
  fi
  [[ -f $none ]] && no_art
}
answer_from_cache

# Only one instance extracts at a time. Parallel callers (lockscreen, rmpc,
# waybar polling) wait here, then find the finished image in the cache.
exec 9>"$CACHE_DIR/.lock"
flock 9
answer_from_cache

# Work in a private temp file, then move it into place atomically.
tmp=$(mktemp "$CACHE_DIR/.tmp.XXXXXX") || exit 1
trap 'rm -f "$tmp"' EXIT

# 1. Embedded art. ffmpeg handles mp3/m4a/flac/ogg alike, so no per-format code.
if ffmpeg -nostdin -loglevel error -i "$src" -map 0:v:0 -frames:v 1 -c copy -f image2pipe - 2>/dev/null |
  magick - -auto-orient -strip -resize "${SIZE}x${SIZE}>" "PNG:$tmp" 2>/dev/null &&
  [[ -s $tmp ]]; then
  mv -f "$tmp" "$out"
  printf '%s\n' "$out"
  exit 0
fi

# 2. Cover file next to the song (cover/folder/front/albumart .jpg/.png)
img=$(find "${src%/*}" -maxdepth 1 -type f \
  -iregex '.*/\(cover\|folder\|front\|albumart\)\.\(jpe?g\|png\)' -print -quit 2>/dev/null)
if [[ -n $img ]] &&
  magick "${img}[0]" -auto-orient -strip -resize "${SIZE}x${SIZE}>" "PNG:$tmp" 2>/dev/null &&
  [[ -s $tmp ]]; then
  mv -f "$tmp" "$out"
  printf '%s\n' "$out"
  exit 0
fi

# 3. Nothing found: remember it, so polling doesn't re-run ffmpeg every second.
: >"$none"
no_art
