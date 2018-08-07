" Must-Haves.
set nocompatible
filetype off

" Vundle Stuff
if has("win32") || has("win16")
    call plug#begin('$HOME/vimfiles/bundle/')
else
    call plug#begin('~/.vim/bundle')
endif

" Set mapleader before plugin loads
nnoremap <SPACE> <Nop>
let mapleader=" "
let maplocalleader=" "

" Optional plugins
let vim_fat = 0
let ycm_enabled = 1
let lightline_enabled = 1
let airline_enabled = 0
let js_dev_enabled = 1

" Vim Internal Plugins
if !has('nvim')
    packadd matchit
endif

" Ugly workaround until vim fixes
if has('python3')
  silent! python3 1
endif

" Visual Plugins
if has('nvim') && !empty($NVIM_GUI)
    Plug 'frankier/neovim-colors-solarized-truecolor-only'
    Plug 'equalsraf/neovim-gui-shim'
else
    Plug 'altercation/vim-colors-solarized'
endif

" Absolute Must Haves!
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'terryma/vim-multiple-cursors'
Plug 'Konfekt/FastFold'
Plug 'ervandew/supertab'
Plug 'Yggdroot/LeaderF'
Plug 'mhinz/vim-grepper'
Plug 'thirtythreeforty/lessspace.vim'
Plug 'maxbrunsfeld/vim-yankstack'

" General
Plug 'SirVer/ultisnips'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'junegunn/vim-easy-align'
Plug 'tpope/vim-fugitive'

" My own plugins
Plug 'leandros/vim-misc'

" My forks
Plug 'leandros/QFEnter'
Plug 'leandros/vim-bufkill'
Plug 'leandros/nerdtree' " No idea why I use my own fork

" Syntax / File Plugins
Plug 'Chiel92/vim-autoformat', { 'for': ['objc', 'gn', 'js', 'jsx', 'ts', 'tsx', 'javascript', 'typescript'] }
Plug 'cofyc/vim-uncrustify', { 'for': ['cpp', 'c', 'cs'] }
Plug 'dummyunit/vim-fastbuild', { 'for': ['fastbuild'] }
Plug 'wlangstroth/vim-racket', { 'for': ['racket'] }
Plug 'luochen1990/rainbow', { 'for': ['scheme', 'lisp', 'racket'] }
Plug 'leandros/hlsl.vim', { 'for': ['hlsl'] }
Plug 'leandros/vim-gn', { 'for': ['gn'] }

if ycm_enabled
    Plug 'Valloric/YouCompleteMe', { 'for': ['cpp', 'c', 'python'] }
endif


" =============================================================================
" FAT VIM
" =============================================================================
if vim_fat
    if lightline_enabled
        Plug 'itchyny/lightline.vim'
    elseif airline_enabled
        Plug 'vim-airline/vim-airline'
        Plug 'vim-airline/vim-airline-themes'
    endif

    if js_dev_enabled
        Plug 'leafgarland/typescript-vim'
        Plug 'pangloss/vim-javascript'
        Plug 'w0rp/ale', { 'for': ['js', 'ts', 'jsx', 'tsx', 'javascript', 'typescript' ] }
        Plug 'Shougo/deoplete.nvim', { 'for': ['js', 'ts', 'jsx', 'tsx', 'javascript', 'typescript' ], 'do': ':UpdateRemotePlugins' }
        Plug 'jparise/vim-graphql'
        Plug 'posva/vim-vue'
        Plug 'alvan/vim-closetag'
        Plug 'elzr/vim-json'
        if has_key(g:plugs, 'deoplete.nvim')
            let g:deoplete#enable_at_startup = 1
        endif
        let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.vue'
        let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.tsx,*.vue'
    endif

    Plug 'easymotion/vim-easymotion'
    Plug 'jeffkreeftmeijer/vim-numbertoggle'

    " Pinned, due to deoplete incompatability.
    Plug 'ludovicchabant/vim-gutentags', { 'tag': '0423321dc4fa80b41eaa41295b609186bb1eb5fb' }

    " Required for 'EnhancedJumps'
    Plug 'vim-scripts/ingo-library'
    Plug 'vim-scripts/EnhancedJumps'

    " My forks
    Plug 'leandros/taglist.vim'
    Plug 'leandros/YankRing.vim'
    Plug 'leandros/zoomwin'

    if !has("win32") && !has("win16")
        Plug 'Xuyuanp/nerdtree-git-plugin'
    endif
endif

call plug#end()

" required for remapping Y to y$
" has to come after plug#end()
if has_key(g:plugs, 'vim-yankstack')
    call yankstack#setup()
endif

" =============================================================================
" Language / Shell
" =============================================================================
set langmenu=en_US.UTF-8
let $LANG='en_US'

" Set the default shell
if has("win32") || has("win16")
    source $VIMRUNTIME/delmenu.vim
    source $VIMRUNTIME/menu.vim
    set shell=cmd.exe
    set shellcmdflag=/C
else
    set shell=$SHELL
endif

" =============================================================================
" General
" =============================================================================
set fileencoding=utf-8 " Set the encoding written to file
set termencoding=utf-8 " Set the default encodings just in case $LANG isn't set
set encoding=utf-8  " Set the default encodings just in case $LANG isn't set
set cursorline      " Hightlight current selected line.
set ttyfast         " Set that we have a fast terminal
set emoji           " enable emoji's on Vim8
set clipboard+=unnamed " enabled system clipboard

syntax enable
set hidden          " Hide buffer, instead of closing it.
set number          " Always show line numbers.
set hlsearch        " Hightlight found searches.
set incsearch       " Show matched searches as you type.
set ignorecase      " Ignore case when searching.
set smartcase       " Ignore case if search pattern is all lowercase, case-sensitive otherwise.
set nowrapscan      " Do not wrap when searching

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
set scrolloff=3     " 3 lines of buffer above and below the cursor

" Set mapping and key timeouts
set timeout
set timeoutlen=1000 " timeout for leader key
set ttimeoutlen=10  " timeout for esc key

" Show if leader key is pressed
set showcmd

" Correct backspace
set backspace=indent,eol,start

" Improve breaks
set showbreak=>>>
set breakindent

" Disable mouse
set mouse=c
set guioptions+=lrbmTLce
set guioptions-=lrbmTLce
set guioptions+=c

" =============================================================================
" Performance
" =============================================================================
" Improve performance of matchparen plugin
" This is DISABLING it!
let g:loaded_matchparen = 1         " Don't show matching parens.
set noshowmatch                     " Don't show matching braces.
let g:matchparen_timeout = 2
let g:matchparen_insert_timeout = 2

" Improve performance (not necessary on iTerm2 Beta)
" set lazyredraw

" Disable syntax highlighting long lines
set synmaxcol=300

" Disable syntax highlighting in large files
autocmd BufReadPre * if getfsize(expand("%")) > 10000000 | set syntax=OFF | endif

" =============================================================================
" Buffer Switching
" =============================================================================
" Improve :b switch menu
set wildchar=<Tab> wildmenu wildmode=full

" Buffer switching
nnoremap <Leader>1 :1b<CR>
nnoremap <Leader>2 :2b<CR>
nnoremap <Leader>3 :3b<CR>
nnoremap <Leader>4 :4b<CR>
nnoremap <Leader>5 :5b<CR>
nnoremap <Leader>6 :6b<CR>
nnoremap <Leader>7 :7b<CR>
nnoremap <Leader>8 :8b<CR>
nnoremap <Leader>9 :9b<CR>
nnoremap <Leader>0 :10b<CR>

" Jump to buffers with Ngb
let c = 1
while c <= 99
  execute "nnoremap " . c . "gb :" . c . "b\<CR>"
  let c += 1
endwhile

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
if has('nvim') && !empty($NVIM_GUI)
    set termguicolors
endif
set background=dark
colorscheme solarized

" =============================================================================
" Custom Filetypes
" =============================================================================
au BufRead,BufNewFile *.ds set filetype=rgbds                   " GameBoy Assembly
au BufRead,BufNewFile *.fl,*.flex,*.l,*.lm setlocal ft=lex      " Flex
au BufRead,BufNewFile *.y,*.ypp,*.ym setlocal ft=yacc           " Bison
au BufRead,BufNewFile *.man setlocal ft=groff                   " Groff/Troff
au BufRead,BufNewFile *.mm setlocal ft=objcpp                   " Objective-C++
au BufRead,BufNewFile *.m setlocal ft=objc                      " Objective-C

" =============================================================================
" Set syntax options
" =============================================================================
" Highlight trailing whitespace in c files
let c_space_errors = 1
" Custom no-fold in my c.vim
let c_no_block_fold = 1
" Don't fold comments
let c_no_comment_fold = 1
" Don't fold #if 0 blocks
let c_no_if0_fold = 1

" =============================================================================
" Bindings
" =============================================================================
" Warn about doing the wrong undo (U instead of u).
nnoremap U :echo " < < ===== C H E C K C A P S L O C K ===== > > "<CR>

" Map redo to r instead of C-r
nnoremap j <C-r>

" Map Vim Expression valuation
inoremap <c-a> <c-r>

" Convenient pasting.
set pastetoggle=<F2>

" Removed due to blocking super awesome multiline edit mode.
" Convenient copy to clipboard.
" vnoremap <C-c> :w !pbcopy<CR><CR>
" noremap <C-v> :r !pbpaste<CR><CR>

" Unhighlight searches
" using <esc> for this, behaves weird
nnoremap <C-d> :noh<return>

" Reselect visual blocks after movement
vnoremap < <gv
vnoremap > >gv

" Keep search matches in the middle of the window.
nnoremap ? nzzzv
nnoremap - Nzzzv

" Move by words
" nnoremap B B
" nnoremap S W
nnoremap <S-b> b
nnoremap <S-s> w
vnoremap <S-b> b
vnoremap <S-s> w
" Go to end of word
nnoremap w e
vnoremap w e

" Key map optimizations for Bone 2 Layout
" Normal Mode remaps.
nnoremap b <Left>
nnoremap r <Up>
nnoremap n <Down>
nnoremap s <Right>
nnoremap gn gj
nnoremap gr gk

" Visual and Select Mode remaps.
vnoremap b <Left>
vnoremap r <Up>
vnoremap n <Down>
vnoremap s <Right>
vnoremap gn gj
vnoremap gr gk

" Move half page up / down
nnoremap ( <C-D>
nnoremap ) <C-U>
vnoremap ( <C-D>
vnoremap ) <C-U>

" Move line up down
nnoremap <S-n> <C-e>
nnoremap <S-r> <C-y>
vnoremap <S-n> <C-e>
vnoremap <S-r> <C-y>

" Insert newline
" nnoremap <CR> o<Esc>
" inoremap <C-O> <Esc>o

" Split switching
nnoremap <C-n> <C-W>j
nnoremap <C-r> <C-W>k
nnoremap <C-b> <C-W>h
nnoremap <C-s> <C-W>l

" Split resizing
nnoremap ! 5<C-W>-
nnoremap = 5<C-W>+
nnoremap < 5<C-W><
nnoremap > 5<C-W>>

" Even out splits
nnoremap <C-y>w <C-W>=
nnoremap <C-y>m <C-W>_
nnoremap <C-y>t <C-W>T
nnoremap <C-y>l :ZoomWin<CR>

" Split Creating
nnoremap <C-i> :vsplit<CR>
nnoremap <C-t> :split<CR>

" Split killing
command! Bd bp\|bd \#
nnoremap <C-q> :BD<CR>
nnoremap <C-w> :bd<CR>

" Close / Open quickfix
nnoremap <Leader>qq :cclose<CR>
nnoremap <Leader>qc :cclose<CR>
nnoremap <Leader>qo :copen<CR>

" Map Y to y$, to behave like D and C
nnoremap Y y$

" =============================================================================
" Tag navigation keys
" =============================================================================
if ycm_enabled
    " let g:ycm_python_binary_path = 'python3'
    if js_dev_enabled
        autocmd FileType javascript nnoremap <Leader>d :ALEGoToDefinition<CR>
        autocmd FileType typescript nnoremap <Leader>d :ALEGoToDefinition<CR>
        autocmd FileType cpp nnoremap <Leader>d :YcmCompleter GoTo<CR>
        autocmd FileType c nnoremap <Leader>d :YcmCompleter GoTo<CR>
        autocmd FileType javascript nnoremap <Leader>, :ALEFindReferences<CR>
        autocmd FileType typescript nnoremap <Leader>, :ALEFindReferences<CR>
        autocmd FileType cpp nnoremap <Leader>, :YcmCompleter GetType<CR>
        autocmd FileType c nnoremap <Leader>, :YcmCompleter GetType<CR>
        nnoremap <Leader>t :YcmCompleter GetDoc<CR>
        nnoremap <Leader>i :YcmCompleter GoToInclude<CR>
        " jump back after go to definition
        nnoremap <Leader>.  <C-O>
    else
        nnoremap <Leader>d :YcmCompleter GoTo<CR>
        nnoremap <Leader>, :YcmCompleter GetType<CR>
        nnoremap <Leader>t :YcmCompleter GetDoc<CR>
        nnoremap <Leader>i :YcmCompleter GoToInclude<CR>
        " jump back after go to definition
        nnoremap <Leader>.  <C-O>
    endif
else
    nnoremap <Leader>d <C-]>
    nnoremap <Leader>. <C-t>
endif
nnoremap <Leader>c :TlistToggle<CR>

" =============================================================================
" Tab navigation
" =============================================================================
nnoremap <C-u>b :tabprevious<CR>
nnoremap <C-u>s :tabnext<CR>
nnoremap <C-u>n :tabedit<CR>
nnoremap <C-u>c :tabclose<CR>
nnoremap <C-u>1 1gt
nnoremap <C-u>2 2gt
nnoremap <C-u>3 3gt
nnoremap <C-u>4 4gt
nnoremap <C-u>5 5gt
nnoremap <C-u>6 6gt
cabbrev tabv tab sview +setlocal\ nomodifiable

" =============================================================================
" Indent
" =============================================================================
" Use two spaces to indent js/ts files
autocmd FileType javascript setlocal tabstop=2
autocmd FileType javascript setlocal shiftwidth=2
autocmd FileType typescript setlocal tabstop=2
autocmd FileType typescript setlocal shiftwidth=2
autocmd FileType typescript set makeprg=tsc\ $*

" Setup comment string
autocmd FileType javascript setlocal commentstring=/*\ %s\ */
autocmd FileType typescript setlocal commentstring=/*\ %s\ */

" Use two spaces to indent json files
autocmd FileType json setlocal tabstop=2
autocmd FileType json setlocal shiftwidth=2
" Use Tabs in Makefiles
autocmd FileType make setlocal noexpandtab

" Use two spaces in gn files
autocmd FileType gn setlocal tabstop=2
autocmd FileType gn setlocal shiftwidth=2

" Use two spaces in yaml files
autocmd FileType yaml setlocal tabstop=2
autocmd FileType yaml setlocal shiftwidth=2

" =============================================================================
" Folding Config
" =============================================================================
nnoremap z( zj
nnoremap z) zk
augroup vimrc
    autocmd!

    " Set foldmethod indent AND manual
    autocmd BufReadPre * setlocal foldmethod=indent
    autocmd BufWinEnter * if &fdm == 'indent' | setlocal foldmethod=manual | endif

    " Open all folds at startup
    autocmd BufRead * normal zR
augroup END

augroup filetype_cs
    autocmd!

    " Set folding by syntax for C# (Unity) files
    autocmd FileType cs setlocal foldmethod=syntax
    autocmd FileType cs let b:match_words = '\s*#\s*region.*$:\s*#\s*endregion'

    " Close all folds
    autocmd BufRead *.cs normal zM
augroup END

augroup filetype_cpp
    autocmd!

    " Create custom doxygen comment style
    autocmd FileType cpp syn region doxygenComment start="/\*\!" end="\*/" fold
    autocmd FileType cpp hi link doxygenComment cError

    " Fold based on our custom syntax.
    autocmd FileType cpp setlocal foldmethod=syntax

    " Close all folds.
    autocmd BufRead *.cxx,*.hxx,*.cpp,*.hpp normal zM
augroup END

" =============================================================================
" Set 80 column limit.
" =============================================================================
if exists('+colorcolumn')
  set colorcolumn=80
  highlight ColorColumn guibg=#004653

  " except for mail
  autocmd FileType mail set colorcolumn=72
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
endif

" =============================================================================
" Setup GUI font
" =============================================================================
if has('gui_running')
    if has('nvim')
        " Done in ginit.vim
        " has('gui_running') is always false.
    else
        set t_Co=256
        set guifont=Input:h11
        set lsp=0
        " HighDPI
        " set guifont=Input:h9:w4.5
        " set lsp=-2
    endif
endif

" =============================================================================
" Commands
" =============================================================================
" Invoke p4
command -nargs=+ P4 :cexpr system('p4.py <args> '.expand('%:p')) | e! | copen

" Change current working directory
nnoremap ,cd :cd %:p:h<CR>:pwd<CR>

" Never mess when file opened without sudo.
cmap w!! w !sudo tee % >/dev/null

" =============================================================================
" Profiling
" =============================================================================
fun! ProfileStart()
:   profile start profile.log
:   profile func *
:   profile file *
endfun
command! ProfileStart call ProfileStart()

fun! ProfileEnd()
:   profile pause
:   noautocmd qall!
endfun
command! ProfileEnd call ProfileEnd()

" =============================================================================
" Strip trailing whitespace
" =============================================================================
fun! StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

command! StripWhitespace call StripTrailingWhitespaces()

" =============================================================================
" Minifier functions
" =============================================================================
fun! MinifyJson()
  %s/\ //g
  %s/\n//g
endfunction

command! JsonMinify call MinifyJson()

" =============================================================================
" Highlight whitespace
" =============================================================================
" if version >= 704 && has('patch712')
"     set listchars=tab:--,trail:~,extends:>,precedes:<,space:·
"     set nolist
"     " Highlight whitespace color config
"     hi Conceal ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
" endif

" =============================================================================
" Shell command
" =============================================================================
command! -complete=shellcmd -nargs=+ Shell call s:RunShellCommand(<q-args>)
function! s:RunShellCommand(cmdline)
  let expanded_cmdline = a:cmdline
  for part in split(a:cmdline, ' ')
     if part[0] =~ '\v[%#<]'
        let expanded_part = fnameescape(expand(part))
        let expanded_cmdline = substitute(expanded_cmdline, part, expanded_part, '')
     endif
  endfor
  botright new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  execute '$read !'. expanded_cmdline
  execute 1 'delete _'
  setlocal nomodifiable
  1
endfunction

" =============================================================================
" Compile and Run code. The primitive way.
" =============================================================================
command! -nargs=1 Silent execute ':silent !'.<q-args> | execute ':redraw!'
function! CompileCC()
   write
   let src = expand('%:p')
   let exe = expand('%:r')
   call s:RunShellCommand('clang++ -std=c++14 '.src.' -o '.exe.' && ./'.exe)
   exec 'Silent rm '.exe
endfunction
autocmd filetype cpp nnoremap <F5> :call CompileCC()<CR>
command! Run :call CompileCC()

" =============================================================================
" Focus Mode
" =============================================================================
function! ToggleFocusMode()
  if (&foldcolumn != 12)
    set laststatus=0
    set numberwidth=10
    set foldcolumn=12
    set noruler
    hi FoldColumn ctermbg=none
    hi LineNr ctermfg=0 ctermbg=none
    hi NonText ctermfg=0
  else
    set laststatus=2
    set numberwidth=4
    set foldcolumn=0
    set ruler
    execute 'colorscheme ' . g:colors_name
  endif
endfunc
nnoremap <F1> :call ToggleFocusMode()<cr>

" =============================================================================
" Buffer Moving
" =============================================================================
function! MarkWindowSwap()
    let g:markedWinNum = winnr()
endfunction

function! DoWindowSwap()
    "Mark destination
    let curNum = winnr()
    let curBuf = bufnr( "%" )
    exe g:markedWinNum . "wincmd w"
    "Switch to source and shuffle dest->source
    let markedBuf = bufnr( "%" )
    "Hide and open so that we aren't prompted and keep history
    exe 'hide buf' curBuf
    "Switch to dest and shuffle source->dest
    exe curNum . "wincmd w"
    "Hide and open so that we aren't prompted and keep history
    exe 'hide buf' markedBuf
endfunction

nnoremap <silent> <Leader>m :call MarkWindowSwap()<CR>
nnoremap <silent> <Leader>u :call DoWindowSwap()<CR>

" =============================================================================
" Generate CTags manually
" =============================================================================
function! GenerateTags()
:   w
:   exec '!ctags -R -f tags .'
endfunction
command! -nargs=* GenTagsManual call GenerateTags()

" =============================================================================
" Quit if quickfix is last window
" =============================================================================
augroup QFClose
    autocmd!
    autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix" | q | endif
augroup END

" =============================================================================
" Close all buffers
" =============================================================================
function! CloseBuffers()
    let curr = bufnr("%")
    let last = bufnr("$")
    if curr > 1     | silent! execute "1,".(curr-1)."bd"        | endif
    if curr < last  | silent! execute (curr+1).",".last."bd"    | endif
endfunction
nmap <Leader>w :call CloseBuffers()<CR>

" =============================================================================
" Increment numbers in rows
" =============================================================================
function! Incr()
    let a = line('.') - line("'<")
    let c = virtcol("'<")
    if a > 0
        execute 'normal! '.c.'|'.a."\<C-a>"
    endif
    normal `<
endfunction
vnoremap <C-a> :call Incr()<CR>


" =============================================================================
"                       ____  _             _
"                      |  _ \| |_   _  __ _(_)_ __  ___
"                      | |_) | | | | |/ _` | | '_ \/ __|
"                      |  __/| | |_| | (_| | | | | \__ \
"                      |_|   |_|\__,_|\__, |_|_| |_|___/
"                                     |___/
" =============================================================================

" =============================================================================
" Statusline
" =============================================================================
set laststatus=2

if has_key(g:plugs, 'lightline-vim')
    " Lightline settings
    let g:lightline = {
        \ 'colorscheme': 'solarized',
        \ 'active': {
        \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'relativepath', 'modified' ] ],
        \ },
        \ 'inactive': {
        \   'left': [ [ ], [ 'relativepath' ] ],
        \ },
        \ }
endif

if has_key(g:plugs, 'vim-airline')
    " Airline Settings
    let g:airline_highlighting_cache = 1
    let g:airline_inactive_collapse = 1
    let g:airline_extensions = []
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#buffer_nr_show = 1
    let g:airline#extensions#whitespace#mixed_indent_algo = 0
    let g:airline_powerline_fonts = 1
endif

" =============================================================================
" ReMap NERDTree Keys.
" =============================================================================
let g:NERDTreeMapRefresh='<C-a>'
let g:NERDTreeMapRefreshRoot='<C-u>'
let g:NERDTreeMapOpenSplit='t'
let g:NERDTreeMapOpenVSplit='i'
let g:NERDTreeMenuDown='n'
let g:NERDTreeMenuUp='r'

let g:NERDTreeMapChdir='C'
let g:NERDTreeMapUpdir='u'
" let g:NERDTreeMapActivateNode='<CR>'
" let NERDTreeMapNextSibling='N'
" let NERDTreeMapPrevSibling='R'

" Custom bindings
augroup nerdtreebuf
    autocmd!
    autocmd FileType nerdtree nnoremap <buffer> <silent> <CR> :call nerdtree#ui_glue#invokeKeyMap("o")<CR>
augroup END

" Open NERDTree
map <Leader>e :NERDTreeToggle<CR>

" NERDTree options
let g:NERDTreeChDirMode = 2
let g:NERDTreeShowHidden = 1
let g:NERDTreeQuitOnOpen = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeAutoDeleteBuffer = 1
let g:NERDTreeShowLineNumbers = 0
let g:NERDTreeIgnore = ['\.meta$','^\.DS_Store$']

" Open NERDTree when no files specified.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Close VIM if only tab left is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Hide Line Numbers
augroup nerdtree
    autocmd!
    autocmd FileType nerdtree set nonumber
    autocmd FileType nerdtree set norelativenumber
augroup END

" NERDTress File highlighting
function! NERDTreeHighlightFile(extension, regex, fg, bg, guifg, guibg)
 exec 'autocmd filetype nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
 exec 'autocmd filetype nerdtree syn match ' . a:extension .' #^.*\('. a:regex .'\)$#'
endfunction

" source files
" For some reason, VIM doesn't like C files :(
" C
call NERDTreeHighlightFile('cfile', '\.c',          '11', 'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('cheader', '\.h',        '9',  'NONE', 'NONE', 'NONE')
" C++
call NERDTreeHighlightFile('cc', '\.cc',            '5',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('hh', '\.hh',            '9',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('cpp', '\.cpp',          '5',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('hpp', '\.hpp',          '9',  'NONE', 'NONE', 'NONE')
" Objective-C
call NERDTreeHighlightFile('mm', '\.mm',            '4',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('m', '\.m',              '4',  'NONE', 'NONE', 'NONE')
" shell scripts
call NERDTreeHighlightFile('sh', '\.sh',            '2',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('bash', '\.bash',        '2',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('zsh', '\.zsh',          '2',  'NONE', 'NONE', 'NONE')
" makefiles
call NERDTreeHighlightFile('mk', '\.mk',            '28', 'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('makefile', '\makefile', '28', 'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('Makefile', '\Makefile', '28', 'NONE', 'NONE', 'NONE')
" JavaScript
call NERDTreeHighlightFile('js', '\.js',            '3',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('jsx', '\.jsx',          '3',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('ts', '\.ts',            '5',  'NONE', 'NONE', 'NONE')
call NERDTreeHighlightFile('tsx', '\.tsx',          '5',  'NONE', 'NONE', 'NONE')

" =============================================================================
" Easy Motion Settings
" =============================================================================
if has_key(g:plugs, 'vim-easymotion')
    map <Leader> <Plug>(easymotion-prefix)
    map <Leader>s <Plug>(easymotion-lineforward)
    map <Leader>n <Plug>(easymotion-j)
    map <Leader>r <Plug>(easymotion-k)
    map <Leader>b <Plug>(easymotion-linebackward)
    nmap e <Plug>(easymotion-s2)

    let g:EasyMotion_smartcase = 1
    let g:EasyMotion_startofline = 0 " keep cursor column when JK motion
endif

" =============================================================================
" vim-autoformat Settings.
" =============================================================================
if has_key(g:plugs, 'vim-autoformat')
    noremap <C-f> :Autoformat<CR>
    let g:formatdef_astyle_objc = '"astyle --mode=c"'
    let g:formatdef_prettier_ts = '"yarn --silent prettier --parser=typescript --stdin"'
    let g:formatdef_prettier_js = '"yarn --silent prettier --stdin"'
    let g:formatdef_gnformat = '"gn format --stdin"'
    let g:formatters_objc = ['astyle_objc']
    let g:formatters_javascript = ['prettier_js']
    let g:formatters_typescript = ['prettier_ts']
    let g:formatters_gn = ['gnformat']
endif

" =============================================================================
" Uncrustify
" =============================================================================
if has_key(g:plugs, 'vim-uncrustify')
    function! GetUncrustifyCfg()
python3 <<EOF
import vim
import os

file_name = ".uncrustify.cfg"
cur_dir = os.getcwd()

while True:
    file_list = os.listdir(cur_dir)
    parent_dir = os.path.dirname(cur_dir)
    if file_name in file_list:
        vim.command("let sUncPath = '%s'" % cur_dir)
        break
    else:
        if cur_dir == parent_dir:
            vim.command("let sUncPath = '%s'" % "__non__")
            break
        else:
            cur_dir = parent_dir

EOF

        if sUncPath ==# "__non__"
            return 0
        else
            let g:uncrustify_cfg_file_path = sUncPath . "/.uncrustify.cfg"
            return 1
        endif
    endfunction

    function! UncrustifyWrapper(language)
        call GetUncrustifyCfg()
        call Uncrustify('cpp')
    endfunction
    function! RangeUncrustifyWrapper(language) range
        call GetUncrustifyCfg()
        " call RangeUncrustify('cpp')
        return call('Uncrustify2', extend([a:language], [a:firstline, a:lastline]))
    endfunction

    autocmd FileType c noremap <buffer> <c-f> :call UncrustifyWrapper('c')<CR>
    autocmd FileType c vnoremap <buffer> <c-f> :call RangeUncrustifyWrapper('c')<CR>
    autocmd FileType cpp noremap <buffer> <c-f> :call UncrustifyWrapper('cpp')<CR>
    autocmd FileType cpp vnoremap <buffer> <c-f> :call RangeUncrustifyWrapper('cpp')<CR>
endif

" =============================================================================
" YouCompleteMe
" =============================================================================
if has_key(g:plugs, 'YouCompleteMe')
    let g:ycm_key_list_select_completion  = ['<Tab>', '<Down>']
    let g:ycm_key_list_previous_completion  = ['<S-Tab>', '<Up>']
    let g:ycm_key_list_stop_completion = ['<Enter>']
    let g:ycm_key_invoke_completion = '<C-Space>'
    let g:ycm_add_preview_to_completeopt = 1
    let g:ycm_error_symbol = 'E>'
    let g:ycm_warning_symbol = 'W>'
    let g:ycm_complete_in_comments = 1
    let g:ycm_min_num_of_chars_for_completion = 2
    let g:ycm_echo_current_diagnostic = 1
    let g:ycm_always_populate_location_list = 1
    let g:ycm_use_ultisnips_completer = 1
    set completeopt-=preview
endif

" =============================================================================
" SuperTab
" =============================================================================
if has_key(g:plugs, 'supertab')
    " inoremap <C-n> <Plug>SuperTabForward
    " inoremap <C-r> <Plug>SuperTabBackward
    let g:SuperTabCrMapping = 1

    " Up & down mapping
    " inoremap <expr> <c-r> ((pumvisible()) ? ("\<c-n>") : ("\<c-n>"))
    " inoremap <expr> <c-n> ((pumvisible()) ? ("\<c-p>") : ("\<c-r>"))

    " To map <s-tab> to the real tab:
    runtime! plugin/supertab.vim
    inoremap <s-tab> <tab>
endif

" =============================================================================
" UltiSnips
" =============================================================================
if has_key(g:plugs, 'ultisnips')
    let g:UltiSnipsExpandTrigger = "<c-z>"
    let g:UltiSnipsJumpForwardTrigger = "<c-z>"
    let g:UltiSnipsJumpBackwardTrigger = "<c-y>"
    let g:UltiSnipsListSnippets = "<c-tab>"
    if has("win32") || has("win16")
        let g:UltiSnipsSnippetsDir = $HOME . '/vimfiles/bundle/vim-misc/UltiSnips'
    else
        let g:UltiSnipsSnippetsDir = $HOME . '/.vim/bundle/vim-misc/UltiSnips'
    endif
    let g:UltiSnipsSnippetDirectories = ['UltiSnips']
    let g:UltiSnipsEditSplit = "vertical"
endif

" =============================================================================
" NumberToggle config
" =============================================================================
if has_key(g:plugs, 'vim-numbertoggle')
    set relativenumber
    let g:NumberToggleTrigger = "<C-o>"
endif

" =============================================================================
" FastFold
" =============================================================================
let g:fastfold_fold_command_suffixes = []

" =============================================================================
" LeaderF
" =============================================================================
let g:Lf_ShortcutF = '<Leader>o'
nnoremap <Leader>o :LeaderfFile<CR>
nnoremap <Leader>b :LeaderfBuffer<CR>
nnoremap <Leader>z :LeaderfMruCwd<CR>
nnoremap <Leader>f :LeaderfBufTag<CR>
nnoremap <Leader>v :LeaderfTag<CR>
let g:Lf_UseVersionControlTool = 0
let g:Lf_ShowRelativePath = 1
let g:Lf_PreviewCode = 0
let g:Lf_WindowHeight = 0.2
let g:Lf_StlSeparator = {
    \ 'left': '',
    \ 'right': ''
    \ }
let g:Lf_WildIgnore = {
    \ 'dir': ['.svn','.git','.p4','.perforce','.plastic','node_modules','temp','Temp','out','_out','_build','extern'],
    \ 'file': ['*.sw?','~$*','*.bak','*.exe','*.o','*.so','*.pyco','*.dll','*.meta','AssemblyU2DCSharp*','*.a','*.lib']
    \ }
let g:Lf_CommandMap = {
    \ '<C-R>': ['<C-E>'],
    \ '<Down>': ['<C-N>'],
    \ '<Up>': ['<C-R>'],
    \ '<C-C>': ['<ESC>'],
    \ '<C-X>': ['<C-T>'],
    \ '<C-]>': ['<C-I>'],
    \ '<C-T>': ['<C-X>'],
    \ '<C-L>': ['<C-D>'],
    \ '<F5>': ['<C-Z>']
    \ }
let g:Lf_RootMarkers = ['.git', '.hg', '.svn', '.depotroot', '.projroot', '.p4', '.perforce', '.plastic']

" =============================================================================
" Vim Grep
" =============================================================================
nnoremap <Leader>ag :Grepper<CR>
nmap gs <plug>(GrepperOperator)
xmap gs <plug>(GrepperOperator)
nmap g* gsiw
xmap g* gsiw
let g:grepper = {
    \ 'tools': ['rg', 'ag', 'git', 'grep'],
    \ 'open': 1,
    \ 'jump': 0,
    \ }

" Fix Grepper's quickfix window
augroup quickfix
    autocmd!
    autocmd FileType qf setlocal nowrap
    autocmd FileType qf setlocal norelativenumber
    autocmd FileType qf setlocal nonumber
    autocmd FileType qf setlocal scrolloff=0
    autocmd FileType qf set nobuflisted
    autocmd FileType qf nnoremap <buffer> q :cclose<CR>
augroup END

" Improve Quickfix through QFEnter
let g:qfenter_open_map = ['<CR>']
let g:qfenter_vopen_map = ['i']
let g:qfenter_hopen_map = ['t']
let g:qfenter_topen_map = ['<Tab>']
let g:qfenter_keep_quickfixfocus = {
            \ 'open': 0,
            \ 'cnext': 0,
            \ 'cprev': 0,
            \ }
nnoremap <Leader>qf :copen<CR>

" =============================================================================
" Gutentags
" =============================================================================
if has_key(g:plugs, 'vim-gutentags')
    set statusline+=%{gutentags#statusline('[Generating...]')}
    function! GenTags()
    :   w
    :   GutentagsUpdate
    :   redraw!
    endfunction
    function! GenTagsAll()
    :   w
    :   GutentagsUpdate!
    :   redraw!
    endfunction
    command! -nargs=* GenTags call GenTags()
    command! -nargs=* GenTagsAll call GenTagsAll()

    let g:gutentags_project_root = [ '.git', '.svn', '.hg', '.p4', '.p4project', '.plastic', '.depotroot' ]
    "let g:gutentags_ctags_exclude_wildignore = [ '*.meta' ]
endif

" =============================================================================
" TagList
" =============================================================================
let g:Tlist_Inc_Winwidth=0
let g:Tlist_WinWidth=40
let g:Tlist_Use_Right_Window=1
let g:Tlist_Enable_Fold_Column=0
let g:Tlist_Compact_Format=1
let g:Tlist_Exit_OnlyWindow=1
let g:Tlist_GainFocus_On_ToggleOpen=1
let g:Tlist_File_Fold_Auto_Close=1
let g:Tlist_Process_File_Always=1
let g:tlist_c_settings = 'c;d:macro;f:function;g:enums;p:prototype;s:struct;t:typedef;x:external'
let g:tlist_cpp_settings = 'c++;d:macro;f:function;g:enums;p:prototype;s:struct;t:typedef;x:external'
autocmd FileType taglist set nonumber
autocmd FileType taglist set norelativenumber
autocmd FileType taglist nnoremap <buffer> <C-a> :TlistUpdate<CR>

" Show only current buffer?
" let g:Tlist_Show_One_File=1

" =============================================================================
" YankRing / YankStack
" =============================================================================
if has_key(g:plugs, 'YankRing.vim')
    " p for paste
    " <C-P> maps to next paste
    " <C-N> maps to previous paste
    nnoremap <Leader>y :YRShow<CR>
    let g:yankring_replace_n_pkey = '<C-H>'
    let g:yankring_replace_n_nkey = '<C-L>'
elseif has_key(g:plugs, 'vim-yankstack')
    let g:yankstack_yank_keys = ['y', 'd', 'c', 'yy', 'dd', 'cc', 'Y', 'D', 'C']
    nmap <Leader>p <Plug>yankstack_substitute_older_paste
    nmap <Leader>P <Plug>yankstack_substitute_newer_paste
    nnoremap <Leader>y :Yanks<CR>
endif

" =============================================================================
" EnhancedJumps
" =============================================================================
nmap <Leader>h  <Plug>EnhancedJumpsOlder
nmap <Leader>l  <Plug>EnhancedJumpsNewer
nmap <Leader>gh <Plug>EnhancedJumpsLocalOlder
nmap <Leader>gl <Plug>EnhancedJumpsLocalNewer

" =============================================================================
" MultipleCursor
" =============================================================================
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-g>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'
let g:multi_cursor_start_key='<C-g>'
nnoremap <silent> <C-j> :MultipleCursorsFind <C-R>/<CR>
vnoremap <silent> <C-j> :MultipleCursorsFind <C-R>/<CR>

" Disable youcompleteme while multiple cursors are active
function! Multiple_cursors_before()
    let g:yankring_record_enabled = 0
    if exists("*youcompleteme#DisableCursorMovedAutocommands")
        call youcompleteme#DisableCursorMovedAutocommands()
    endif
endfunction
function! Multiple_cursors_after()
    let g:yankring_record_enabled = 1
    if exists("*youcompleteme#EnableCursorMovedAutocommands")
        call youcompleteme#EnableCursorMovedAutocommands()
    endif
endfunction

" =============================================================================
" Vim Easy Align
" =============================================================================
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" =============================================================================
" Rainbow
" =============================================================================
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'guifgs': ['firebrick', 'seagreen3', 'darkorange3', 'yellow', 'magenta1'],
\   'ctermfgs': [9, 2, 4, 3, 5],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\   'separately': {
\       '*': {},
\       'tex': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
\       },
\       'lisp': {
\           'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
\       },
\       'vim': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
\       },
\       'html': {
\           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
\       },
\       'css': 0,
\   }
\}

" =============================================================================
" ALE
" =============================================================================
let g:ale_fixers = {
    \ 'typescript': ['tslint'],
    \ 'javascript': ['eslint'],
    \ }
let g:ale_linters = {
    \ 'typescript': ['tslint', 'tsserver', 'typecheck'],
    \ 'javascript': ['eslint'],
    \ }
noremap <C-j> :ALEFix<CR>
autocmd FileType typescript inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"
autocmd FileType typescript inoremap <expr><s-tab> pumvisible() ? "\<c-p>" : "\<s-tab>"

" Disable, we use deoplete.
let g:ale_completion_enabled = 0

