#!/bin/bash
# usage: dojob2.sh <C:\script.py>  run in fresh project, wait for one new status line
n0=$(ssh server-win-ts "type C:\clo_jobs\out\status.txt" 2>/dev/null | grep -c .)
./runjob.sh "$1" >/dev/null || { echo NOT EMPTY; exit 1; }
for i in $(seq 1 90); do n=$(ssh server-win-ts "type C:\clo_jobs\out\status.txt" 2>/dev/null | grep -c .); [ "$n" -gt "$n0" ] && break; sleep 10; done
[ "$n" -gt "$n0" ] && ssh server-win-ts "type C:\clo_jobs\out\status.txt" | tail -1 || echo TIMEOUT
./console.sh
