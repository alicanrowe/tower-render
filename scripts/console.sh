#!/bin/bash
# bring the server console (Edge kiosk) to the front
printf "focus the tower console\n" > _k.txt; ./run.sh _k.txt x >/dev/null 2>&1
