#!/bin/bash
# Plays a freedesktop theme sound. Usage: sounds.sh --screenshot | --volume | --notification | --error

theme="freedesktop"
mute=false

# Mute individual sounds here.
muteScreenshots=false
muteVolume=false
muteNotifications=false
muteErrors=false

# Exit if the system sounds are muted.
if [[ "$mute" = true ]]; then
  exit 0
fi

# Choose the sound to play.
case "$1" in
--screenshot)
  [[ "$muteScreenshots" = true ]] && exit 0
  soundoption="screen-capture.*"
  ;;
--volume)
  [[ "$muteVolume" = true ]] && exit 0
  soundoption="audio-volume-change.*"
  ;;
--notification)
  [[ "$muteNotifications" = true ]] && exit 0
  soundoption="message-new-instant.*"
  ;;
--error)
  [[ "$muteErrors" = true ]] && exit 0
  soundoption="dialog-error.*"
  ;;
*)
  echo -e "Available sounds: --screenshot, --volume, --notification, --error"
  exit 0
  ;;
esac

# Set the directory defaults for system sounds.
if [ -d "/run/current-system/sw/share/sounds" ]; then
  systemDIR="/run/current-system/sw/share/sounds" # NixOS
else
  systemDIR="/usr/share/sounds"
fi
userDIR="$HOME/.local/share/sounds"
defaultTheme="freedesktop"

# Prefer the user's theme, but use the system's if it doesn't exist.
sDIR="$systemDIR/$defaultTheme"
if [ -d "$userDIR/$theme" ]; then
  sDIR="$userDIR/$theme"
elif [ -d "$systemDIR/$theme" ]; then
  sDIR="$systemDIR/$theme"
fi

# Get the theme that it inherits.
iTheme=$(grep -i "^inherits" "$sDIR/index.theme" 2>/dev/null | cut -d "=" -f 2)
iDIR="$sDIR/../$iTheme"

# Find the sound file and play it.
sound_file=""
for dir in "$sDIR" "$iDIR" "$userDIR/$defaultTheme" "$systemDIR/$defaultTheme"; do
  sound_file=$(find "$dir/stereo" -name "$soundoption" -print -quit 2>/dev/null)
  [[ -f "$sound_file" ]] && break
done
if [[ ! -f "$sound_file" ]]; then
  echo "Error: Sound file not found."
  exit 1
fi

# pipewire priority, fallback pulseaudio
pw-play "$sound_file" || pa-play "$sound_file"
