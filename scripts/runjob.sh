#!/bin/bash
# usage: runjob.sh <C:\path\script.py>   new project, empty check, paste, run, minimise editor
E=524998; M=263482
printf "show $E\nsleep 300\nmax $M\nsleep 600\nclick 70,32\nsleep 900\nclick 96,60\nsleep 2500\nwindows\n" > _c.txt
W=$(./run.sh _c.txt x 2>/dev/null | grep 'CLO Standalone' | grep -v "^$E|\|^$M|")
if [ -n "$W" ]; then
  H=$(echo "$W" | head -1 | cut -d'|' -f1)
  printf "raise $H\nsleep 500\nclick 964,601\nsleep 2500\n" > _c.txt; ./run.sh _c.txt x >/dev/null 2>&1
fi
ssh server-win-ts "del C:\clo_jobs\chk.txt" 2>/dev/null
printf "show $E\nsleep 400\nclick 840,360\nsleep 300\nkeys ^a\nsleep 200\npaste C:\\\\clo_jobs\\\\chk.py\nsleep 500\nclick 288,148\nsleep 3000\n" > _c.txt; ./run.sh _c.txt x >/dev/null 2>&1
n=$(ssh server-win-ts "type C:\clo_jobs\chk.txt"); echo "patterns before run: $n"
[ "$n" = "0" ] || { echo "SCENE NOT EMPTY"; exit 1; }
printf "show $E\nsleep 400\nclick 840,360\nsleep 300\nkeys ^a\nsleep 200\npaste %s\nsleep 800\nclick 288,148\nsleep 1500\nmin $E\n" "$1" > _c.txt; ./run.sh _c.txt x >/dev/null 2>&1
echo started
