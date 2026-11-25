#!/bin/bash
# usage: recover.sh [reason]  CLO hung or stuck: mark the running job FAILED, kill CLO, relaunch,
# dismiss Autosave Recovery (No), reopen Python Editor, write the new E/M handles into runjob.sh.
G=${XFER:-$HOME/xfer}/gui; cd "$G"
R=${1:-hung}
# running job = first queue entry whose out dir has neither DONE nor FAILED
J=$(ssh server-win-ts "for /f %j in (C:\clo_jobs\queue.txt) do @if not exist C:\clo_jobs\out\%j\DONE if not exist C:\clo_jobs\out\%j\FAILED echo %j" | tr -d '\r' | head -1)
ssh server-win-ts "powershell -ExecutionPolicy Bypass -File C:\clo_jobs\kg.ps1" >/dev/null 2>&1
ssh server-win-ts "taskkill /f /fi \"IMAGENAME eq CLO_Standalone*\"" >/dev/null 2>&1; sleep 15
if [ -n "$J" ]; then
  ssh server-win-ts "if not exist C:\clo_jobs\out\\$J mkdir C:\clo_jobs\out\\$J & echo $R, CLO killed and relaunched by recover.sh > C:\clo_jobs\out\\$J\FAILED & echo %date% %time% $J FAILED $R>> C:\clo_jobs\out\status.txt"
fi
ssh server-win-ts "schtasks /run /tn \"Open CLO\"" >/dev/null; sleep 50
# Autosave Recovery appears after every kill: No sits at (1028,600). Harmless click if absent.
printf 'click 1028,600\nsleep 3000\nclick 961,600\nsleep 2000\nwindows\n' > _r.txt
M=$(./run.sh _r.txt x 2>/dev/null | grep 'CLO Standalone' | grep '|0,0,' | head -1 | cut -d'|' -f1)
printf "max $M\nsleep 1500\nclick 110,32\nsleep 1200\nclick 132,240\nsleep 6000\nwindows\n" > _r.txt
E=$(./run.sh _r.txt x 2>/dev/null | grep 'CLO Standalone' | grep -v "^$M|" | head -1 | cut -d'|' -f1)
[ -z "$E" ] || [ -z "$M" ] && { echo "RECOVER FAILED E=$E M=$M"; exit 1; }
printf "front $E\nsleep 1000\n" > _r.txt; ./run.sh _r.txt x >/dev/null 2>&1
sed -i '' "s/^E=[0-9]*; M=[0-9]*/E=$E; M=$M/" runjob.sh
echo "RECOVERED job=$J E=$E M=$M"; ./console.sh >/dev/null 2>&1
