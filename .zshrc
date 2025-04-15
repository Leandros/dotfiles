# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000000
SAVEHIST=100000
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt AUTO_PUSHD

# This needs to be run earlier than compinit
bindkey -v

# =============================================================================
# Config
# =============================================================================
export HOME=##NEWHOME##
export EDITOR=nvim
export VISUAL=nvim
export CC=gcc
export CXX=g++
export DEFAULT_USER=##NEWUSER##
export LANG="en_us.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export HOMEBREW_NO_AUTO_UPDATE=1
export AWS_DEFAULT_REGION="us-east-1"
export AWS_PAGER=""
# if you wish to use IMDS set AWS_EC2_METADATA_DISABLED=false
export AWS_EC2_METADATA_DISABLED=true
export VIRTUAL_ENV_DISABLE_PROMPT=1
export TERRAFORM_BINARY_NAME=tofu
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export GOPATH="$HOME/gopath"

# Profiling
PROFILE_STARTUP=false
if [[ "$PROFILE_STARTUP" == true ]]; then
    # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
    PS4=$'%D{%M%S%.} %N:%i> '
    exec 3>&2 2>$HOME/tmp/startlog.$$
    setopt xtrace prompt_subst
fi

# =============================================================================
# OS X
# =============================================================================
if [[ "Darwin" == "`uname`" ]]; then
    bindkey "^[[7~" beginning-of-line
    bindkey "^[[8~" end-of-line

    # LOL! Free C-s
    stty -ixon -ixoff

    # Homebrew
    if [[ $(uname -m) == "arm64" ]]; then
	    eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi

    # Mac specificts.
    export BROWSER="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
    export FLAGS_GETOPT_CMD="$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt"
    export GREP_OPTIONS='--color=always'
    export GREP_COLOR='1;35;40'
    export PNPM_HOME="$HOME/Library/pnpm"

# =============================================================================
# Linux
# =============================================================================
elif [[ "Linux" == "`uname`" ]]; then
    alias startx='startx -- -dpi 144'
    if [ -z ${DISPLAY+x} ]; then
        # X is not running
        # TODO: Do we want to detect that tmux is running?
        alias pbpaste='tmux save-buffer -'
        alias pbcopy='tmux load-buffer -w -'
    else
        alias pbpaste='xclip -o'
        alias pbcopy='xclip -i'
    fi

    # LOL! Free C-s
    stty -ixon -ixoff

    n ()
    {
        # Block nesting of nnn in subshells
        if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
            echo "nnn is already running"
            return
        fi

        # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
        # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
        # see. To cd on quit only on ^G, remove the "export" and make sure not to
        # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
        #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
        export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
        export NNN_OPTS="dH"

        # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
        # stty start undef
        # stty stop undef
        # stty lwrap undef
        # stty lnext undef

        nnn "$@"

        if [ -f "$NNN_TMPFILE" ]; then
                . "$NNN_TMPFILE"
                rm -f "$NNN_TMPFILE" > /dev/null
        fi
    }

    # Linux specifics.
    export BROWSER="/usr/bin/google-chrome-stable"
    export PNPM_HOME="$HOME/.local/share/pnpm"

    if [[ "$TERM" == "rxvt-unicode" ]]; then
        export TERM="xterm-256color"
    fi

# =============================================================================
# Cygwin
# =============================================================================
elif [[ "Cygwin" == "`uname -o`" ]]; then
    export TERM="xterm-256color"

    _pbcopy() { read data; echo "$data" > /dev/clipboard }
    _pbpaste() { cat /dev/clipboard }
    alias pbcopy="_pbcopy"
    alias pbpaste="_pbpaste"
fi

# =============================================================================
# ZSH
# =============================================================================
zstyle :compinstall filename $HOME'/.zshrc'
zmodload zsh/complist
zmodload zsh/mathfunc
autoload -Uz compinit && compinit
autoload -U zmv
autoload -U zcalc

zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs ..
zstyle ':completion:*' use-ip true
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' rehash true

# ls(1) like colors
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34:st=37;44:ex=01;32'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

fpath=(/usr/local/share/zsh-completions $fpath)
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fpath=($HOME/.zsh/compl $fpath)

# zmv is awesome
alias zmv='noglob zmv'
alias zcp='noglob zmv -C'
alias zln='noglob zmv -L'
alias zsy='noglob zmv -Ls'
alias mmv='noglob zmv -W'

# =============================================================================
# FZF
export FZF_DEFAULT_COMMAND='fd --strip-cwd-prefix --hidden --follow --exclude .git'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Preview file content using bat (https://github.com/sharkdp/bat)
export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-t:change-preview-window(down|hidden|)'"

export FZF_DEFAULT_OPTS="--bind=ctrl-n:down,ctrl-r:up,ctrl-b:backward-char,ctrl-s:forward-char"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-p:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --bind=ctrl-n:down,ctrl-r:up,ctrl-b:backward-char,ctrl-s:forward-char
  --bind=ctrl-t:toggle-sort
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Init fzf
if [ -x "$(command -v fzf)" ]; then
    source <(fzf --zsh)
else
    # Old way of init.
    [ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
    # Init for debian
    [ -f "/usr/share/doc/fzf/examples/key-bindings.zsh" ] && . "/usr/share/doc/fzf/examples/key-bindings.zsh"
    [ -f "/usr/share/doc/fzf/examples/completion.zsh" ] && . "/usr/share/doc/fzf/examples/completion.zsh"
fi

function f {
    fzf $*
}

# -- GIT CR
# This has to happen before compinit.
if [ -x "$(command -v git-cr)" ]; then
    source <(git-cr generate-shell-compl zsh)
fi

# =============================================================================
# Atuin
# if [ -x "$(command -v atuin)" ]; then
#     eval "$(atuin init zsh)"
# fi

# =============================================================================
# OH-MY-ZSH
# =============================================================================
ZSH=$HOME/.oh-my-zsh
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS=false
export ZSH_THEME=""
export UPDATE_ZSH_DAYS=7

# Autosuggestion config
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243"

# Installation instructions:
# $ git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# $ git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# $ git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting

# Order is important.
plugins=(git git-prompt colored-man-pages zsh-autosuggestions fast-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Man pages config
less_termcap[md]="${fg_bold[blue]}"

function __git_prompt {
    # local ref=$(command git symbolic-ref HEAD 2>/dev/null || command git rev-parse --short HEAD 2>/dev/null)
    # if [ "$ref" != "" ]; then
    #     echo "%{$fg[green]%}[${ref#refs/heads/}]%{$reset_color%}"
    # fi

    ZSH_THEME_GIT_PROMPT_PREFIX="["
    ZSH_THEME_GIT_PROMPT_SUFFIX="]"
    # • ⦁   
    ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg[green]%}"
    ZSH_THEME_GIT_PROMPT_STAGED="%{$fg[red]%}%{%G%}"
    ZSH_THEME_GIT_PROMPT_CONFLICTS="%{$fg[red]%}%{⚠%G%}"
    ZSH_THEME_GIT_PROMPT_CHANGED="%{$fg[blue]%}%{+%G%}"
    ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[blue]%}%{-%G%}"
    ZSH_THEME_GIT_PROMPT_BEHIND="%{↓%G%}"
    ZSH_THEME_GIT_PROMPT_AHEAD="%{↑%G%}"
    ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%}%{⚐%G%}"
    ZSH_THEME_GIT_PROMPT_STASHED="%{$fg_bold[blue]%}%{⚑%G%}"
    ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%}%{✔%G%}"
    ZSH_THEME_GIT_PROMPT_UPSTREAM_SEPARATOR="→"
    git_super_status
}

function __pyvenv_prompt {
    if [ -x "$VIRTUAL_ENV" ]; then
        venv_name=$(basename "$VIRTUAL_ENV")
        echo " 🐍(${venv_name})"
    fi
}

if [ "$EUID" = "0" ]; then
    promptchar="%{$fg[red]%}#%{$reset_color%}"
elif [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
    promptchar="%{$fg[magenta]%}%%%%%{$reset_color%}"
else
    promptchar="%{$fg[magenta]%}%%%{$reset_color%}"
fi

export PS1=$'
%{$fg[blue]%}%~%{$reset_color%} $(__git_prompt)$(__pyvenv_prompt)
$promptchar '
export PS2="%{$fg_blod[black]%}%_> %{$reset_color%}"

# This disables the prompt on the right.
unset RPROMPT

# Uncomment this, and the lines below using it to re-enable the RPROMPT.
# export _RPS1="%(?.%{$fg[green]%}✓%{$reset_color%}.%{$fg[red]%}✗ %?%{$reset_color%})"

function zle-line-init {
    # local insert="%{$fg[blue]%}INSERT%{$reset_color%}"
    # RPS1="${${KEYMAP/vicmd/NORMAL}/(main|viins)/$insert} $_RPS1"
    # zle reset-prompt

    # Use beam shape cursor.
    # https://vt100.net/docs/vt510-rm/DECSCUSR
    echo -ne "\e[6 q"
}
zle -N zle-line-init

function zle-keymap-select {
    # local insert="%{$fg[blue]%}INSERT%{$reset_color%}"
    # RPS1="${${KEYMAP/vicmd/NORMAL}/(main|viins)/$insert} $_RPS1"
    # zle reset-prompt

    case $KEYMAP in
        vicmd) echo -ne '\e[2 q';; # block
        viins|main) echo -ne '\e[6 q';; # beam
    esac
}
zle -N zle-keymap-select

echo -ne '\e[6 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[6 q' ;} # Use beam shape cursor for each new prompt.

# =============================================================================
# General Config
# =============================================================================
# Make use of the dirstack
DIRSTACKSIZE=9
DIRSTACKFILE=~/.zdirs
if [[ -f $DIRSTACKFILE ]] && [[ $#dirstack -eq 0 ]]; then
  dirstack=( ${(f)"$(< $DIRSTACKFILE)"} )
  [[ -d $dirstack[1] ]] && cd $dirstack[1] && cd $OLDPWD
fi
chpwd() {
  print -l $PWD ${(u)dirstack} >$DIRSTACKFILE
}

# =============================================================================
# Vi Mode
# =============================================================================
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
bindkey -M vicmd "w" vi-forward-word-end
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

# Bindings for zsh-autosuggestions
bindkey -M viins "" autosuggest-accept

# Search on steroids.
# Replaced by fzf
# bindkey "^R" history-incremental-pattern-search-backward
# bindkey "^S" history-incremental-pattern-search-forward

# Bind Up and Down keys again
bindkey -M vicmd "OA" up-line-or-beginning-search
bindkey -M vicmd "OB" down-line-or-beginning-search
bindkey -M viins "OA" up-line-or-beginning-search
bindkey -M viins "OB" down-line-or-beginning-search

# Move physical line up and down
_physical_up_line()   { zle backward-char -n $COLUMNS }
_physical_down_line() { zle forward-char  -n $COLUMNS }
zle -N physical-up-line _physical_up_line
zle -N physical-down-line _physical_down_line
bindkey -M vicmd "R" physical-up-line
bindkey -M vicmd "N" physical-down-line

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

autoload -Uz narrow-to-region
function _history-incremental-preserving-pattern-search-backward {
    local state
    MARK=CURSOR  # magick, else multiple ^R don't work
    narrow-to-region -p "$LBUFFER${BUFFER:+>>}" -P "${BUFFER:+<<}$RBUFFER" -S state
    zle end-of-history
    zle history-incremental-pattern-search-backward
    narrow-to-region -R state
}
zle -N _history-incremental-preserving-pattern-search-backward

# Only overwrite ^R when `fzf` doesn't exist
if [ -z "$(command -v fzf)" ]; then
    bindkey -M viins "" _history-incremental-preserving-pattern-search-backward
    bindkey -M vicmd "" _history-incremental-preserving-pattern-search-backward
    bindkey -M isearch "" history-incremental-pattern-search-backward
fi

export KEYTIMEOUT=1

# This will put (n)vim in the background and revive it back.
# It's triggered with ^Z.
foreground-vim() {
    fg %nvim 2>/dev/null >/dev/null || fg %vim 2>/dev/null >/dev/null
}
zle -N foreground-vim
bindkey '^Z' foreground-vim


# =============================================================================
# Aliases
# =============================================================================
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
alias m='mutt -F ~/.mutt/muttrc1'
alias m1='mutt -F ~/.mutt/muttrc1'
alias m2='mutt -F ~/.mutt/muttrc2'
alias m3='mutt -F ~/.mutt/muttrc3'
alias gb1='goobook -c ~/.mutt/goobook/goobookrc_private'
alias gb2='goobook -c ~/.mutt/goobook/goobookrc_appico'
alias gb3='goobook -c ~/.mutt/goobook/goobookrc_arvidio'
alias ccp='rsync -ah --progress'
alias ytdl="youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'"
alias vim='nvim'
alias tf='tofu'
alias p='pnpm'
alias pnx="pnpm nx"

# Less modes
export LESS="-R"
export LESSOPEN="|~/.lessfilter %s"

# Ignore these commands in history
alias cd=' cd'

# Amazon
if [ -d "$HOME/.brazil_completion" ]; then
    alias bb='brazil-build'
    alias b='brazil'
    alias bws='brazil ws'
    alias bre='brazil-runtime-exec'
    alias brc='brazil-recursive-cmd'
    alias bbr='brc brazil-build'
    alias bball='brc --allPackages'
    alias bbb='brc --allPackages brazil-build'

    brazil() {
        unfunction "$0"
        source "$HOME/.brazil_completion/zsh_completion"
        $0 "$@"
    }

    if [ -d "$HOME/.toolbox" ]; then
        alias tb='toolbox'
    fi
fi

# ls replacements.
if [ -x "$(command -v eza)" ]; then
    alias ls=' eza'
    alias l=' eza -lah'
elif [[ "Linux" == "`uname`" ]]; then
    alias ls=' ls'
    alias l=' ls -lah'
else
    alias ls=' ls --color=auto'
    alias l=' ls -lah'
fi

# Highlight current day
cal() {
    /usr/bin/cal $* | grep --color -EC6 "\b$(date +%e | sed "s/ //g")\b"
}

# Easyily convert between hex and decimal
h2d() { echo "ibase=16; $@" | bc }
d2h() { echo "obase=16; $@" | bc }

# Objdump shortcut
function dump {
    if [ -x "$(command -v gobjdump)" ]; then
        command gobjdump -Mintel -S $@
    else
        command objdump -Mintel -S $@
    fi
}

# Mutt command
mutt() {
    local cwd=$(pwd)
    cd ~/
    command mutt $@
    cd $cwd
}

# GN with python3
if [[ "$OSTYPE" =~ darwin* ]]; then
    gn() {
        command gn $@ --script-executable=python3
    }
fi

# up x -- move up x levels
up() {
  local op=print
  [[ -t 1 ]] && op=cd
  case "$1" in
    '') up 1;;
    -*|+*) $op ~$1;;
    <->) $op $(printf '../%.0s' {1..$1});;
    *) local -a seg; seg=(${(s:/:)PWD%/*})
       local n=${(j:/:)seg[1,(I)$1*]}
       if [[ -n $n ]]; then
         $op /$n
       else
         print -u2 up: could not find prefix $1 in $PWD
         return 1
       fi
  esac
}

# Short of learning how to actually configure OSX, here's a hacky way to use
# GNU manpages for programs that are GNU ones, and fallback to OSX manpages
# otherwise oh, and colorized
alias gnuman='_() { echo $1; man -M $(brew --prefix)/opt/coreutils/libexec/gnuman $1 1>/dev/null 2>&1;  if [ "$?" -eq 0  ]; then man -M $(brew --prefix)/opt/coreutils/libexec/gnuman $1; else man $1; fi  }; _'

# Convert man page to pdf
man-pdf () {
    man -t "$@" | pstopdf -i -o "$@.pdf"
}

countdown() {
    local target=$(($(date +%s) + $1))
    while [ "$target" -ge `date +%s` ]; do
        echo -ne "$(date -u --date @$(($target - `date +%s`)) +%H:%M:%S)\r"
        sleep 0.1
    done
    echo -e "Countdown Over!"
}

stopwatch() {
  date1=`date +%s`;
   while true; do
    echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r";
    sleep 0.1
   done
}

install-rust-analyzer() {
    local archive_name
    if [[ "Darwin" == "`uname`" ]]; then
        if [[ $(uname -m) == "arm64" ]]; then
            archive_name="rust-analyzer-aarch64-apple-darwin.gz"
        else
            archive_name="rust-analyzer-x86_64-apple-darwin.gz"
        fi
    elif [[ "Linux" == "`uname`" ]]; then
        archive_name="rust-analyzer-x86_64-unknown-linux-gnu.gz"
    fi

    curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/$archive_name | \
        gunzip -c - > ~/bin/rust-analyzer
    chmod +x ~/bin/rust-analyzer
}

# extract any format
extract () {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1;;
            *.tar.gz)    tar xzf $1;;
            *.tar.xz)    tar xJf $1;;
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

# =============================================================================
# SDKs
# =============================================================================
export PICO_SDK_PATH=$HOME/pico-sdk

# =============================================================================
# PATH
# =============================================================================
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PATH="$PNPM_HOME:$PATH"
PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
# PATH="$HOMEBREW_PREFIX/opt/binutils/bin:$PATH"
# PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
PATH="$HOMEBREW_PREFIX/opt/make/libexec/gnubin:$PATH"
PATH="$HOMEBREW_PREFIX/opt/gnu-getopt/bin:$PATH"
PATH="$HOMEBREW_PREFIX/opt/openjdk@11/bin:$PATH"
PATH="$HOMEBREW_PREFIX/opt/mysql@5.7/bin:$PATH"

# Core paths.
PATH="$PATH:/usr/bin/core_perl"
PATH="$PATH:$HOME/bin"
PATH="$PATH:$HOME/.zsh/bin"
PATH="$PATH:$HOME/.fzf/bin"
PATH="$PATH:$HOME/.cargo/bin"
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:$HOME/.rvm/bin"
PATH="$PATH:$HOME/.fastlane/bin"
PATH="$PATH:$HOME/gopath/bin"
PATH="$PATH:/usr/local/go/bin"
PATH="$PATH:/usr/local/share/dotnet"
PATH="$PATH:$HOME/flutter/bin"
if [ -x "$(command -v python3)" ]; then
    PATH="$PATH:$(python3 -m site --user-base)/bin"
fi
if [ -d "/Applications/Postgres.app/Contents/Versions/latest/bin" ]; then
    PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin"
fi

# macOS specific
PATH="$PATH:/Applications/p4merge.app/Contents/MacOS"

# Cross Compiling Toolchains
PATH="$PATH:/usr/local/sh-elf/bin"
PATH="$PATH:/usr/local/sh-coff/bin"
PATH="$PATH:/usr/local/m68k-elf/bin"
PATH="$PATH:/Applications/microchip/xc8/v2.46/bin"

# Amazon
if [ -d "$HOME/.brazil_completion" ]; then
    PATH="$PATH:$HOME/.toolbox/bin"
fi

export PATH

# Start ssh-agent on startup
# eval `ssh-agent -s` > /dev/null 2>&1

# ━━ Homebrew ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -v security > /dev/null \
    && export HOMEBREW_GITHUB_API_TOKEN=$(security find-generic-password -a 'homebrew-token' -l 'github.com' -w)

# ━━ Lazygit ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
lg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}


# ━━ Zoxide ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# zoxide (must appear after `compinit`)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ━━ Pyenv ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PATH:$PYENV_ROOT/bin"
if [ -x "$(command -v pyenv)" ]; then
    eval "$(pyenv init -)"
fi

# ━━ MANPATH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export MANPATH=$HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman:$MANPATH
function mman { MANPATH=$HOME/p4/depot/liba/docs man $* | less }

# ━━ fnm ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -d "$HOME/.local/share/fnm" ]; then
    export PATH="$HOME/.local/share/fnm:$PATH"
else
    export PATH="$HOME/.fnm:$PATH"
fi

command -v fnm >/dev/null && eval "`fnm env`"

# ━━ External ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -f "$HOME/.p4creds" ]; then
    source "$HOME/.p4creds"
fi
if [ -f "$HOME/.env.accounts" ]; then
    source "$HOME/.env.accounts"
fi

# ━━ RVM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# ━━ Nix ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    export NIX_PROFILES="/nix/var/nix/profiles/default $HOME/.nix-profile"
    export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
fi

# ━━ Direnv ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ━━ Broot ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[[ -s "$HOME/.config/broot/launcher/bash/br" ]] && . "$HOME/.config/broot/launcher/bash/br"

# esp32
if [ -f "$HOME/export-esp.sh" ]; then
    . "$HOME/export-esp.sh"
fi

# ━━ ghcup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env

# ━━ chruby ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -f "/usr/local/share/chruby/chruby.sh" ]; then
    . /usr/local/share/chruby/chruby.sh
    . /usr/local/share/chruby/auto.sh
    chruby ruby-3.3.0
fi

# ━━ MISE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate zsh)"
    if [ -f "$HOME/.local/share/mise/completions.zsh" ]; then
        . $HOME/.local/share/mise/completions.zsh
    fi
fi

# ━━ Terraform completion ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -v terraform >/dev/null 2>&1; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C $(command -v terraform) terraform
fi


# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ KEEP AT BOTTOM!                                          ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
# Entirety of my startup file... then
if [[ "$PROFILE_STARTUP" == true ]]; then
    unsetopt xtrace
    exec 2>&3 3>&-
fi
