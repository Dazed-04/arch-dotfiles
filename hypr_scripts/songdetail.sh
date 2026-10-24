#!/bin/bash
case "$1" in
--title) mpc current -f '%title%' ;;
--artist) mpc current -f '%artist%' ;;
--status)
  case $(mpc status | awk 'NR==2 {print $1}') in
  "[playing]") echo " [Playing]" ;;
  "[paused]") echo " [Paused]" ;;
  esac
  ;;
--line)
  title=$(mpc current -f '%title%' 2>/dev/null)
  artist=$(mpc current -f '%artist%' 2>/dev/null)
  echo "${title}${artist:+ - $artist} $($0 --status)"
  ;;
esac
