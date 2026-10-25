#!/bin/bash
# Rofi script mode "Network": Wi-Fi / Bluetooth toggles and manager launchers.

wifi_status=$(nmcli radio wifi)
bt_status=$(timeout 2 bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')

wifi_toggle="󰤭  Turn Off WiFi"
[[ $wifi_status != "enabled" ]] && wifi_toggle="󰤨  Turn On WiFi"

bt_toggle="󰂲  Turn Off Bluetooth"
[[ $bt_status != "yes" ]] && bt_toggle="󰂯  Turn On Bluetooth"

if (($# == 0)); then
  printf "%s\n" \
    "$wifi_toggle" \
    "󰤨  Open WiFi Manager" \
    "󰂱  Open Bluetooth Manager" \
    "$bt_toggle"
  exit 0
fi

case "$1" in
*"Turn Off WiFi")
  pkill -x rofi
  nmcli radio wifi off && notify-send "WiFi" "Disabled"
  ;;
*"Turn On WiFi")
  pkill -x rofi
  nmcli radio wifi on && notify-send "WiFi" "Enabled"
  ;;
*"Open WiFi Manager")
  pkill -x rofi
  "$HOME/.local/bin/myScripts/utilities/wlctl.sh"
  ;;
*"Turn Off Bluetooth")
  pkill -x rofi
  bluetoothctl power off >/dev/null 2>&1 && notify-send "Bluetooth" "Disabled"
  ;;
*"Turn On Bluetooth")
  pkill -x rofi
  rfkill unblock bluetooth # power on fails while the radio is soft-blocked
  bluetoothctl power on >/dev/null 2>&1 && notify-send "Bluetooth" "Enabled"
  ;;
*"Open Bluetooth Manager")
  pkill -x rofi
  if [[ $bt_status != "yes" ]]; then
    rfkill unblock bluetooth
    bluetoothctl power on >/dev/null 2>&1
    sleep 0.2
  fi
  "$HOME/.local/bin/myScripts/utilities/bluetui.sh"
  ;;
esac
