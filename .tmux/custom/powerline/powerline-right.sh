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

source ~/.passwords
COUNT_PRIVATE=$(curl -u $MAIL_USERNAME_PRIVATE:$MAIL_PASSWORD_PRIVATE --silent "https://mail.google.com/mail/feed/atom" | grep -E -m 1 -o '<fullcount>(.*)</fullcount>' | sed -e 's,.*<fullcount>\([^<]*\)</fullcount>.*,\1,g')
COUNT_APPICO=$(curl -u $MAIL_USERNAME_APPICO:$MAIL_PASSWORD_APPICO --silent "https://mail.google.com/mail/feed/atom" | grep -E -m 1 -o '<fullcount>(.*)</fullcount>' | sed -e 's,.*<fullcount>\([^<]*\)</fullcount>.*,\1,g')
COUNT_VOONY=$(curl -u $MAIL_USERNAME_VOONY:$MAIL_PASSWORD_VOONY --silent "https://mail.google.com/mail/feed/atom" | grep -E -m 1 -o '<fullcount>(.*)</fullcount>' | sed -e 's,.*<fullcount>\([^<]*\)</fullcount>.*,\1,g')

if [ "$COUNT_PRIVATE" -gt 0 -o "$COUNT_APPICO" -gt 0 -o "$COUNT_VOONY" -gt 0 ]; then
    MEM="#[fg=colour148, bg=colour9]#[default]#[fg=colour234, bg=colour148] mem: ${LOAD_MEM} #[default]"
    MAIL="#[fg=colour9, bg=colour235]#[default]#[fg=colour234, bg=colour9] $COUNT_PRIVATE | $COUNT_APPICO | $COUNT_VOONY #[default]"
    echo "${MAIL}${MEM}${CPU}"
else
    MEM="#[fg=colour148, bg=colour235]#[default]#[fg=colour234, bg=colour148] mem: ${LOAD_MEM} #[default]"
    echo "${MEM}${CPU}"
fi

