#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

rm -rf $HOME/.dotbackup

cpix() {
    if [ -f "$1" ]; then
        cp "$1" "${@:2}"
    elif [ -d "$1" ]; then
        cp -r "$1" "${@:2}"
    fi
}

backup() {
    if [ -f "$1" ]; then
        cp "$1" $HOME/.dotbackup
    elif [ -d "$1" ]; then
        cp -r "$1" $HOME/.dotbackup
    fi
}

# Copy all Windows specific files.
if [[ `uname` = MSYS_NT* ]]; then
    backup $APPDATA/lazygit
    backup $APPDATA/alacritty
    backup $APPDATA/Code/User
    backup $HOME/_vimrc

    cpix AppData/Roaming/lazygit $APPDATA
    cpix AppData/Roaming/alacritty $APPDATA
    cpix AppData/Roaming/Code/User $APPDATA/Code
    # cp -r $APPDATA/../Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json WindowsTerminal/

    cpix .vimrc $HOME/_vimrc

# All non-Windows files.
else
    backup $HOME/.vimrc

    cpix .vimrc $HOME
fi

backup $HOME/.bash_profile
backup $HOME/.bashrc
backup $HOME/.clang-format
backup $HOME/.config/
backup $HOME/.ctags
backup $HOME/.gdb.py
backup $HOME/.gdbinit
backup $HOME/.gdbinit.local
backup $HOME/.gitconfig
backup $HOME/.gitignore_global
backup $HOME/.inputrc
backup $HOME/.lessfilter
backup $HOME/.lesskey
backup $HOME/.lldbinit
backup $HOME/.minttycolors
backup $HOME/.minttyrc
backup $HOME/.oh-my-zsh/
backup $HOME/.tigrc
backup $HOME/.tmux/
backup $HOME/.tmux.conf
backup $HOME/.uncrustify/
backup $HOME/.vim/
backup $HOME/.xbindkeysrc
backup $HOME/.Xdefaults
backup $HOME/.xinitrc
backup $HOME/.Xmodmap
backup $HOME/.xsession
backup $HOME/.ycm_extra_conf.py
backup $HOME/.zsh/
backup $HOME/.zshrc

cpix .bash_profile $HOME
cpix .bashrc $HOME
cpix .clang-format $HOME
cpix .config/ $HOME
cpix .ctags $HOME
cpix .gdb.py $HOME
cpix .gdbinit $HOME
cpix .gdbinit.local $HOME
cpix .gitconfig $HOME
cpix .gitignore_global $HOME
cpix .inputrc $HOME
cpix .lessfilter $HOME
cpix .lesskey $HOME
cpix .lldbinit $HOME
cpix .minttycolors $HOME
cpix .minttyrc $HOME
cpix .oh-my-zsh/ $HOME
cpix .tigrc $HOME
cpix .tmux/ $HOME
cpix .tmux.conf $HOME
cpix .uncrustify/ $HOME
cpix .vim/ $HOME
cpix .vimrc $HOME
cpix .xbindkeysrc $HOME
cpix .Xdefaults $HOME
cpix .xinitrc $HOME
cpix .Xmodmap $HOME
cpix .xsession $HOME
cpix .ycm_extra_conf.py $HOME
cpix .zsh/ $HOME
cpix .zshrc $HOME

