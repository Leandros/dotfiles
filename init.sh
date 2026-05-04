#!/usr/bin/env bash
set -euxo pipefail

BASE_URL="https://raw.githubusercontent.com/Leandros/dotfiles/refs/heads/master"

curl -fSsL -o "$HOME/.vimrc" "${BASE_URL}/.vimrc.min"
curl -fSsL -o "$HOME/.bash_profile" "${BASE_URL}/.bash_profile"
curl -fSsL -o "$HOME/.bashrc" "${BASE_URL}/.bashrc"
curl -fSsL -o "$HOME/.inputrc" "${BASE_URL}/.inputrc"
curl -fSsL -o "$HOME/.lesskey" "${BASE_URL}/.lesskey"
