#!/usr/bin/env bash
# Package counts for fastfetch: "N (Pacman)  M (Aur)". The AUR number counts foreign
# packages only (pacman -Qm). The cached value is printed immediately; when a database
# changed, it is recounted in the background, so fastfetch never waits for pacman
# (after a package change the numbers are one run behind).

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch"
CACHE_FILE="$CACHE_DIR/pkgcount.txt"
LOCAL_DB="${PACMAN_LOCAL_DB:-/var/lib/pacman/local}" # changes on install/remove/upgrade
SYNC_DB="${PACMAN_SYNC_DB:-/var/lib/pacman/sync}"    # changes on -Sy; repo<->AUR moves show up here

refresh() {
  set -o pipefail # a failing pacman must not look like "0 packages"
  local pacman_count aur_count tmp
  exec 9>"$CACHE_DIR/pkgcount.lock"
  flock -n 9 || return 0 # a refresh is already running
  pacman_count=$(pacman -Qqn 2>/dev/null | wc -l) || return 1
  aur_count=$(pacman -Qqm 2>/dev/null | wc -l) || return 1
  tmp=$(mktemp "$CACHE_FILE.XXXXXX") || return 1
  printf '%s (Pacman)  %s (Aur)' "$pacman_count" "$aur_count" >"$tmp" && mv "$tmp" "$CACHE_FILE"
}

mkdir -p "$CACHE_DIR"

if [[ ! -s $CACHE_FILE ]]; then
  refresh # first run only: nothing to show yet, so count now
elif [[ $LOCAL_DB -nt $CACHE_FILE || $SYNC_DB -nt $CACHE_FILE ]]; then
  # Detached with stdio closed: fastfetch waits for every process holding its pipe open
  (refresh) </dev/null >/dev/null 2>&1 &
  disown
fi

cat "$CACHE_FILE" 2>/dev/null
