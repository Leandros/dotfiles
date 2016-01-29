# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=1000

# ====================
# Config
# ====================
export HOME=/Users/arvidgerstmann
export EDITOR=vim
export CC=clang
export CXX=clang++
export DEFAULT_USER=arvidgerstmann


# System Specifics: OS X
if [[ "Darwin" == "`uname`" ]]; then
    alias vim='mvim -v'
    bindkey "^[[7~" beginning-of-line
    bindkey "^[[8~" end-of-line

    # LOL! Free C-s
    stty -ixon -ixoff

    # Terminal Colors
    export FLAGS_GETOPT_CMD="$(brew --prefix gnu-getopt)/bin/getopt"
    export GREP_OPTIONS='--color=always'
    export GREP_COLOR='1;35;40'
    source "`brew --prefix`/etc/grc.bashrc"
fi

# System Specifics: Linux
if [[ "Linux" == "`uname`" ]]; then

fi


# ====================
# ZSH
# ====================
zstyle :compinstall filename $HOME'/.zshrc'
autoload -Uz compinit
compinit
fpath=(/usr/local/share/zsh-completions $fpath)


# ====================
# OH-MY-ZSH
# ====================
ZSH=$HOME/.oh-my-zsh
ENABLE_CORRECTION="false"
export UPDATE_ZSH_DAYS=7

# powerlevel9k theme
ZSH_THEME="powerlevel9k/powerlevel9k"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(vi_mode status)
POWERLEVEL9K_TIME_BACKGROUND="blue" # cyan / 013 are also good looking
POWERLEVEL9K_PROMPT_ON_NEWLINE=true

plugins=(git git-flow git-extras repo wd brew sublime osx pod terminalapp colored-man cp colorize history)

# External Scripts
source $ZSH/oh-my-zsh.sh


# ====================
# Functions
# ====================
if [[ "Darwin" == "`uname`" ]]; then
    man-preview () {
        man -t "$@" | open -f -a /Applications/Preview.app
    }
    alias pman='man-preview'
fi

man-pdf () {
    man -t "$@" | pstopdf -i -o "$@.pdf"
}
duf () {
    du -sk "$@" | sort -n | \
        while read size fname
            do for unit in k M G T P E Z Y
                do if [ $size -lt 1024 ]; then
                    echo -e "${size}${unit}\t${fname}"
                    break
                fi
            size=$((size/1024))
            done
        done
}
dirsize () {
    du -shx * .[a-zA-Z0-9_]* 2> /dev/null | \
    egrep '^ *[0-9.]*[MG]' | sort -n > /tmp/list
    egrep '^ *[0-9.]*M' /tmp/list
    egrep '^ *[0-9.]*G' /tmp/list
    rm -rf /tmp/list
}
extract () {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1;;
            *.tar.gz)    tar xzf $1;;
            *.bz2)       bunzip2 $1;;
            *.rar)       rar x $1;;
            *.gz)        gunzip $1;;
            *.tar)       tar xf $1;;
            *.tbz2)      tar xjf $1;;
            *.tgz)       tar xzf $1;;
            *.zip)       unzip $1;;
            *.Z)         uncompress $1;;
            *.7z)        7z x $1;;
            *)           echo "'$1' cannot be extracted via extract()";;
        esac
        else
            echo "'$1' is not a valid file"
    fi
}
netinfo () {
    echo "--------------- Network Information ---------------"
    /sbin/ifconfig | awk /'inet addr/ {print $2}'
    /sbin/ifconfig | awk /'Bcast/ {print $3}'
    /sbin/ifconfig | awk /'inet addr/ {print $4}'
    /sbin/ifconfig | awk /'HWaddr/ {print $4,$5}'
    myip=`lynx -dump -hiddenlinks=ignore -nolist http://checkip.dyndns.org:8245/ | sed '/^$/d; s/^[ ]*//g; s/[ ]*$//g' `
    echo "${myip}"
    echo "---------------------------------------------------"
}
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            man "$@"
}

# ====================
# Programs
# ====================
export LESS="-R"
export LESSOPEN="|~/.lessfilter %s"

# ====================
# General Config
# ====================
# Set Locale. LOL
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# tmux current working dir
PS1="$PS1"'$([ -n "$TMUX"  ] && tmux setenv TMUXPWD_$(tmux display -p "#D" | tr -d %) "$PWD")'

# ====================
# Vi Mode
# ====================

# Enable Vi mode
bindkey -v

# Just if dots appear again
# bindkey "^I" expand-or-complete

# Normal bindings
bindkey -M vicmd "s" forward-char
bindkey -M vicmd "b" backward-char
bindkey -M vicmd "n" down-line-or-beginning-search
bindkey -M vicmd "r" up-line-or-beginning-search
bindkey -M vicmd "B" backward-word
bindkey -M vicmd "S" forward-word
bindkey -M vicmd "$" end-of-line
bindkey -M vicmd "0" beginning-of-line
bindkey -M vicmd "y" yank

# Bind Up and Down keys again
bindkey -M vicmd "OA" up-line-or-beginning-search
bindkey -M vicmd "OB" down-line-or-beginning-search
bindkey -M viins "OA" up-line-or-beginning-search
bindkey -M viins "OB" down-line-or-beginning-search

# Insert mode bindings
bindkey -M viins "" backward-delete-char

export KEYTIMEOUT=1


# ====================
# Aliases
# ====================
alias g=git
alias ti='tig status'
alias tigs='tig status'
alias copy='noeol | pbcopy'
alias fuck='sudo $(history -p \!\!)'
alias lsfiles='for f in *; do [[ -f "$f" ]] && ls -- "$f"; done'
alias lsfilesrec="tree -if --noreport . | sed 's/^\.\///g'"
alias untargz='tar -xzf'
alias untarbz='tar -xjf'
alias targz='tar -czf'
alias tarbz='tar -cjf'

# Android SDK / NDK
export ANDROID_ROOT=$HOME/android-sdk
export ANDROID_HOME=$ANDROID_ROOT
export NDK_ROOT=$HOME/android-ndk-r9b
export NDK_TOOLCHAIN_VERSION=4.9
export NDK_CCACHE=/usr/local/bin/ccache
export USE_CCACHE=1

# PATH
PATH=/usr/local/bin:$PATH
PATH=$PATH:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/core_perl
PATH=$PATH:$HOME/bin
PATH=$PATH:$HOME/bin/awscli/eb/macosx/python2.7
PATH=$PATH:$HOME/bin/drmemory/bin
PATH=$PATH:$HOME/.rvm/bin

PATH=$PATH:$ANDROID_ROOT
PATH=$PATH:$ANDROID_ROOT/tools
PATH=$PATH:$ANDROID_ROOT/platform-tools
PATH=$PATH:$NDK_ROOT
PATH=$PATH:$NDK_CCACHE

# Cross Compiling Toolchains
PATH=$PATH:/usr/local/sh-elf/bin
PATH=$PATH:/usr/local/sh-coff/bin
PATH=$PATH:/usr/local/m68k-elf/bin

export PATH

# Start ssh-agent on startup
eval `ssh-agent -s` > /dev/null 2>&1

