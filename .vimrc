set nocompatible
filetype off

execute pathogen#infect()

syntax enable
set background=dark
set number

" Indentation is 4 spaces, and not a tab
set tabstop=4
set shiftwidth=4
set expandtab

" Solarized Theme
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

" Compile and Run C++ code
autocmd filetype cpp nnoremap <D-r> :w <bar> exec '!clang++ '.shellescape('%').' -o '.shellescape('%:r').' && ./'.shellescape('%:r')<CR>
