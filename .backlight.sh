#!/bin/bash

input="$1"
bpath="/sys/class/backlight/intel_backlight/brightness"
current=`cat "$bpath"`

if [[ "$input" == +* ]]; then
    inc="${input:1}"
    new=$((current + inc))
    echo "$new" | tee "$bpath"
elif [[ "$input" == -* ]]; then
    inc="${input:1}"
    new=$((current - inc))
    echo "$new" | tee "$bpath"
else
    echo "$input" | tee "$bpath"
fi

