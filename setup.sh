#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

command_exists () {
    type "$1" &> /dev/null ;
}

update_or_install() {
    local installed
    installed=$(brew ls --versions "$1" | wc -l)
    if [[ "$installed" -gt 0 ]] ; then
        brew upgrade "$1"
    else
        brew install "$@"
    fi
}

mv_if_exists() {
    if [ -f "$1" ]; then
        mv "$1" "$2"
    fi
}

# Poor mans input parsing.
SKIPINSTALL=0
if [[ "$1" == "--skip-install" ]]; then
    SKIPINSTALL=1
fi

SKIPCOPY=0
if [[ "$1" == "--skip-copy" ]]; then
    SKIPCOPY=1
fi

if [[ "$SKIPCOPY" -eq 0 ]]; then
    echo -e "Enter username:"
    read -r NEWUSER

    echo -e "\nEnter home directory:"
    read -r NEWHOME

    echo -e "\nEnter editor:"
    read -r NEWEDITOR
fi

if [[ "$SKIPINSTALL" -eq 0 ]]; then
    UNAME=$(uname)
    if [[ "$UNAME" == "Darwin" ]]; then
        if command_exists brew ; then
            brew update

            update_or_install astyle
            update_or_install autoconf
            update_or_install automake
            update_or_install binutils
            update_or_install cdiff
            update_or_install coreutils
            update_or_install dateutils
            update_or_install diffutils
            update_or_install findutils
            update_or_install gawk
            update_or_install gcc
            update_or_install gdb
            update_or_install git
            update_or_install gnu-indent
            update_or_install gnu-sed
            update_or_install gnu-tar
            update_or_install gnu-which
            update_or_install gnutls
            update_or_install grep
            update_or_install gzip
            update_or_install less
            update_or_install lynx
            update_or_install m4
            update_or_install macvim
            update_or_install make
            update_or_install md5sha1sum

            # mutt requires sidebar patch
            # update_or_install mutt

            update_or_install perl
            update_or_install pidof
            update_or_install pkg-config
            update_or_install python
            update_or_install ranger
            update_or_install reattach-to-user-namespace
            update_or_install screen
            update_or_install the_silver_searcher
            update_or_install tig
            update_or_install tmux
            update_or_install tmux-mem-cpu-load
            update_or_install tree
            update_or_install valgrind
            update_or_install vim --override-system-vi
            update_or_install unzip
            update_or_install urlview
            update_or_install watch
            update_or_install wdiff --with-gettext
            update_or_install weechat
            update_or_install wget
            update_or_install zsh

            brew linkapps macvim
        else
            echo "brew is not installed."
            exit 1
        fi
    fi
fi

if [[ "$SKIPCOPY" -eq 0 ]]; then
    sed -e 's,##NEWHOME##,'"$NEWHOME"',g' .zshrc > .zshrc.tmp && mv .zshrc.tmp .zshrc
    sed -e 's,##NEWUSER##,'"$NEWUSER"',g' .zshrc > .zshrc.tmp && mv .zshrc.tmp .zshrc
    sed -e 's,##NEWEDITOR##,'"$NEWEDITOR"',g' .zshrc > .zshrc.tmp && mv .zshrc.tmp .zshrc

    rm -rf "$NEWHOME/.dotbackup"
    mkdir -p "$NEWHOME/.dotbackup"
    mv_if_exists "$NEWHOME/.astylerc" "$NEWHOME/.dotbackup/"
    # Do not "backup" .config, or a lot of stuff might be lost
    # mv_if_exists "$NEWHOME/.config" "$NEWHOME/.dotbackup"/
    mv_if_exists "$NEWHOME/.gitconfig" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.jsbeautifyrc" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.jshintrc" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.lessfilter" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.lesskey" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.lldbinit" "$NEWHOME/.dotbackup/"
    # Do not "backup" .mutt either, or mail cache is lost
    # mv_if_exists $NEWHOME/.mutt $NEWHOME/.dotbackup/
    # Do not "backup" .oh-my-zsh either, or the oh-my-zsh installation is lost
    # mv_if_exists $NEWHOME/.oh-my-zsh $NEWHOME/.dotbackup/
    mv_if_exists "$NEWHOME/.passwords".sh "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.tigrc" "$NEWHOME/.dotbackup/"
    # do not backup .tmux, or plugins are lost
    # mv_if_exists "$NEWHOME/.tmux" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.tmux".conf "$NEWHOME/.dotbackup/"
    # Do not "backup" .vim directory either, or all plugins have to re-installed
    # mv_if_exists "$NEWHOME/.vim" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.vimrc" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.xbindkeysrc" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.Xdefaults" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.xinitrc" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.Xmodmap" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.xsession" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.ycm_extra_conf.py" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.zsh" "$NEWHOME/.dotbackup/"
    mv_if_exists "$NEWHOME/.zshrc" "$NEWHOME/.dotbackup/"


    # Copy all files over:
    cp .astylerc "$NEWHOME/"
    cp -r .config "$NEWHOME/"
    cp .gitconfig "$NEWHOME/"
    cp .jsbeautifyrc "$NEWHOME/"
    cp .jshintrc "$NEWHOME/"
    cp .lessfilter "$NEWHOME/"
    cp .lesskey "$NEWHOME/"
    cp .lldbinit "$NEWHOME/"
    cp -r .mutt "$NEWHOME/"
    cp -r .oh-my-zsh "$NEWHOME/"
    cp .passwords.sh "$NEWHOME/"
    cp .tigrc "$NEWHOME/"
    cp -r .tmux "$NEWHOME/"
    cp .tmux.conf "$NEWHOME/"
    cp -r .vim "$NEWHOME/"
    cp .vimrc "$NEWHOME/"
    cp .xbindkeysrc "$NEWHOME/"
    cp .Xdefaults "$NEWHOME/"
    cp .xinitrc "$NEWHOME/"
    cp .Xmodmap "$NEWHOME/"
    cp .xsession "$NEWHOME/"
    cp .ycm_extra_conf.py "$NEWHOME/"
    cp -r .zsh "$NEWHOME/"
    cp .zshrc "$NEWHOME/"

    ln -s "$NEWHOME/.vim" "$NEWHOME/.config/nvim"
    ln -s "$NEWHOME/.vimrc" "$NEWHOME/.vim/init.vim"

    # Reset .zshrc
    git checkout -- .zshrc
fi

