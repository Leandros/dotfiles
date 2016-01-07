#!/bin/bash

if [ -z ${HOME+x} ]; then
    echo "`HOME` environment variable is not set."
    exit 1
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

