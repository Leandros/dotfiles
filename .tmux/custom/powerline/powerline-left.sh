#!/bin/bash

# Symbols:
# ""
# ""
# ""
# ""

SESSION_IN=`tmux display-message -p '#S:#I.#P'`
SESSION_OUT="#[fg=colour234, bg=colour148] ${SESSION_IN} #[default]#[fg=colour148, bg=colour33]#[default]"

HOSTNAME_IN=`hostname`
HOSTNAME_OUT="#[fg=colour0, bg=colour33] ${HOSTNAME_IN} #[default]#[fg=colour33, bg=colour235]#[default]"

echo "${SESSION_OUT}${HOSTNAME_OUT}"
