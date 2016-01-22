#!/bin/bash

# Symbols:
# ""
# ""
# ""
# ""

DATE=`date +"%a %d.%m.%Y  %H:%M"`
LOAD_CPU=`tmux-mem-cpu-load | grep -Eo "([0-9])+\.([0-9])+%"`
CPU="#[fg=colour234, bg=colour148]#[default]#[fg=colour234, bg=colour148] cpu: ${LOAD_CPU} #[default]"

LOAD_MEM_USE=`tmux-mem-cpu-load | grep -Eo "([0-9])+" | head -n 1`
LOAD_MEM_ALL=`tmux-mem-cpu-load | grep -Eo "([0-9])+" | head -n 2 | tail -n 1`
LOAD_MEM=$(printf "%.2f%%" `echo "(${LOAD_MEM_USE}/${LOAD_MEM_ALL}) * 100" | bc -l`)
MEM="#[fg=colour148, bg=colour234]#[default]#[fg=colour234, bg=colour148] mem: ${LOAD_MEM} #[default]"

echo "${MEM}${CPU}"
