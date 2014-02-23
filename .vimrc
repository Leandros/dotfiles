set nocompatible
filetype off

execute pathogen#infect()

syntax enable
set background=dark
set number

set tabstop=4
set shiftwidth=4
set expandtab

if has('gui_running')
    let g:solarized_contrast="low" 
    colorscheme solarized
else
    let g:solarized_termtrans=1
    colorscheme solarized
endif

" Vundle Stuff
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'
Bundle 'Valloric/YouCompleteMe'
