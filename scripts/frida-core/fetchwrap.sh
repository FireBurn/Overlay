#!/bin/bash
# fetchwrap.sh <subprojects-dir> <name>: unpack the wrap's pinned commit into <dir>/<dirname>
d=$1; n=$2; w=$d/$n.wrap
u=$(sed -n 's/^url *= *//p' "$w" | sed 's/\.git$//'); r=$(sed -n 's/^revision *= *//p' "$w")
dir=$(sed -n 's/^directory *= *//p' "$w"); dir=${dir:-$n}
case $u in
  *gitlab*) url="$u/-/archive/$r/x.tar.gz" ;;
  *)        url="$u/archive/$r.tar.gz" ;;
esac
rm -rf "$d/$dir"; mkdir -p "$d/$dir"
curl -fsSL "$url" | tar xz -C "$d/$dir" --strip-components=1 && echo "fetched $n $r -> $d/$dir"
