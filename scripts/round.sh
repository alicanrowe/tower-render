#!/bin/bash
# usage: round.sh <tag e.g. r3>  run queue loop, fetch outputs, white turntables, zip
TAG=$1; X=${XFER:-$HOME/xfer}; G=$X/gui; O=$X/clo/${TAG}_out; S=$X/clo/send_${TAG}   # XFER = transfer folder on the external SSD
cd "$G"
for k in $(seq 1 22); do l=$(./dojob2.sh 'C:\clo_jobs\build_all.py'); echo "$l"; echo "$l" | grep -q "QUEUE EMPTY\|NOT EMPTY" && break; done
mkdir -p "$O" "$S"
for j in $(ssh server-win-ts "type C:\clo_jobs\queue.txt" | tr -d '\r' | grep -v '^#' | grep .); do scp -q -r server-win-ts:/C:/clo_jobs/out/$j "$O"/; rm -f "${O:?}"/"${j:?}"/*.zprj; done
cd "$O"
python3 - <<PY
from PIL import Image;import glob,os
for f in glob.glob('*/*_turn_output*.png'):
    if f.endswith('_white.png'): continue
    im=Image.open(f).convert('RGBA');bg=Image.new('RGBA',im.size,(255,255,255,255));bg.alpha_composite(im)
    bg.convert('RGB').save(f.replace('.png','_white.png'))
PY
for d in */; do j=${d%/}; zip -q -r "$S/p3out_${j}.zip" "$j"; done
echo PIPELINE DONE
