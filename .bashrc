#################
## Bash
#################

# History
HISTFILE=~/.bash_history
HISTSIZE=100000
HISTFILESIZE=100000

# Defaults
export EDITOR=vim

# General settings (i don't know if this is bash or readline specific)
set bell-style none
set show-all-if-ambiguous on
set completion-ignore-case on
set menu-complete-display-prefix on

# Set Locale. LOL
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Less config
export LESS="-R"
export LESSOPEN="|~/.lessfilter %s"

# Disable stupid old stuff
stty -ixon

# Source perforce (if any process ends up using bash instead of zsh)
if [ -f "$HOME/.p4creds" ]; then
    source "$HOME/.p4creds"
fi

