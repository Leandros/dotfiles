#################
## Bash
#################

# History
shopt -u histappend
export HISTFILE=~/.bash_history
export HISTSIZE=
export HISTFILESIZE=
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T: "

# Persistent history.
# Will be run in PROMPT_COMMAND
log_bash_persistent_history()
{
  [[
    $(history 1) =~ ^\ *[0-9]+\ +([^\ ]+\ [^\ ]+)\ +(.*)$
  ]]
  local date_part="${BASH_REMATCH[1]}"
  local command_part="${BASH_REMATCH[2]}"
  if [ "$command_part" != "$PERSISTENT_HISTORY_LAST" ]
  then
    echo $date_part "|" "$command_part" >> ~/.persistent_history
    export PERSISTENT_HISTORY_LAST="$command_part"
  fi
}

# Defaults
export EDITOR=nvim
# export TERM=xterm-256color

# Detect Windows
if [[ "$OS" =~ Windows* ]]; then
    export IS_WINDOWS=1
fi

# General settings (i don't know if this is bash or readline specific)
set bell-style none
set show-all-if-ambiguous on
set completion-ignore-case on
set menu-complete-display-prefix on

# Enable advanced globbing
shopt -s globstar

# Disable stupid old stuff (enables c-s)
stty -ixon -ixoff

# Set Locale. LOL
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Path
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/.cargo/bin

if [[ "$IS_WINDOWS" = "1" ]]; then
    export PATH=$PATH:/c/Python310/Scripts
    export PATH=$PATH:/c/Perforce
fi

# XDG
if [ "$IS_WINDOWS" = "1" ]; then
    export XDG_CONFIG_HOME=$APPDATA
    export XDG_CACHE_HOME=$LOCALAPPDATA/Temp
    export XDG_DATA_HOME=$LOCALAPPDATA
    export XDG_STATE_HOME=$LOCALAPPDATA
fi

# Less config
export LESS="-R"
export LESSOPEN="|~/.lessfilter %s"

# Aliases
nvim-qt() { NVIM_GUI=1 command nvim-qt "$@"; }
alias ti='tig status'
alias vim='nvim'
alias vimdiff='nvim -d'
alias tf='terraform'
alias pkc='packer'
if [ "$IS_WINDOWS" = "1" ]; then
    alias http='winpty http'
    pbcopy() { read data; echo "$data" > /dev/clipboard; }
    pbpaste() { cat /dev/clipboard; }
fi

lg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

# Source perforce (if any process ends up using bash instead of zsh)
if [ -f "$HOME/.p4creds" ]; then
    source "$HOME/.p4creds"
fi

# Use fnm, if it exists
if command -v fnm &> /dev/null; then
    # export PATH=$HOME/.fnm:$PATH
    eval "`fnm env`"
fi

# Use zoxide if installed.
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
fi

# Prompt
function __bash_prompt {
    local exitcode=$?
    local NONE="\[\033[0m\]"        # Reset Prompt
    local R="\[\033[0;31m\]"        # Red
    local G="\[\033[0;32m\]"        # Green
    local B="\[\033[0;34m\]"        # Blue
    local Y="\[\033[0;33m\]"        # Yellow
    local C="\[\033[0;36m\]"        # Cyan
    PS1="${G}\n\u@\h ${Y}\w${C}`__git_ps1`${NONE}\n$ "

    log_bash_persistent_history
}
PROMPT_COMMAND=__bash_prompt

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

