" Must-Haves.
set nocompatible
filetype off

" Vundle Stuff
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Let Vundle manage itself.
Plugin 'gmarik/Vundle.vim'

" Plugins
Plugin 'altercation/vim-colors-solarized'
Plugin 'scrooloose/syntastic'
Plugin 'xuhdev/SingleCompile'
Plugin 'tpope/vim-fugitive'
Plugin 'rizzatti/dash.vim'
Plugin 'bling/vim-airline'

" Enable if really desired.
" Plugin 'Valloric/YouCompleteMe'

call vundle#end()
filetype plugin indent on

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
set showmatch       " Show matching braces.
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
set timeoutlen=100
set ttimeoutlen=100

" Correct backspace
set backspace=indent,eol,start

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
nnoremap b <Left>
nnoremap r <Up>
nnoremap n <Down>
nnoremap s <Right>

" Visual and Select Mode remaps.
vnoremap b <Left>
vnoremap r <Up>
vnoremap n <Down>
vnoremap s <Right>

nnoremap <C-B> <C-W><C-H>
nnoremap <C-N> <C-W><C-J>
nnoremap <C-R> <C-W><C-K>
nnoremap <C-S> <C-W><C-L>

" Split switching
map <C-n> <C-W>j
map <C-r> <C-W>k
map <C-b> <C-W>h
map <C-s> <C-W>l

" ReMap NERDTree Keys.
" let NERDTreeMapRefresh='<D-r>'

" Open NERDTree when no files specified.
" autocmd vimenter * if !argc() | NERDTree | endif

" Insert new line with Shift-Enter
nmap <S-Enter> o<Esc>

" Never mess when file opened without sudo.
cmap w!! w !sudo tee % >/dev/null

" Use Tabs in Makefiles
autocmd FileType make setlocal noexpandtab

" Unfold all
if has("autocmd")
    au BufWinEnter * normal zR
endif

" Set 80 column limit.
if exists('+colorcolumn')
  set colorcolumn=80
  highlight ColorColumn guibg=#004653
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
endif

" Airline Settings
set laststatus=2

" Syntactic Settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_cpp_config_file = '.syntastic_cpp_config'
let g:syntastic_cpp_check_header = 1
let g:syntastic_cpp_remove_include_errors = 1

" YouCompleteMe Settings
let g:ycm_confirm_extra_conf = 0

" Strip trailing whitespace
fun! <SID>StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

autocmd BufWritePre <buffer> :call <SID>StripTrailingWhitespaces()

" Minifier functions
fun! MinifyJson()
  %s/\ //g
  %s/\n//g
endfunction

command! JsonMinify call MinifyJson()
