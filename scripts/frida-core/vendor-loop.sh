#!/bin/bash
cd ~/frida-build
for i in $(seq 1 40); do
  out=$(TAILN=100 ./configure.sh 2>&1)
  dep=$(grep -oE 'fallback subproject for the dependency [A-Za-z0-9_.+-]+' <<<"$out" | tail -1 | awk '{print $NF}')
  sub=$(grep -oE 'Subproject [A-Za-z0-9_.+-]+ is buildable: NO' <<<"$out" | tail -1 | awk '{print $2}')
  w=""
  if grep -qE 'is buildable: NO|downloading is disabled|has no meson.build' <<<"$out"; then
    [ -n "$sub" ] && w=$(find fc/subprojects -name "$sub.wrap" -not -path '*/packagefiles/*' | xargs grep -L wrap-redirect | head -1)
    [ -z "$w" ] && [ -n "$dep" ] && w=$(grep -lE "dependency_names *=.*(^|[ ,=])$dep(,|\$| )" $(find fc/subprojects -name '*.wrap' -not -path '*/packagefiles/*' | xargs grep -L wrap-redirect) 2>/dev/null | head -1)
  fi
  if [ -n "$w" ]; then
    d=$(dirname "${w#fc/}"); n=$(basename "$w" .wrap)
    echo "need ${sub:-$dep} -> $d/$n"
    (cd fc && ../fetchwrap.sh "$d" "$n") || break
  else
    break
  fi
done
echo "$out" | tail -14 | cut -c1-200
