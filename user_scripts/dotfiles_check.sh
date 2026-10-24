cd ~/.dotfiles || exit 1

echo "== 1. broken links inside the dotfiles"
find . -path ./.git -prune -o -xtype l -print

echo "== 1b. links that point at their own folder or a parent (loops)"
find . -path ./.git -prune -o -type l -print0 | while IFS= read -r -d '' l; do
  t=$(readlink -f "$l")
  case "$(readlink -f "$(dirname "$l")")/" in "$t"/*) echo "  $l" ;; esac
done

echo "== 2. configs/* not linked from ~/.config (or linked to a different place)"
for d in configs/*; do
  n=${d##*/}
  [ "$(readlink -f ~/.config/"$n")" = "$(readlink -f "$d")" ] || echo "  $n"
done

echo "== 3. ~/.config links that point outside the dotfiles"
find ~/.config -maxdepth 1 -type l ! -lname '../.dotfiles/*' -printf '  %f -> %l\n'

echo "== 4. script folders: missing link, real copy, or link to another file"
check() { # source_dir linked_dir
  for f in "$1"/*; do
    n=${f##*/}
    [ "$(readlink -f "$f")" = "$(readlink -f "$2/$n")" ] || echo "  $2/$n"
  done
  for f in "$2"/*; do
    [ -e "$1/${f##*/}" ] || echo "  extra (no source): $f"
  done
}
check hypr_scripts configs/hypr/scripts
check waybar_scripts configs/waybar/scripts
