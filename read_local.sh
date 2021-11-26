#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cpix() {
    if [ -f "$1" ]; then
        cp "$1" "${@:2}"
    elif [ -d "$1" ]; then
        cp -r "$1" "${@:2}"
    fi
}

# Copy all Windows specific files.
if [[ `uname` = MSYS_NT* ]]; then
    cpix $APPDATA/lazygit AppData/Roaming
    cpix $APPDATA/alacritty AppData/Roaming
    cpix $APPDATA/Code/User AppData/Roaming/Code
    # cp -r $APPDATA/../Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json WindowsTerminal/

    cpix $HOME/_vimrc .vimrc

# All non-Windows files.
else
    cpix $HOME/.vimrc .vimrc
fi

cpix $HOME/.bash_profile .
cpix $HOME/.bashrc .
cpix $HOME/.clang-format .
cpix $HOME/.config/ .
cpix $HOME/.ctags .
cpix $HOME/.gdb.py .
cpix $HOME/.gdbinit .
cpix $HOME/.gdbinit.local .
cpix $HOME/.gitconfig .
cpix $HOME/.gitignore_global .
cpix $HOME/.inputrc .
cpix $HOME/.lessfilter .
cpix $HOME/.lesskey .
cpix $HOME/.lldbinit .
cpix $HOME/.minttycolors .
cpix $HOME/.minttyrc .
cpix $HOME/.oh-my-zsh/ .
cpix $HOME/.tigrc .
cpix $HOME/.tmux/ .
cpix $HOME/.tmux.conf .
cpix $HOME/.uncrustify/ .
cpix $HOME/.vim/ .
cpix $HOME/.xbindkeysrc .
cpix $HOME/.Xdefaults .
cpix $HOME/.xinitrc .
cpix $HOME/.Xmodmap .
cpix $HOME/.xsession .
cpix $HOME/.ycm_extra_conf.py .
cpix $HOME/.zsh/ .
cpix $HOME/.zshrc .

