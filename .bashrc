#################
## Bash
#################

# History
export HISTFILE=~/.bash_history
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups

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

# Disable stupid old stuff (enables c-s)
stty -ixon

# Aliases
alias pbcoby='/dev/clipboard'
alias pbpaste='cat /dev/clipboard'

# Source perforce (if any process ends up using bash instead of zsh)
if [ -f "$HOME/.p4creds" ]; then
    source "$HOME/.p4creds"
fi

# Functions
function up()
{
    dir=""
    if [ -z "$1" ]; then
        dir=..
    elif [[ $1 =~ ^[0-9]+$ ]]; then
        x=0
        while [ $x -lt ${1:-1} ]; do
            dir=${dir}../
            x=$(($x+1))
        done
    else
        dir=${PWD%/$1/*}/$1
    fi
    cd "$dir";
}

