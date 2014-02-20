execute pathogen#infect()

syntax enable
set background=dark
set number

set tabstop=4
set shiftwidth=4
set expandtab

let g:solarized_termcolors=256
let g:solarized_contrast="low"

colorscheme solarized


set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'Valloric/YouCompleteMe'
