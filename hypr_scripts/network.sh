#!/bin/bash
# Prints a status icon for the active connection (used by hyprlock).

# One call: "TYPE:STATE" per device, e.g. "ethernet:connected", "wifi:connected",
# "loopback:connected (externally)", "bridge:connected (externally)"
devices=$(nmcli -t -f TYPE,STATE device 2>/dev/null)

if grep -q '^ethernet:connected' <<<"$devices"; then
  printf "󰈀⠀\n"
elif grep -q '^wifi:connected' <<<"$devices"; then
  # SIGNAL is 0-100 for the access point we're connected to
  signal=$(nmcli -t -f ACTIVE,SIGNAL device wifi list 2>/dev/null | awk -F: '$1 == "yes" { print $2; exit }')
  if [[ ! $signal =~ ^[0-9]+$ ]]; then
    printf "Wi-Fi signal unknown\n"
  elif ((signal <= 10)); then
    printf "󰤯⠀\n"
  elif ((signal <= 35)); then
    printf "󰤟⠀\n"
  elif ((signal <= 60)); then
    printf "󰤢⠀\n"
  elif ((signal <= 80)); then
    printf "󰤥⠀\n"
  else
    printf "󰤨⠀\n"
  fi
elif grep -Eq '^(wifi|ethernet):connecting' <<<"$devices"; then
  printf "Connecting 󱍸⠀\n"
else
  printf "Disconnected 󰤮⠀\n"
fi
