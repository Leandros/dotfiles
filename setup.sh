#!/bin/bash

command_exists () {
    type "$1" &> /dev/null ;
}

if [ -z ${HOME+x} ]; then
    echo "`HOME` environment variable is not set."
    exit 1
fi

UNAME=$(uname)
if [ "$UNAME" = "Darwin" ] ; then
    if command_exists brew ; then
        brew install astyle
        brew install autoconf
        brew install automake
        brew install binutils
        brew install cdiff
        brew install coreutils
        brew install dateutils
        brew install diffutils
        brew install findutils --with-default-names
        brew install gawk
        brew install gcc
        brew install gdb
        brew install git
        brew install gnu-indent --with-default-names
        brew install gnu-sed --with-default-names
        brew install gnu-tar --with-default-names
        brew install gnu-which --with-default-names
        brew install gnutls
        brew install grep --with-default-names
        brew install gzip
        brew install less
        brew install lynx
        brew install m4
        brew install macvim
        brew install make
        brew install md5sha1sum

        # mutt requires sidebar patch
        brew install mutt
        brew install perl
        brew install pidof
        brew install pkg-config
        brew install python
        brew install ranger
        brew intsall reattach-to-user-namespace
        brew install screen
        brew install the_silver_searcher
        brew install tig
        brew install tmux
        brew install tmux-mem-cpu-load
        brew install tree
        brew install valgrind
        brew install vim --override-system-vi
        brew install unzip
        brew install watch
        brew install wdiff --with-gettext
        brew install weechat
        brew install wget
        brew install zsh

        brew linkapps macvim
    fi
fi

# Install a set of programs:
#   - less
#   - astyle
#   - zsh
#   - js-beautify
#   - tig
#   - git
#   - tmux
#   - vim
#   - the_silver_searcher (a.k.a ag)

# Copy all files over:
cp .astylerc $HOME/
cp .gitconfig $HOME/
cp .jsbeautifyrc $HOME/
cp .jshintrc $HOME/
cp .lesskey $HOME/
cp .tigrc $HOME/
cp .tmux.conf $HOME/
cp -r .vim $HOME/
cp .vimrc $HOME/
cp .ycm_extra_conf.py $HOME/
cp .zshrc $HOME/

