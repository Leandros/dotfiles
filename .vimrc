" Must-Haves.
set nocompatible
filetype off

" Vundle Stuff
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'
Bundle 'altercation/vim-colors-solarized'
Bundle 'Valloric/YouCompleteMe'
Bundle 'xuhdev/SingleCompile'
Bundle 'tpope/vim-fugitive'
Bundle 'Gundo'

" General
set hidden          " Hide buffer, instead of closing it.
syntax on
set number          " Always show line numbers.
set hlsearch        " Hightlight found searches.
set incsearch       " Show matched searches as you type.
set showmatch       " Show maching braces.
set ignorecase      " Ignore case when searching.
set smartcase       " Ignore case if search pattern is all lowercase, case-sensitive otherwise.

set history=1000    " Larger command history.
set undolevels=1000 " Undo ALL the changes.
set visualbell      " Don't beep.
set noerrorbells    " Don't beep.

set nobackup        " Disable backup. set noswapfile can disable the .swp file.

" Indentation is 4 spaces, and not a tab
set tabstop=4       " A tab is 4 spaces.
set autoindent      " Autoindent.
set copyindent      " Copy the previous indent on autoindenting.
set shiftwidth=4    " Number of spaces used for autoindent.
set expandtab
set smarttab        " Insert 'tabs' on start of line, according to shiftwidth instead of tabstop.

" Solarized Theme
set background=dark " Solarized Dark.
if has('gui_running')
    let g:solarized_contrast="low" 
    colorscheme solarized
else
    let g:solarized_termtrans=1
    colorscheme solarized
endif

" Compile and Run code. The primitive way.
" autocmd Filetype java nnoremap <D-r> :w <bar> exec '!javac '.shellescape('%').' && java '.shellescape('%:r')<CR>
" autocmd filetype c nnoremap <D-r> :w <bar> exec '!clang '.shellescape('%').' -o '.shellescape('%:r').' && ./'.shellescape('%:r')<CR>
" autocmd filetype cpp nnoremap <D-r> :w <bar> exec '!clang++ '.shellescape('%').' -o '.shellescape('%:r').' && ./'.shellescape('%:r')<CR>

" Compile and Run code. The easy way.
nmap <D-r> :SCCompileRun<CR>

" Warn about doing the wrong undo (U instead of u).
nnoremap U :echo " < < ===== C H E C K C A P S L O C K ===== > > "<CR>

" Convenient pasting.
set pastetoggle=<F2>

" Unhighlight searches
nmap <silent> <D-d> :nohlsearch<CR>

" Never mess when file opened without sudo.
cmap w!! w !sudo tee % >/dev/null
