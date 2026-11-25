#!/bin/bash
# usage: run.sh <cmdsfile> <shotname>
SP=${SP:-${TMPDIR:-/tmp}}   # local folder for fetched screenshots
scp -q "$1" server-win-ts:/C:/clo_jobs/gui_cmds.txt
ssh server-win-ts "del C:\clo_jobs\gui.log & schtasks /run /tn GUI" >/dev/null 2>&1
for i in $(seq 1 30); do sleep 2; ssh server-win-ts "type C:\clo_jobs\gui.log" 2>/dev/null | grep -q '^end' && break; done
ssh server-win-ts "type C:\clo_jobs\gui.log"
scp -q server-win-ts:/C:/clo_jobs/$2.png $SP/$2.png && sips -Z 1600 $SP/$2.png >/dev/null
