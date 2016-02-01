#!/bin/bash

command_exists () {
    type "$1" &> /dev/null ;
}

update_or_install() {
    local installed=$(brew ls --versions $1 | wc -l)
    if [[ "$installed" -gt 0 ]] ; then
        brew upgrade $1
    else
        brew install $@
    fi
}

echo -e "Enter username:"
read NEWUSER

echo -e "\nEnter home directory:"
read NEWHOME

echo -e "\nEnter editor:"
read NEWEDITOR

# Poor mans input parsing.
SKIPINSTALL=0
if [[ "$1" == "--skip-install" ]]; then
    SKIPINSTALL=1
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
            update_or_install findutils --with-default-names
            update_or_install gawk
            update_or_install gcc
            update_or_install gdb
            update_or_install git
            update_or_install gnu-indent --with-default-names
            update_or_install gnu-sed --with-default-names
            update_or_install gnu-tar --with-default-names
            update_or_install gnu-which --with-default-names
            update_or_install gnutls
            update_or_install grep --with-default-names
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

sed -e 's,##NEWHOME##,'"$NEWHOME"',g' .zshrc > .zshrc.tmp && mv .zshrc.tmp .zshrc
sed -e 's,##NEWUSER##,'"$NEWUSER"',g' .zshrc > .zshrc.tmp && mv .zshrc.tmp .zshrc
sed -e 's,##NEWEDITOR##,'"$NEWEDITOR"',g' .zshrc > .zshrc.tmp && mv .zshrc.tmp .zshrc

# Copy all files over:
cp .astylerc $NEWHOME/
cp -r .config $NEWHOME/
cp .gitconfig $NEWHOME/
cp .jsbeautifyrc $NEWHOME/
cp .jshintrc $NEWHOME/
cp .lessfilter $NEWHOME/
cp .lesskey $NEWHOME/
cp .lldbinit $NEWHOME/
cp -r .mutt $NEWHOME/
cp -r .oh-my-zsh $NEWHOME/
cp .passwords.sh $NEWHOME/
cp .tigrc $NEWHOME/
cp -r .tmux $NEWHOME/
cp .tmux.conf $NEWHOME/
cp -r .vim $NEWHOME/
cp .vimrc $NEWHOME/
cp .ycm_extra_conf.py $NEWHOME/
cp -r .zsh $NEWHOME/
cp .zshrc $NEWHOME/

# Reset .zshrc
git checkout -- .zshrc

