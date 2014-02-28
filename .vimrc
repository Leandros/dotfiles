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
Bundle 'scrooloose/nerdtree'

" General
set shell=$SHELL    " Set the default shell
set termencoding=utf-8 " Set the default encodings just in case $LANG isn't set
set encoding=utf-8  " Set the default encodings just in case $LANG isn't set
set cursorline      " Hightlight current selected line.
set ttyfast         " Set that we have a fast terminal

set hidden          " Hide buffer, instead of closing it.
syntax enable
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
set noswapfile

" Indentation is 4 spaces, and not a tab
set tabstop=4       " A tab is 4 spaces.
set autoindent      " Autoindent.
set copyindent      " Copy the previous indent on autoindenting.
set shiftwidth=4    " Number of spaces used for autoindent.
set expandtab
set smarttab        " Insert 'tabs' on start of line, according to shiftwidth instead of tabstop.

" Set mapping and key timeouts
set timeout
set timeoutlen=1000
set ttimeoutlen=100

" Write undo tree to a file to resume from next time the file is opened.
if has("persistent_undo")
  set undolevels=2000            " The number of undo items to remember
  set undofile                   " Save undo history to files locally
  set undodir=$HOME/.vimundo     " Set the directory of the undofile
  if !isdirectory(expand(&undodir))
    call mkdir(expand(&undodir), "p")
  endif
endif

" When running as diff.
if &diff
  set modifiable
  set noreadonly
  if tabpagenr('$') == 1
    nnoremap ZZ :wqall<cr>
  endif
endif

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

" Reselect visual blocks after movement
vnoremap < <gv
vnoremap > >gv

" Keep search matches in the middle of the window.
nnoremap y nzzzv
nnoremap Y Nzzzv

" Key map optimizations for Bone 2 Layout
" Normal Mode remaps.
"nnoremap b h
"nnoremap n k
"nnoremap r j
"nnoremap s l
nnoremap b <Left>
nnoremap n <Up>
nnoremap r <Down>
nnoremap s <Right>

" Visual and Select Mode remaps.
"vnoremap b h
"vnoremap n k
"vnoremap r j 
"vnoremap s l
vnoremap b <Left>
vnoremap n <Up>
vnoremap r <Down>
vnoremap s <Right>

" ReMap NERDTree Keys.
let NERDTreeMapRefresh='<D-r>'

" Open NERDTree when no files specified.
autocmd vimenter * if !argc() | NERDTree | endif

" Insert new line with Shift-Enter
nmap <S-Enter> o<Esc>

" Never mess when file opened without sudo.
cmap w!! w !sudo tee % >/dev/null
