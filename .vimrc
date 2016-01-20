" Must-Haves.
set nocompatible
filetype off

" Vundle Stuff
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Set mapleader before plugin loads
nnoremap <SPACE> <Nop>
let mapleader=" "
let maplocalleader=" "

" Let Vundle manage itself.
Plugin 'gmarik/Vundle.vim'

" Plugins
Plugin 'altercation/vim-colors-solarized'
Plugin 'scrooloose/syntastic'
Plugin 'xuhdev/SingleCompile'
Plugin 'tpope/vim-fugitive'
Plugin 'bling/vim-airline'
Plugin 'jiangmiao/auto-pairs'
Plugin 'ervandew/supertab'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'easymotion/vim-easymotion'
Plugin 'tpope/vim-commentary'
Plugin 'kien/ctrlp.vim'
Plugin 'rking/ag.vim'
Plugin 'Chiel92/vim-autoformat'
Plugin 'jeffkreeftmeijer/vim-numbertoggle'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-lua-ftplugin'
Plugin 'Yggdroot/indentLine'
Plugin 'tmux-plugins/vim-tmux-focus-events'

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
set timeoutlen=1000 " timeout for leader key
set ttimeoutlen=10  " timeout for esc key

" Show if leader key is pressed
set showcmd

" Correct backspace
set backspace=indent,eol,start

" Cygwin cursor fix.
let &t_ti.="\e[1 q"
let &t_SI.="\e[5 q"
let &t_EI.="\e[1 q"
let &t_te.="\e[0 q"

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

" Theme
set background=dark
colorscheme solarized


" Compile and Run code. The primitive way.
" autocmd Filetype java nnoremap <D-r> :w <bar> exec '!javac '.shellescape('%').' && java '.shellescape('%:r')<CR>
" autocmd filetype c nnoremap <D-r> :w <bar> exec '!clang '.shellescape('%').' -o '.shellescape('%:r').' && ./'.shellescape('%:r')<CR>
" autocmd filetype cpp nnoremap <D-r> :w <bar> exec '!clang++ '.shellescape('%').' -o '.shellescape('%:r').' && ./'.shellescape('%:r')<CR>

" Compile and Run code. The easy way.
nmap <D-r> :SCCompileRun<CR>

" Warn about doing the wrong undo (U instead of u).
nnoremap U :echo " < < ===== C H E C K C A P S L O C K ===== > > "<CR>

" Map redo to r instead of C-r
nnoremap j <C-r>

" Convenient pasting.
set pastetoggle=<F2>

" Convenient copy to clipboard.
vnoremap <C-c> :w !pbcopy<CR><CR>
noremap <C-v> :r !pbpaste<CR><CR>

" Unhighlight searches
" using <esc> for this, behaves weird
nnoremap <C-d> :noh<return>

" Reselect visual blocks after movement
vnoremap < <gv
vnoremap > >gv

" Keep search matches in the middle of the window.
nnoremap ? nzzzv
nnoremap - Nzzzv

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

" No clue???
" nnoremap <C-B> <C-W><C-H>
" nnoremap <C-N> <C-W><C-J>
" nnoremap <C-R> <C-W><C-K>
" nnoremap <C-S> <C-W><C-L>

" Move page up / down
nnoremap ( <PageDown>
nnoremap ) <PageUp>
vnoremap ) <PageDown>
vnoremap ) <PageUp>

" Move line up down
nnoremap <S-n> <C-e>
nnoremap <S-r> <C-y>
vnoremap <S-n> <C-e>
vnoremap <S-r> <C-y>

" Insert newline
nnoremap <CR> o<Esc>
inoremap <C-O> <Esc>o
" inoremap  <Esc>o

" Split switching
nnoremap <C-n> <C-W>j
nnoremap <C-r> <C-W>k
nnoremap <C-b> <C-W>h
nnoremap <C-s> <C-W>l

nnoremap <C-i> :vnew<CR>
nnoremap <C-t> :new<CR>

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
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#whitespace#mixed_indent_algo = 0

" Setup Airline font
if has('gui_running')
    set guifont=Menlo\ for\ Powerline:h11
endif
let g:airline_powerline_fonts = 1

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

" Easy Motion Settings
map <Leader> <Plug>(easymotion-prefix)
map <Leader>s <Plug>(easymotion-lineforward)
map <Leader>n <Plug>(easymotion-j)
map <Leader>r <Plug>(easymotion-k)
map <Leader>b <Plug>(easymotion-linebackward)
nmap t <Plug>(easymotion-s2)

let g:EasyMotion_smartcase = 1
let g:EasyMotion_startofline = 0 " keep cursor column when JK motion"

" ag.vim Settings.
let g:ag_working_path_mode="r"

" vim-autoformat Settings.
noremap <F3> :Autoformat<CR> "
let g:formatdef_astyle_c = '"astyle --mode=c"'
let g:formatters_c = ['astyle_c']
let g:formatdef_astyle_cpp = '"astyle --mode=c"'
let g:formatters_cpp = ['astyle_cpp']
let g:formatdef_astyle_objc = 'astyle --mode=c'
let g:formatters_objc = ['astyle_objc']
let g:formatdef_jsbeautify = 'js-beautify -f -'
let g:formatters_javascript = ['jsbeautify']


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

" Highlight whitespace
if version >= 704 && has('patch712')
    set listchars=tab:--,trail:~,extends:>,precedes:<,space:·
    set nolist

    " Highlight whitespace color config
    hi Conceal ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
endif

" vim-ftplugin config
let g:lua_compiler_name = '/usr/local/bin/luac'

" SuperTab config
runtime! plugin/supertab.vim
inoremap <s-tab> <tab>
"let g:SuperTabMappingTabLiteral = '<s-tab>'
"inoremap <s-tab> <C-v><Tab>

" NumberToggle config
let g:NumberToggleTrigger="<C-o>"

" Indent Line settings
let g:indentLine_enabled = 1
let g:indentLine_color_term = 239
let g:indentLine_char = '│' " ''  default: '│'
let g:indentLine_concealcursor = 'inc' " (default 'inc')
let g:indentLine_conceallevel = 2 " (default 2)

