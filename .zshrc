# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=1000

# ====================
# Config
# ====================
export HOME=/Users/leandros
export EDITOR=vim
export CC=clang
export CXX=clang++
export DEFAULT_USER=leandros
export BROWSER=/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome


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

source $ZSH/oh-my-zsh.sh

# ====================
# External Scripts
# ====================
source $ZSH/oh-my-zsh.sh

# Glob all other scripts
for file in $HOME/.zsh/scripts/* ; do
  if [ -f "$file" ] ; then
    source "$file"
  fi
done


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
bindkey -M vicmd "u" undo
bindkey -M vicmd "j" redo
bindkey -M vicmd "gg" beginning-of-buffer-or-history
bindkey -M vicmd "G" end-of-buffer-or-history
bindkey -M vicmd "v" visual-mode
bindkey -M vicmd "f" edit-command-line
bindkey -M vicmd "?" vi-repeat-search
bindkey -M vicmd ":" vi-rev-repeat-search # was execute-named-cmd
#bindkey -M vicmd "y" yank
#bindkey -M vicmd " " magic-space

# Bind Up and Down keys again
bindkey -M vicmd "OA" up-line-or-beginning-search
bindkey -M vicmd "OB" down-line-or-beginning-search
bindkey -M viins "OA" up-line-or-beginning-search
bindkey -M viins "OB" down-line-or-beginning-search

# Insert mode bindings
bindkey -M viins "" backward-delete-char

# Copy & Paste
x-copy() {
    zle copy-region-as-kill
    print -rn -- $CUTBUFFER | pbcopy
    zle visual-mode
}
zle -N x-copy

x-cut() {
    zle kill-region
    print -rn -- $CUTBUFFER | pbcopy
}
zle -N x-cut

x-paste() {
    PASTE=$(pbpaste)
    LBUFFER="$LBUFFER${RBUFFER:0:1}"
    RBUFFER="$PASTE${RBUFFER:1:${#RBUFFER}}"
}
zle -N x-paste

bindkey -M vicmd "y" x-copy
bindkey -M vicmd "Y" x-cut
bindkey -M vicmd "p" x-paste

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
PATH=$PATH:$HOME/.zsh/bin
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

