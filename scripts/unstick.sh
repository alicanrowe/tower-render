#!/bin/bash
# while round pipeline runs: if CLO CPU flat for 60 s, click the modal OK (961,600) a few times
while pgrep -f "round.sh" >/dev/null; do
  a=$(ssh server-win-ts "powershell -c \"[int](Get-Process CLO*).CPU\"" 2>/dev/null | tr -d '\r'); sleep 60
  b=$(ssh server-win-ts "powershell -c \"[int](Get-Process CLO*).CPU\"" 2>/dev/null | tr -d '\r')
  if [ -n "$a" ] && [ -n "$b" ] && [ $((b-a)) -lt 3 ]; then
    if ! pgrep -f "runjob.sh" >/dev/null; then
      ( for i in 1 2 3 4 5 6; do echo 'click 961,600'; echo 'sleep 800'; echo 'click 1028,600'; echo 'sleep 800'; done ) > _u.txt; ./run.sh _u.txt x >/dev/null 2>&1; echo "$(date +%T) clicked (cpu $a->$b)"
    fi
  fi
done
