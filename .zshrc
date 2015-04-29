# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=1000
bindkey -v

zstyle :compinstall filename $HOME'/.zshrc'

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="blinks"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Change this value to set how frequently ZSH updates¬
export UPDATE_ZSH_DAYS=7

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(git git-flow git-extras repo wd brew sublime osx pod terminalapp colored-man cp colorize history)

source $ZSH/oh-my-zsh.sh
source $ZSH/custom/git-flow-completion.zsh

# Aliases
alias git=hub
alias g=git
alias copy="noeol | pbcopy"
alias fuck='sudo $(history -p \!\!)'
alias lsfiles='for f in *; do [[ -f "$f" ]] && ls -- "$f"; done'
alias lsfilesrec="tree -if --noreport . | sed 's/^\.\///g'"

# Default Editor
export EDITOR=mvim

# Home
export HOME=/Users/arvidgerstmann
export ANDROID_HOME=$HOME/android-sdk
export NDK_HOME=$HOME/android-ndk-r10d

# Terminal Colors
export FLAGS_GETOPT_CMD="$(brew --prefix gnu-getopt)/bin/getopt"
export GREP_OPTIONS='--color=always'
export GREP_COLOR='1;35;40'
source "`brew --prefix`/etc/grc.bashrc"

# Bind Pos1 and Ende
bindkey "^[[7~" beginning-of-line
bindkey "^[[8~" end-of-line

# Set Locale. LOL
export LC_ALL="en_US.UTF-8"

# Completions
autoload -Uz compinit
compinit
fpath=(/usr/local/share/zsh-completions $fpath)

# Add environment variable COCOS_CONSOLE_ROOT for cocos2d-x
export ANDROID_SDK_ROOT=$ANDROID_HOME
export NDK_ROOT=$NDK_HOME
export ANT_ROOT=/usr/local/Cellar/ant/1.9.4/libexec/bin
export COCOS_X_ROOT=$HOME/cocos2d-x-3.4
export COCOS_CONSOLE_ROOT=$COCOS_X_ROOT/tools/cocos2d-console/bin
export COCOS_TEMPLATES_ROOT=$COCOS_X_ROOT/templates

NDK_MODULE_PATH=$HOME/cocos2d-x-3.4
NDK_MODULE_PATH=$NDK_MODULE_PATH:$HOME/cocos2d-x-3.4/cocos
NDK_MODULE_PATH=$NDK_MODULE_PATH:$HOME/cocos2d-x-3.4/external
NDK_MODULE_PATH=$NDK_MODULE_PATH:$HOME/cocos2d-x-3.4/extensions
export NDK_MODULE_PATH

export NDK_TOOLCHAIN_VERSION=4.9
export USE_CCACHE=1
export NDK_CCACHE=/usr/local/bin/ccache

# PATH
PATH=/usr/local/bin:$PATH
PATH=$PATH:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/core_perl
PATH=$PATH:$ANDROID_HOME/tools
PATH=$PATH:$ANDROID_HOME/platform-tools
PATH=$PATH:$ANDROID_HOME/build-tools/android-4.4W
PATH=$PATH:$HOME/bin
PATH=$PATH:$HOME/bin/awscli/eb/macosx/python2.7
PATH=$PATH:$HOME/bin/drmemory/bin
PATH=$PATH:/usr/local/opt/ruby/bin
PATH=$PATH:$HOME/.rvm/bin
PATH=$PATH:$HOME/pebble-dev/PebbleSDK-current/bin

PATH=$PATH:$ANDROID_SDK_ROOT
PATH=$PATH:$NDK_ROOT
PATH=$PATH:$NDK_CCACHE
PATH=$PATH:$ANT_ROOT

PATH=$PATH:$COCOS_CONSOLE_ROOT
PATH=$PATH:$COCOS_TEMPLATES_ROOT
export PATH

# Start ssh-agent on startup
eval `ssh-agent -s` > /dev/null 2>&1

