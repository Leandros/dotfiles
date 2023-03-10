set nocompatible " be iMproved, required
filetype off     " required

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
let js_dev_enabled = 1
let has_navigator = 0
let has_lspsaga = 1

" Vim Internal Plugins
if !has('nvim')
    packadd matchit
endif

" Python paths
if has('nvim')
    if has("win32") || has("win16")
        let g:python3_host_prog = 'C:\Python310\python.exe'
    else
        let g:python3_host_prog = '/usr/bin/python3'
    endif
endif

" Ugly workaround until vim fixes
if has('python3')
  silent! python3 1
endif

" Visual Plugins
if has('nvim') && !empty($NVIM_GUI)
    Plug 'frankier/neovim-colors-solarized-truecolor-only'
    Plug 'equalsraf/neovim-gui-shim'
elseif has('nvim')
    Plug 'ishan9299/nvim-solarized-lua'
else
    Plug 'altercation/vim-colors-solarized'
endif

" Absolute Must Haves!
Plug 'tpope/vim-commentary'
" Plug 'tpope/vim-repeat' " remaps <c-r>
Plug 'tpope/vim-surround'
Plug 'tpope/vim-speeddating'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'Konfekt/FastFold'
Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
Plug 'mhinz/vim-grepper'
" Plug 'ntpeters/vim-better-whitespace'
Plug 'maxbrunsfeld/vim-yankstack'
Plug 'scrooloose/nerdtree'
" Plug 'mbbill/undotree'

" General
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/vim-peekaboo'
" Required for 'EnhancedJumps'
Plug 'vim-scripts/ingo-library'
Plug 'vim-scripts/EnhancedJumps'
Plug 'MattesGroeger/vim-bookmarks'
Plug 'dhruvasagar/vim-zoom'
Plug 'shortcuts/no-neck-pain.nvim', { 'tag': '*' }

" My own plugins
Plug 'leandros/vim-misc'

" My forks
Plug 'leandros/QFEnter'
Plug 'leandros/vim-bufkill'

" Rust
if has('nvim')
    " Libraries
    Plug 'kyazdani42/nvim-web-devicons'
    Plug 'nvim-lua/plenary.nvim'               " Lua library
    Plug 'rcarriga/nvim-notify'                " Notification framework

    " Completion
    Plug 'hrsh7th/nvim-cmp'                    " Completion framework
    Plug 'hrsh7th/cmp-vsnip'                   " Snippet completion source for nvim-cmp
    Plug 'hrsh7th/cmp-path'                    " Completion for paths
    Plug 'hrsh7th/cmp-buffer'                  " Completion from buffer
    Plug 'hrsh7th/vim-vsnip'                   " Snippet engine
    " Plug 'hrsh7th/vim-vsnip-integ'             " Snippet integration with compe

    " Status/Tab Line
    Plug 'nvim-lualine/lualine.nvim'           " Statusline (bottom)
    Plug 'kdheepak/tabline.nvim'               " Tabline (top)

    " Treesitter
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

    " Misc
    Plug 'lewis6991/gitsigns.nvim'             " Showins git changes in the gutter
    Plug 'danymat/neogen'                      " Generating documentation comments
    Plug 'lukas-reineke/indent-blankline.nvim' " Showing indentation lines
    Plug 'kevinhwang91/nvim-bqf'               " Get preview in quickfix
    Plug 'windwp/nvim-autopairs'               " Automatically close braces
    Plug 'voldikss/vim-floaterm'               " Floating terminals. Spooky!
    Plug 'nvim-tree/nvim-tree.lua'

    " Telescope
    Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' } " Improved LSP actions
    Plug 'nvim-telescope/telescope-ui-select.nvim' " Use telescope as native vim select popup, required from NVIM v0.7.0
    Plug 'nvim-telescope/telescope-fzy-native.nvim'
    " Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
    " Plug 'leandros/telescope-fzf-native.nvim', { 'do': 'make', 'branch': 'feature/windows_build_support' }

    " Code navigation
    " Plug 'https://gitlab.com/madyanov/svart.nvim.git'
    Plug 'ggandor/leap.nvim'

    " LSP Requirements
    Plug 'neovim/nvim-lspconfig'               " Collection of common configurations for the Nvim LSP client
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'

    " LSP Tools
    Plug 'hrsh7th/cmp-nvim-lsp'                " LSP completion source for nvim-cmp
    Plug 'folke/lsp-colors.nvim'               " Highlight groups for trouble.nvim
    Plug 'folke/trouble.nvim'                  " Pretty diagnostics
    Plug 'nvim-lua/lsp-status.nvim'            " Plugin to show lsp status in statusline

    " LSP Language Plugins
    Plug 'simrat39/rust-tools.nvim'            " Improved LSP support for Rust
    Plug 'akinsho/flutter-tools.nvim'

    if has_navigator
        Plug 'ray-x/guihua.lua', {'do': 'cd lua/fzy && make' }
        Plug 'ray-x/navigator.lua'
    endif
    if has_lspsaga
        Plug 'tami5/lspsaga.nvim' " chose either lspsaga or navigator
    endif

    " Debugging
    Plug 'puremourning/vimspector'
    " Plug 'mfussenegger/nvim-dap' " debug adapter for debugging
    " Plug 'theHamsta/nvim-dap-virtual-text' " virtual text during debugging
    " Plug 'rcarriga/nvim-dap-ui' " for nvim-dap
endif

" Prettier
Plug 'Chiel92/vim-autoformat', { 'for': ['gn', 'jbuild', 'opam', 'python'] }
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install',
  \ 'for': ['javascript', 'javascript.jsx', 'typescript', 'typescript.tsx', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
Plug 'cofyc/vim-uncrustify', { 'for': ['cpp', 'c', 'cs', 'objc', 'objcpp'] }

" Syntax Plugins
Plug 'dummyunit/vim-fastbuild', { 'for': ['fastbuild'] }
Plug 'wlangstroth/vim-racket', { 'for': ['racket'] }
Plug 'luochen1990/rainbow', { 'for': ['scheme', 'lisp', 'racket'] }
Plug 'leandros/hlsl.vim', { 'for': ['hlsl'] }
Plug 'leandros/vim-gn', { 'for': ['gn'] }
Plug 'aexpl/vim-aexpl', { 'for': ['aexpl'] }
Plug 'jparise/vim-graphql', { 'for': ['graphql'] }
Plug 'qnighy/lalrpop.vim', { 'for': ['lalrpop'] }
Plug 'rust-lang/rust.vim', { 'for': ['rust'] }
Plug 'cespare/vim-toml', { 'for': ['toml'], 'branch': 'main' }
Plug 'NoahTheDuke/vim-just'
Plug 'jvirtanen/vim-hcl'
Plug 'towolf/vim-helm'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'alx741/vim-hindent'

if js_dev_enabled
    Plug 'leafgarland/typescript-vim'
    Plug 'pangloss/vim-javascript'
    Plug 'elzr/vim-json'
endif

call plug#end()

" required for remapping Y to y$
" has to come after plug#end()
if has_key(g:plugs, 'vim-yankstack')
    call yankstack#setup()
endif

" Update plugins and save snapshot
command UpdatePlugins
  \ PlugUpdate | PlugSnapshot! ~/github/dotfiles/plug.snapshot
command Snapshot
  \ PlugSnapshot! ~/github/dotfiles/plug.snapshot

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
set encoding=utf-8     " Set the default encodings just in case $LANG isn't set
set cursorline         " Hightlight current selected line.
set ttyfast            " Set that we have a fast terminal
set emoji              " enable emoji's on Vim8
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
set nowritebackup
set noswapfile

" Indentation is 4 spaces, and not a tab
set tabstop=4       " A tab is 4 spaces.
set softtabstop=0   " How tabs behave when editing
set autoindent      " Autoindent.
set copyindent      " Copy the previous indent on autoindenting.
set shiftwidth=4    " Number of spaces used for autoindent.
set expandtab       " Expand <Tab> into spaces
set smarttab        " Insert 'tabs' on start of line, according to shiftwidth instead of tabstop.
set scrolloff=3     " 3 lines of buffer above and below the cursor

" Don't automatically insert line breaks
set textwidth=0

" Set mapping and key timeouts
set timeout
set timeoutlen=1000 " timeout for leader key
set ttimeoutlen=10  " timeout for esc key
set updatetime=300  " 300ms of no cursor movement to trigger CursorHold

" Show if leader key is pressed
set showcmd
set cmdheight=2     " Give more space for displaying messages.
set laststatus=2

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
set sessionoptions+=tabpages,globals " store tabpages and globals in session

" Disable ZZ to close vim
nnoremap Z <Nop>
nnoremap ZZ <Nop>

" Disable netrw
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" Runtime path
set rtp+=/opt/homebrew/opt/fzf

" =============================================================================
" Performance
" =============================================================================
" Improve performance of matchparen plugin
" This is DISABLING it!
let g:loaded_matchparen = 1         " Don't show matching parens.
set noshowmatch                     " Don't show matching braces.
let g:matchparen_timeout = 2
let g:matchparen_insert_timeout = 2

" Syntax highlighting for lua in .vimrc
let g:vimsyn_embed = 'l'

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

" When running as diff.
if &diff
  set modifiable
  set noreadonly
  if tabpagenr('$') == 1
    nnoremap ZZ :wqall<cr>
  endif
endif

" C-I acting as Tab fix
if $TERM ==# 'screen-256color'
  autocmd UIEnter * if v:event.chan ==# 0 | call chansend(v:stderr, "\x1b[>1u") | endif
  autocmd UILeave * if v:event.chan ==# 0 | call chansend(v:stderr, "\x1b[<1u") | endif
endif

" Theme
if has('nvim')
    set termguicolors
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set background=dark
let g:solarized_italics = 0
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
au BufRead,BufNewFile *.jsx set ft=javascript.jsx               " Javascript
au BufRead,BufNewFile *.tsx set ft=typescript.tsx               " TypescriptX
au BufRead,BufNewFile *.ts set ft=typescript                    " Typescript
au BufRead,BufNewFile *.nomad set ft=hcl                        " HCL
au BufRead,BufNewFile *.tf set ft=hcl                           " HCL
au BufRead,BufNewFile *.hcl set ft=hcl                          " HCL
au BufRead,BufNewFile *.tfvars set ft=hcl                        " HCL

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
nnoremap <C-p> <C-W>w
nnoremap <C-n> <C-W>j
nnoremap <C-r> <C-W>k
nnoremap <C-b> <C-W>h
nnoremap <C-s> <C-W>l

" Split resizing
nnoremap ! :vertical resize -5<CR>
nnoremap = :vertical resize +5<CR>
nnoremap < :resize +5<CR>
nnoremap > :resize -5<CR>

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
" nnoremap <C-w> :bd<CR>

" Close / Open quickfix
nnoremap <Leader>qq :cclose<CR>
nnoremap <Leader>qc :cclose<CR>
nnoremap <Leader>qo :copen<CR>

" Map Y to y$, to behave like D and C
nnoremap Y y$

" Jump back in time
nnoremap <Leader>. <C-t>

" =============================================================================
" Tab navigation
" =============================================================================
nnoremap <C-u> :echo "nothing happened ..."<CR>
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

" Tab switching.
nnoremap <Leader>1 1gt
nnoremap <Leader>2 2gt
nnoremap <Leader>3 3gt
nnoremap <Leader>4 4gt
nnoremap <Leader>5 5gt
nnoremap <Leader>6 6gt
nnoremap <Leader>7 7gt
nnoremap <Leader>8 8gt
nnoremap <Leader>9 9gt

cabbrev tabv tab sview +setlocal\ nomodifiable

" =============================================================================
" Indent
" =============================================================================
" Set make
autocmd FileType typescript set makeprg=tsc\ $*
autocmd FileType typescript.tsx set makeprg=tsc\ $*

" Setup comment string
autocmd FileType javascript setlocal commentstring=/*\ %s\ */
autocmd FileType javascript.jsx setlocal commentstring=/*\ %s\ */
autocmd FileType typescript setlocal commentstring=/*\ %s\ */
autocmd FileType typescript.tsx setlocal commentstring=/*\ %s\ */
autocmd FileType lalrpop setlocal commentstring=//\ %s
autocmd FileType hcl setlocal commentstring=#\ %s

" Use Tabs in Makefiles
autocmd FileType make setlocal noexpandtab

" Use two space
" ts = tabstop
" sts = softtabstop (delete in pairs of N)
" sw = shiftwidth (shift in pairs of N)
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType gn setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType hcl setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType vim setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType helm setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType gn setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType javascript setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType javascript.jsx setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType typescript setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType typescript.tsx setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType haskell setlocal ts=2 sts=2 sw=2 expandtab

" Disable automatic line breaking
autocmd FileType helm setlocal tw=0

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
        set guifont=PragmataPro\ Mono:h9
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
   call s:RunShellCommand('clang++ -std=c++17 '.src.' -o '.exe.' && ./'.exe)
   exec 'Silent rm '.exe
endfunction
autocmd filetype cpp nnoremap <F5> :call CompileCC()<CR>
autocmd filetype cpp command! Run :call CompileCC()

" =============================================================================
" Make
" =============================================================================
function! RunMake(...)
   write
   echo 'make ' . join(a:000, ' ')
   call s:RunShellCommand('make '.join(a:000, ' '))
endfunction
command! -nargs=* Make :call RunMake(<f-args>)


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
" NEOVIM
" =============================================================================
if has('nvim')
    " Set completeopt to have a better completion experience
    " :help completeopt
    " menuone: popup even when there's only one match
    " noinsert: Do not insert text until a selection is made
    " noselect: Do not select, force user to select one from the menu
    set completeopt=menuone,noinsert,noselect

    " Avoid showing extra messages when using completion
    set shortmess+=c

" =============================================================================
" Completion
" =============================================================================
" Must come before LSP.
" See https://github.com/hrsh7th/nvim-cmp#basic-configuration
lua <<EOF
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
local cmp = require 'cmp'
cmp.setup({
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },

  -- Enable LSP snippets
  snippet = {
    expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
    end,
  },

  --formatting = {
  --  format = function (entry, vim_item)
  --    vim_item.dup = { buffer = 1, path = 1, nvim_lsp = 0 }
  --  end
  --},

  mapping = {
    ['<C-r>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    -- Add tab support
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<C-,>'] = cmp.mapping.scroll_docs(-4),
    ['<C-.>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-j>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = false,
    })
  },

  -- Installed sources
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
})

-- Set configuration for specific filetype.
cmp.setup.filetype('gitcommit', {
  sources = cmp.config.sources({
    -- { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
  }, {
    { name = 'buffer' },
  })
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- Doesn't work, for some reason
--cmp.event:on(
--  'confirm_done',
--  cmp_autopairs.on_confirm_done()
--)


EOF


" =============================================================================
" LSP INSTALLER
" =============================================================================
lua << EOF
require("mason").setup {
  ui = {
    border = 'rounded',
    icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
    }
  }
}

require('mason-lspconfig').setup {
  ensure_installed = {
    "rust_analyzer",
    "tsserver",
    "eslint",
    "gopls",
    "bashls",
    "sumneko_lua",
    "vimls",
    "yamlls",
    "jedi_language_server", -- python
    "pylsp", -- depends on the above
  },
}

local lspconfig = require('lspconfig')
local lsp_defaults = lspconfig.util.default_config
local lsp_status = require("lsp-status")

lsp_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lsp_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities(),
  lsp_status.capabilities
)

lsp_status.register_progress()


-- Global `on_attach`
local function on_attach(client, bufnr)
  -- setup buffer keymaps etc.
  lsp_status.on_attach(client)
end

-- Rust
local rust_tools = require("rust-tools")
-- local extension_path = 'C:/Users/leandros/bin/codelldb-x86_64-windows/extension/'
-- local codelldb_path = extension_path .. 'adapter/codelldb.exe'
-- local liblldb_path = extension_path .. 'lldb/lib/liblldb.lib'
local rust_opts = {
    tools = { -- rust-tools options
        autoSetHints = true,
        hover_with_actions = false,
        inlay_hints = {
            -- Only show inlay hints for the current line
            only_current_line = false,
            -- wheter to show parameter hints with the inlay hints or not
            show_parameter_hints = true,
            -- prefix for parameter hints
            parameter_hints_prefix = "<- ",
            -- prefix for all the other hints (type, chaining)
            other_hints_prefix = "=> ",
            -- whether to align to the length of the longest line in the file
            max_len_align = false,
            -- padding from the left if max_len_align is true
            max_len_align_padding = 1,
            -- whether to align to the extreme right or not
            right_align = false,
            -- The color of the hints
            highlight = "Comment",
        },
        runnables = {
            use_telescope = true,
        },
        debuggables = {
            use_telescope = true,
        },
    },
    -- dap = {
    --     adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path)
    -- },
    server = {
      on_attach = on_attach,
      --capabilities = capabilities,
      flags = { allow_incremental_sync = false },
      settings = {
        ["rust-analyzer"] = {
            assist = {
                importGranularity = "module",
                importPrefix = "by_self",
            },
            cargo = {
                loadOutDirsFromCheck = true,
            },
            procMacro = {
                enable = true
            },
            checkOnSave = {
                command = "clippy"
            },
        }
      }
    },
}
rust_tools.setup(rust_opts)

-- Flutter/Dart
require("flutter-tools").setup{
  lsp = {
    on_attach = on_attach,
  },
}

-- Remaining servers
for _, server in ipairs { "tsserver", "eslint", "gopls", "bashls", "sumneko_lua", "vimls", "yamlls", "jedi_language_server", "pylsp" } do
  lspconfig[server].setup {
    on_attach = on_attach,
    --capabilities = capabilities,
  }
end

EOF

lua <<EOF
vim.g.diagnostics_active = true
function _G.toggle_diagnostics()
  if vim.g.diagnostics_active then
    vim.g.diagnostics_active = false
    vim.diagnostic.reset()
    vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
  else
    vim.g.diagnostics_active = true
    vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
      vim.lsp.diagnostic.on_publish_diagnostics, {
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
      }
    )
  end
end

vim.api.nvim_set_keymap('n', '<leader>td', ':call v:lua.toggle_diagnostics()<CR>',  {noremap = true, silent = true})
EOF

function Refresh()
    lua vim.lsp.stop_client(vim.lsp.get_active_clients())
    sleep 500m
    edit
endfunction
command RefreshLSP call Refresh()

" =============================================================================
" Debugging
" =============================================================================
let g:vimspector_enable_mappings = 'HUMAN'
let g:vimspector_install_gadgets = [ 'CodeLLDB' ]

nmap <leader>bl :call vimspector#Launch()<CR>
nmap <leader>bq :VimspectorReset<CR>
nmap <leader>bz <Plug>VimpectorRestart
nmap <leader>bc <Plug>VimspectorContinue
nmap <leader>bd <Plug>VimspectorStop
nmap <leader>bt <Plug>VimspectorRunToCursor
nmap <leader>bn <Plug>VimspectorStepOver
nmap <leader>bsi <Plug>VimspectorStepInto
nmap <leader>bso <Plug>VimspectorStepOut
nmap <leader>br <Plug>VimspectorToggleBreakpoint
nmap <leader>be :VimspectorEval
nmap <leader>bw :VimspectorWatch
nmap <leader>bo :VimspectorShowOutput
nmap <leader>bi <Plug>VimspectorBalloonEval
xmap <leader>bi <Plug>VimspectorBalloonEval

" =============================================================================
" TROUBLE
" =============================================================================
lua << EOF
  require("trouble").setup {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
EOF

" =============================================================================
" LSPCOLORS
" =============================================================================
lua << EOF
require("lsp-colors").setup({
  Error = "#db4b4b",
  Warning = "#e0af68",
  Information = "#0db9d7",
  Hint = "#10B981"
})
EOF

" =============================================================================
" LUALINE
" =============================================================================
lua << EOF
local lsp_status = require('lsp-status')
lsp_status.config({
    --component_separator = ' │ ',
    status_symbol = '',
    indicator_errors = 'E',
    indicator_warnings = 'W',
    indicator_info = 'i',
    indicator_hint = '?',
    indicator_ok = '',
})

local colors = {
  base03  =  '#002b36',
  base02  =  '#073642',
  base01  =  '#586e75',
  base00  =  '#657b83',
  base0   =  '#839496',
  base1   =  '#93a1a1',
  base2   =  '#eee8d5',
  base3   =  '#fdf6e3',
  yellow  =  '#b58900',
  orange  =  '#cb4b16',
  red     =  '#dc322f',
  magenta =  '#d33682',
  violet  =  '#6c71c4',
  blue    =  '#268bd2',
  cyan    =  '#2aa198',
  green   =  '#859900',
}
local custom_solarized_dark = {
  normal = {
    a = { fg = colors.base03, bg = colors.blue, gui = 'bold' },
    b = { fg = colors.base0, bg = colors.base03 },
    c = { fg = colors.base0, bg = colors.base02 },
  },
  insert = { a = { fg = colors.base03, bg = colors.green, gui = 'bold' } },
  visual = { a = { fg = colors.base03, bg = colors.magenta, gui = 'bold' } },
  replace = { a = { fg = colors.base03, bg = colors.red, gui = 'bold' } },
  inactive = {
    a = { fg = colors.base0, bg = colors.base02, gui = 'bold' },
    b = { fg = colors.base03, bg = colors.base00 },
    c = { fg = colors.base01, bg = colors.base02 },
  },
}
require'lualine'.setup {
  options = {
    icons_enabled = false,
    theme = custom_solarized_dark,
    component_separators = '│',
    section_separators = '',
    disabled_filetypes = {},
    always_divide_middle = true,
  },
  sections = {
    lualine_b = {'branch', {'diagnostics', sources={'nvim_diagnostic', 'coc'}}},
    lualine_c = {{'filename', file_status = true, path = 1}},
    lualine_x = {"vim.fn['zoom#statusline']()", "require'lsp-status'.status()"},
    lualine_y = {},
  },
}
EOF

" =============================================================================
" TABLINE
" =============================================================================
" Should be below lualine.

lua <<EOF
require'tabline'.setup {
    -- Defaults configuration options
    enable = true,
    options = {
        max_bufferline_percent = 66, -- set to nil by default, and it uses vim.o.columns * 2/3
        show_tabs_always = false, -- this shows tabs only when there are more than one tab or if the first tab is named
        show_devicons = true, -- this shows devicons in buffer section
        show_bufnr = false, -- this appends [bufnr] to buffer section,
        show_filename_only = true, -- shows base filename only instead of relative path in filename
        modified_icon = "+ ", -- change the default modified icon
        modified_italic = false, -- set to true by default; this determines whether the filename turns italic if modified
    }
}
EOF


" =============================================================================
" Navigator
" =============================================================================
lua <<EOF
if not vim.g['has_navigator'] then
    return
end

--[[
require'navigator'.setup({
    border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"},
    transparency = nil,
    default_mapping = false,
    on_attach = function(client, bufnr)
        print("navigator on_attach")
    end,
    keymaps = {
        -- Keymaps defined below:
        -- {mode = "i", key = "<c-k>", func = "signature_help({border = single})"},
        -- {key = "<c-]>", func = "require('navigator.definition').definition()"},
        -- {key = "gd", func = "require('navigator.definition').definition_preview()"},
        -- {key = "K", func = "hover({ popup_opts = { border = single, max_width = 80 }})"},
        -- {key = "<Leader>re", func = "rename()"},
        -- {key = "<Leader>rn", func = "require('navigator.rename').rename()"},
        -- --{key = "<Leader>gi", func = "incoming_calls()"},
        -- --{key = "<Leader>go", func = "outgoing_calls()"},
        -- {key = "<Leader>k", func = "require('navigator.diagnostics').show_diagnostics()"},

        -- =========
        -- Enabled in telescope.nvim:
        -- =========

        --{key = "gr", func = "require('navigator.reference').reference()"},
        --{key = "<Leader>ca", mode = "n", func = "require('navigator.codeAction').code_action()"},
        --{key = "<Leader>cA", mode = "v", func = "range_code_action()"},

        -- =========
        -- Unused:
        -- =========

        --{mode = "i", key = "<leader>s", func = "signature_help()"},
        --{key = "g0", func = "require('navigator.symbols').document_symbols()"},
        --{key = "gW", func = "workspace_symbol()"},
        --{key = "gD", func = "declaration({ border = 'rounded', max_width = 80 })"},
        --{key = "gT", func = "require('navigator.treesitter').buf_ts()"},
        --{key = "<Leader>gT", func = "require('navigator.treesitter').bufs_ts()"},
        --{key = "gi", func = "implementation()"},
        --{key = "<Leader>d", func = "type_definition()"},
        --{key = "gG", func = "require('navigator.diagnostics').show_buf_diagnostics()"},
        --{key = "<Leader>dt", func = "require('navigator.diagnostics').toggle_diagnostics()"},
        --{key = "]d", func = "diagnostic.goto_next({ border = 'rounded', max_width = 80})"},
        --{key = "[d", func = "diagnostic.goto_prev({ border = 'rounded', max_width = 80})"},
        --{key = "]r", func = "require('navigator.treesitter').goto_next_usage()"},
        --{key = "[r", func = "require('navigator.treesitter').goto_previous_usage()"},
        --{key = "<C-LeftMouse>", func = "definition()"},
        --{key = "g<LeftMouse>", func = "implementation()"},
        --{key = "<Leader>k", func = "require('navigator.dochighlight').hi_symbol()"},
        --{key = '<Space>wa', func = 'add_workspace_folder()'},
        --{key = '<Space>wr', func = 'remove_workspace_folder()'},
        --{key = '<Space>ff', func = 'formatting()', mode='n'},
        --{key = '<Space>ff', func = 'range_formatting()', mode='v'},
        --{key = '<Space>wl', func = 'print(vim.inspect(vim.lsp.buf.list_workspace_folders()))'},
        --{key = "<Space>la", mode = "n", func = "require('navigator.codelens').run_action()"},
    },

    icons = {
        icons = true, -- set to false to use system default (if you using a terminal does not have nerd/icon)
        -- Code action
        code_action_icon = '⚐ ',
        -- code lens
        code_lens_action_icon = '',

        -- Diagnostics
        diagnostic_head = ' ⚠ ',
        diagnostic_err = 'E',
        diagnostic_warn = 'W',
        diagnostic_info = 'I',
        diagnostic_hint = 'H',

        diagnostic_head_severity_1 = ' ⚠ ',
        diagnostic_head_severity_2 = ' ⚠ ',
        diagnostic_head_severity_3 = ' ⚠ ',
        diagnostic_head_description = ' ⚠ ',
        diagnostic_virtual_text = '▷',
        diagnostic_file = ' ⚠ ',

        -- Values
        value_changed = '',
        value_definition = '',

        -- Treesitter
        match_kinds = {
            ['function'] = 'f',
            var = 'v',
            method = 'm',
            parameter = 'p',
            associated = '',
            namespace = 'n',
            type = 't',
            field = '',
        },
        treesitter_defult = '',
    },

    lsp_installer = false,
    lsp = {
        code_action = {enable = true, sign = true, sign_priority = 40, virtual_text = false},
        code_lens_action = {enable = true, sign = true, sign_priority = 40, virtual_text = false},
        format_on_save = false,
    },
})
]]--
EOF


" =============================================================================
" LSPSAGA
" =============================================================================
lua <<EOF
if not vim.g['has_lspsaga'] then
    return
end

local saga = require 'lspsaga'
saga.init_lsp_saga {
    use_saga_diagnostic_sign = true,
    -- diagnostic signs
    error_sign = 'E',
    warn_sign = 'W',
    hint_sign = 'H',
    infor_sign = 'I',
    diagnostic_header_icon = ' ⚠ ',
    -- code action title icon
    code_action_icon = '⚐ ',
    code_action_prompt = {
      enable = true,
      sign = false,
      sign_priority = 40,
      virtual_text = true,
    },
    finder_definition_icon = '⚡',
    finder_reference_icon = '⚡',
    max_preview_lines = 10,
    finder_action_keys = {
      open = 'o', vsplit = 'i',split = 't',quit = 'q',
      scroll_down = '<C-f>',scroll_up = '<C-b>'
    },
    code_action_keys = {
      quit = 'q',exec = '<CR>'
    },
    rename_action_keys = {
      quit = '<C-c>',exec = '<CR>'
    },
    definition_preview_icon = '➤',
    border_style = "single",
    rename_prompt_prefix = '➤',
    server_filetype_map = {}
}
EOF

if has_navigator
    inoremap <silent><c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
    nnoremap <silent><c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
    nnoremap <silent><c-]> <cmd>lua require('navigator.definition').definition()<CR>
    nnoremap <silent>gd <cmd>lua require('navigator.definition').definition_preview()<CR>
    nnoremap <silent>K <cmd>lua vim.lsp.buf.hover({ popup_opts = { border = single, max_width = 80 }})<CR>
    nnoremap <silent><Leader>re <cmd>lua vim.lsp.buf.rename()<CR>
    nnoremap <silent><Leader>rn <cmd>lua require('navigator.rename').rename()<CR>
    nnoremap <silent><Leader>k <cmd>lua require('navigator.diagnostics').show_diagnostics()<CR>
elseif has_lspsaga
    inoremap <silent><c-k> <cmd>:Lspsaga signature_help<CR>
    nnoremap <silent><c-k> <cmd>:Lspsaga signature_help<CR>
    nnoremap <silent>gd <cmd>:Lspsaga preview_definition<CR>
    nnoremap <silent>K <cmd>:Lspsaga hover_doc<CR>
    nnoremap <silent><Leader>re <cmd>lua vim.lsp.buf.rename()<CR>
    nnoremap <silent><Leader>rn <cmd>:Lspsaga rename<CR>
    nnoremap <silent><Leader>k <cmd>lua require'lspsaga.diagnostic'.show_cursor_diagnostics()<CR>
    nnoremap <silent> <S-h> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>
    nnoremap <silent> <S-l> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>
    nnoremap <silent> [e :Lspsaga diagnostic_jump_next<CR>
    nnoremap <silent> ]e :Lspsaga diagnostic_jump_prev<CR>
endif


" =============================================================================
" GitSigns
" =============================================================================
lua << EOF
require('gitsigns').setup({
  signs = {
    add          = { text = '│' },
    change       = { text = '│' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  keymaps = {
    noremap = true,

    ['n <leader>ss'] = '<cmd>Gitsigns stage_hunk<CR>',
    ['v <leader>ss'] = ':Gitsigns stage_hunk<CR>',
    ['n <leader>su'] = '<cmd>Gitsigns undo_stage_hunk<CR>',
    ['n <leader>sr'] = '<cmd>Gitsigns reset_hunk<CR>',
    ['v <leader>sr'] = ':Gitsigns reset_hunk<CR>',
    ['n <leader>sR'] = '<cmd>Gitsigns reset_buffer<CR>',
    ['n <leader>sp'] = '<cmd>Gitsigns preview_hunk<CR>',
    ['n <leader>sb'] = '<cmd>lua require"gitsigns".blame_line{full=true}<CR>',
    ['n <leader>sS'] = '<cmd>Gitsigns stage_buffer<CR>',
    ['n <leader>sU'] = '<cmd>Gitsigns reset_buffer_index<CR>',
  },
})
EOF

" =============================================================================
" Treesitter
" =============================================================================

lua <<EOF
require'nvim-treesitter.configs'.setup {
    ensure_installed = {'rust', 'json', 'javascript', 'typescript', 'tsx', 'vim', 'lua', 'go', 'haskell', 'bash'},
    highlight = {
        enable = true,
        disable = { "rust", "typescript" },
        additional_vim_regex_highlighting = false,
        custom_captures = {
            ["punctuation.bracket"] = "Variable",
            ["punctuation.delimiter"] = "Variable",
            ["include"] = "Keyword",
            ["keyword.function"] = "Keyword",
        },
    },
}
EOF

" =============================================================================
" svart
" =============================================================================
" lua <<EOF
" vim.keymap.set({ "n", "x", "o" }, "t", "<Cmd>Svart<CR>")

" local svart = require("svart")

" svart.configure({
"     key_cancel = "<Esc>",       -- cancel search
"     key_delete_char = "<BS>",   -- delete query char
"     key_delete_word = "<C-W>",  -- delete query word
"     key_delete_query = "<C-U>", -- delete whole query
"     key_best_match = "<CR>",    -- jump to the best match
"     key_next_match = "<C-N>",   -- select next match
"     key_prev_match = "<C-P>",   -- select prev match

"     label_atoms = "jfkdlsahgnuvrbytmiceoxwpqz", -- allowed label chars
"     label_location = 1,                        -- label location relative to the match
"                                                 -- positive: relative to the start of the match
"                                                 -- 0 or negative: relative to the end of the match
"     label_max_len = 2,                          -- max label length
"     label_min_query_len = 1,                    -- min query length required to show labels
"     label_hide_irrelevant = true,               -- hide irrelevant labels after start typing label to go to
"     label_conflict_foresight = 2,               -- number of chars from the start of the match to discard from labels pool

"     search_update_register = false, -- update search (/) register with last used query after accepting match
"     search_wrap_around = true,     -- wrap around when navigating to next/prev match
"     search_multi_window = true,    -- search in multiple windows

"     ui_dim_content = true, -- dim buffer content during search
" })
" EOF

" hi! SvartMatch ctermfg=92 guifg=#586e75

lua <<EOF
require('leap').setup {
  case_sensitive = false,
  safe_labels = {
    "t", "f", "u", "t", "/",
    "T", "F", "L", "H", "M", "U", "G", "?", "Z"
  },
}

-- Greying out the search
vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })

vim.keymap.set({"n", "x", "o"}, "t", "<cmd>lua require('leap').leap { target_windows = { vim.fn.win_getid() } }<CR>", {silent = true})
--vim.keymap.set({"n", "x", "o"}, "t", "<Plug>(leap-forward-to)", {silent = true})
--vim.keymap.set({"n", "x", "o"}, "T", "<Plug>(leap-backward-to)", {silent = true})
vim.keymap.set({"n", "x", "o"}, "gt", "<Plug>(leap-cross-window)", {silent = true})

EOF

" =============================================================================
" Signcolumn
" =============================================================================

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("nvim-0.5.0") || has("patch-8.1.1564")
    " Recently vim can merge signcolumn and number column into one
    set signcolumn=number
else
    set signcolumn=yes
endif

" Code navigation shortcuts
nnoremap <silent> <leader>d <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> <leader>i <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <leader>y <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> <leader>rr <cmd>lua vim.lsp.buf.references()<CR>

" Show diagnostic popup on cursor hold
" autocmd CursorHold * lua require'lspsaga.diagnostic'.show_line_diagnostics()
" autocmd CursorHold * lua require('navigator.diagnostics').show_diagnostics()
" au CursorHold * lua vim.diagnostic.open_float(0,{scope = "cursor"})

" Disable virtual text for diagnostics.
lua <<EOF
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false, }
)
vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    float = { border = "single" },
})
EOF

" =============================================================================
" Indent Blankline
" =============================================================================

lua << EOF
require("indent_blankline").setup {
    show_end_of_line = false,
    show_first_indent_level = false,
    filetype = {'yaml', 'rust', 'helm'},
    filetype_exclude = {'help'},
    buftype_exclude = {'terminal'},
    --show_current_context = true,
    --show_current_context_start = true,
}
EOF

" =============================================================================
" Neogen
" =============================================================================
lua <<EOF
require('neogen').setup {
    enabled = true
}
EOF

nnoremap <Leader>ng <cmd>lua require('neogen').generate()<cr>
nnoremap <Leader>nf <cmd>lua require('neogen').generate({ type = "file" })<cr>
nnoremap <Leader>nc <cmd>lua require('neogen').generate({ type = "class" })<cr>


" =============================================================================
" Auto Pairs
" =============================================================================

lua <<EOF
require('nvim-autopairs').setup({
  disable_filetype = { "TelescopePrompt" , "vim" },
})
EOF

endif " if has(nvim)


" =============================================================================
" Vim Better Whitespace
" =============================================================================
let g:better_whitespace_enabled=1
let g:strip_whitespace_on_save=1
let g:strip_only_modified_lines=1
let g:strip_whitespace_confirm=0


" =============================================================================
" UndoTree
" =============================================================================
nnoremap <F9> :UndotreeToggle<CR>

" Write undo tree to a file to resume from next time the file is opened.
if has("persistent_undo")
  set undolevels=2000            " The number of undo items to remember
  set undofile                   " Save undo history to files locally
  set undodir=$HOME/.vimundo     " Set the directory of the undofile
  if !isdirectory(expand(&undodir))
    call mkdir(expand(&undodir), "p")
  endif
endif

lua <<EOF
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  --remove_keymaps = true, -- remove all default mapping
  view = {
    adaptive_size = true,
    mappings = {
      list = {
        { key = { "C" }, action = "cd" },
        { key = { "<C-a>" }, action = "refresh" },
        { key = { "R" }, action = "rename" },
        { key = { "u" }, action = "dir_up" },
        { key = { "a" }, action = "create" },
        { key = { "r" }, action = "" },
        { key = { "e" }, action = "" },
        { key = { "-" }, action = "" },
        --{ key = { "<CR>", "o" }, action = "edit", mode = "n" },
        --{ key = { "n" }, action = "next_sibling", mode = "n" },
      },
    },
  },
  renderer = {
    group_empty = true,
    add_trailing = true,
    root_folder_label = ":~:s?$?/..?",
    indent_width = 2,
  },
  filters = {
    dotfiles = false,
  },
  actions = {
    open_file = {
      quit_on_open = true,
    },
    change_dir = {
      global = true,
    },
  },
})
EOF

map <Leader>e :NvimTreeToggle<CR>

" =============================================================================
" ReMap NERDTree Keys.
" =============================================================================
" let g:NERDTreeMapRefresh='<C-a>'
" let g:NERDTreeMapRefreshRoot='<C-u>'
" let g:NERDTreeMapOpenSplit='t'
" let g:NERDTreeMapOpenVSplit='i'
" let g:NERDTreeMenuDown='n'
" let g:NERDTreeMenuUp='r'

" let g:NERDTreeMapChdir='C'
" let g:NERDTreeMapUpdir='u'
" " let g:NERDTreeMapActivateNode='<CR>'
" " let NERDTreeMapNextSibling='N'
" " let NERDTreeMapPrevSibling='R'

" " Custom bindings
" augroup nerdtreebuf
"     autocmd!
"     autocmd FileType nerdtree nnoremap <buffer> <silent> <CR> :call nerdtree#ui_glue#invokeKeyMap("o")<CR>
" augroup END

" " Open NERDTree
" map <Leader>e :NERDTreeToggle<CR>

" " NERDTree options
" let g:NERDTreeChDirMode = 2
" let g:NERDTreeShowHidden = 1
" let g:NERDTreeQuitOnOpen = 1
" let g:NERDTreeMinimalUI = 1
" let g:NERDTreeAutoDeleteBuffer = 1
" let g:NERDTreeShowLineNumbers = 0
" let g:NERDTreeIgnore = ['\.meta$','^\.DS_Store$']

" " Open NERDTree when no files specified.
" " autocmd StdinReadPre * let s:std_in=1
" " autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" " Close VIM if only tab left is NERDTree
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" " Hide Line Numbers
" augroup nerdtree
"     autocmd!
"     autocmd FileType nerdtree set nonumber
"     autocmd FileType nerdtree set norelativenumber
" augroup END

" " NERDTress File highlighting
" function! NERDTreeHighlightFile(extension, regex, fg, bg, guifg, guibg)
"  exec 'autocmd filetype nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
"  exec 'autocmd filetype nerdtree syn match ' . a:extension .' #^.*\('. a:regex .'\)$#'
" endfunction

" " source files
" " Fixing NeoVim color theme regression neovim/neovim#9019
" highlight NERDTreeFile ctermfg=14
" " C
" call NERDTreeHighlightFile('cfile', '\.c',          '11', 'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('cheader', '\.h',        '9',  'NONE', 'NONE', 'NONE')
" " C++
" call NERDTreeHighlightFile('cc', '\.cc',            '5',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('hh', '\.hh',            '9',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('cpp', '\.cpp',          '5',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('hpp', '\.hpp',          '9',  'NONE', 'NONE', 'NONE')
" " Objective-C
" call NERDTreeHighlightFile('mm', '\.mm',            '4',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('m', '\.m',              '4',  'NONE', 'NONE', 'NONE')
" " shell scripts
" call NERDTreeHighlightFile('sh', '\.sh',            '2',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('bash', '\.bash',        '2',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('zsh', '\.zsh',          '2',  'NONE', 'NONE', 'NONE')
" " makefiles
" call NERDTreeHighlightFile('mk', '\.mk',            '28', 'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('makefile', '\makefile', '28', 'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('Makefile', '\Makefile', '28', 'NONE', 'NONE', 'NONE')
" " JavaScript
" call NERDTreeHighlightFile('js', '\.js',            '3',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('jsx', '\.jsx',          '3',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('ts', '\.ts',            '5',  'NONE', 'NONE', 'NONE')
" call NERDTreeHighlightFile('tsx', '\.tsx',          '5',  'NONE', 'NONE', 'NONE')


" =============================================================================
" vim-autoformat Settings.
" =============================================================================
if has_key(g:plugs, 'vim-autoformat')
    autocmd! User vim-autoformat noremap <C-f> :Autoformat<CR>
    let g:formatdef_astyle_objc = '"astyle --mode=c"'
    " let g:formatdef_prettier_ts = '"yarn --silent prettier --parser=typescript --stdin"'
    " let g:formatdef_prettier_js = '"yarn --silent prettier --stdin"'
    let g:formatdef_gnformat = '"gn format --stdin"'
    let g:formatdef_ocpindent = '"ocp-indent"'
    let g:formatters_objc = ['astyle_objc']
    " let g:formatters_javascript = ['prettier_js']
    " let g:formatters_typescript = ['prettier_ts']
    let g:formatters_gn = ['gnformat']
    " let g:formatters_rust = ['rustfmt']
endif

" =============================================================================
" vim-prettier Settings.
" =============================================================================
if has_key(g:plugs, 'vim-prettier')
    autocmd! User vim-prettier noremap <C-f> :Prettier<CR>
    let g:prettier#config#trailing_comma = 'all'
    let g:prettier#config#arrow_parens = 'always'
    let g:prettier#config#bracket_spacing = 'true'
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
    autocmd FileType objc noremap <buffer> <c-f> :call UncrustifyWrapper('objc')<CR>
    autocmd FileType objc vnoremap <buffer> <c-f> :call RangeUncrustifyWrapper('objc')<CR>
    autocmd FileType objcpp noremap <buffer> <c-f> :call UncrustifyWrapper('objcpp')<CR>
    autocmd FileType objcpp vnoremap <buffer> <c-f> :call RangeUncrustifyWrapper('objcpp')<CR>
endif

" =============================================================================
" Vsnip
" =============================================================================

" Expand
imap <expr> <C-n>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-n>'
smap <expr> <C-n>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-n>'

" Expand or jump
imap <expr> <C-s>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-s>'
smap <expr> <C-s>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-s>'

" Jump forward or backward
" imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
" smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
" imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
" smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'

" If you want to use snippet for multiple filetypes, you can `g:vsnip_filetypes` for it.
let g:vsnip_filetypes = {}
let g:vsnip_filetypes.javascriptreact = ['javascript']
let g:vsnip_filetypes.typescriptreact = ['typescript']

" =============================================================================
" FastFold
" =============================================================================
let g:fastfold_fold_command_suffixes = []

" =============================================================================
" Telescope
" =============================================================================
lua << EOF
local actions = require 'telescope.actions'
require('telescope').setup {
  defaults = {
    -- Default configuration for telescope goes here:
    --disable_devicons = true,
    mappings = {
      i = {
        ["<esc>"] = actions.close,
        ["<C-n>"] = actions.move_selection_next,
        ["<C-r>"] = actions.move_selection_previous,
      },

      n = {
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
        ["n"] = actions.move_selection_next,
        ["r"] = actions.move_selection_previous,
        ["gg"] = actions.move_to_top,
        ["G"] = actions.move_to_bottom,
      }
    }
  },
  pickers = {
    find_files = {
      --theme = "dropdown",
      --disable_devicons = true,
    },
    live_grep = {
      --theme = "dropdown",
      --disable_devicons = true,
    },
    buffers = {
      --theme = "dropdown",
      --disable_devicons = true,
    },
    file_browser = {
      --disable_devicons = true,
    },
  },
  extensions = {
    --[[
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    },
    ]]--
    fzy_native = {
      override_generic_sorter = true,
      override_file_sorter = true,
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {
        -- even more opts
      }
    }
  }
}

-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
--require('telescope').load_extension('fzf')
require('telescope').load_extension('fzy_native')
require('telescope').load_extension('ui-select')
EOF

" Builtins
nnoremap <leader>fn <cmd>lua require('telescope.builtin').resume()<cr>

" Doubled with navigator:
nnoremap <leader>gr <cmd>lua require('telescope.builtin').lsp_references()<cr>
nnoremap <leader>gd <cmd>lua require('telescope.builtin').diagnostics()<cr>
nnoremap <leader>ca <cmd>lua vim.lsp.buf.code_action()<cr>
nnoremap <leader>cA <cmd>lua vim.lsp.buf.range_code_action()<cr>
nnoremap <leader>gi <cmd>lua require('telescope.builtin').lsp_implementations()<cr>
nnoremap <leader>gn <cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>
nnoremap <leader>ge <cmd>lua require('telescope.builtin').lsp_workspace_symbols()<cr>
nnoremap <leader>gt <cmd>lua require('telescope.builtin').lsp_type_definitions()<cr>

" Telescope.nvim:
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>fm <cmd>lua require('telescope.builtin').marks()<cr>
nnoremap <leader>fs <cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>

" LeaderF replacement:
" Previously: ff, fb, fz
" nnoremap <leader>o <cmd>lua require('telescope.builtin').find_files()<cr>
" nnoremap <leader>b <cmd>lua require('telescope.builtin').buffers()<cr>
" nnoremap <leader>z <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>v <cmd>lua require('telescope.builtin').treesitter()<cr>

" =============================================================================
" LeaderF
" =============================================================================
let g:Lf_ShortcutF = '<Leader>o'
nnoremap <Leader>o :LeaderfFile<CR>
nnoremap <Leader>bb :LeaderfBuffer<CR>
nnoremap <Leader>z :LeaderfMruCwd<CR>
let g:Lf_UseVersionControlTool = 0
let g:Lf_ShowRelativePath = 1
let g:Lf_PreviewCode = 0
let g:Lf_WindowHeight = 0.2
let g:Lf_ShowDevIcons = 0
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
    \ '<C-J>': ['<C-N>'],
    \ '<C-K>': ['<C-R>'],
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
" EnhancedJumps
" =============================================================================
nmap <Leader>h  <Plug>EnhancedJumpsOlder
nmap <Leader>l  <Plug>EnhancedJumpsNewer
nmap <Leader>gh <Plug>EnhancedJumpsLocalOlder
nmap <Leader>gl <Plug>EnhancedJumpsLocalNewer

" =============================================================================
" Vim Visual Multi (VM)
" =============================================================================

let g:VM_default_mappings = 0
let g:VM_mouse_mappings = 0
let g:VM_maps = {}

let g:VM_maps["Exit"]               = '<C-C>' " quit VM
let g:VM_maps["Find Under"]         = '<C-g>' " replace C-n
let g:VM_maps["Find Subword Under"] = '<C-g>' " replace visual C-n
let g:VM_maps["Toggle Mappings"]    = '<CR>'  " toggle VM buffer mappings
let g:VM_maps["Undo"]               = 'u'
let g:VM_maps["Redo"]               = 'j'

" let g:VM_maps["Reselect Last"]         = leader.'gS'
" let g:VM_maps["Add Cursor At Pos"]     = leader.'\'
" let g:VM_maps["Start Regex Search"]    = leader.'/'
" let g:VM_maps["Select All"]            = leader.'A'
let g:VM_maps["Add Cursor Down"]       = '<C-h>'
let g:VM_maps["Add Cursor Up"]         = '<C-l>'
" let g:VM_maps["Select l"]              = '<S-Right>'
" let g:VM_maps["Select h"]              = '<S-Left>'
" let g:VM_maps["Visual Regex"]          = visual.'/'
" let g:VM_maps["Visual All"]            = visual.'A'
" let g:VM_maps["Visual Add"]            = visual.'a'
" let g:VM_maps["Visual Find"]           = visual.'f'
" let g:VM_maps["Visual Cursors"]        = visual.'c'
let g:VM_maps["Find Next"] = 'h'
let g:VM_maps["Find Prev"] = 'l'
let g:VM_maps["Replace"]   = ''
let g:VM_maps["Motion h"]  = 'b'
let g:VM_maps["Motion j"]  = 'n'
let g:VM_maps["Motion k"]  = 'r'
let g:VM_maps["Motion l"]  = 's'


function! VM_Start()
  let g:yankring_record_enabled = 0
  if exists("AutoPairsToggle")
    call AutoPairsToggle()
  endif

  " Add mappings here if desired:
  " Example: nmap <buffer> b <Left>
endfunction

function! VM_Exit()
  let g:yankring_record_enabled = 1
  if exists("AutoPairsToggle")
    call AutoPairsToggle()
  endif

  " And unmap them again here:
  " Example: nunmap <buffer> b
endfunction


" =============================================================================
" Vim Easy Align
" =============================================================================
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" =============================================================================
" vim-bookmarks
" =============================================================================
" We disable default keybinding to create our own binding which is not active
" in NERDTree
let g:bookmark_no_default_key_mappings = 1

fun! SetVimBookmarkMappings()
    " Don't set mappings in nerdtree
    if &ft =~ 'nerdtree'
        return
    endif
    nnoremap <buffer> mm :BookmarkToggle<CR>
    nnoremap <buffer> mi :BookmarkAnnotate<CR>
    nnoremap <buffer> mn :BookmarkNext<CR>
    nnoremap <buffer> mr :BookmarkPrev<CR>
    nnoremap <buffer> ma :BookmarkShowAll<CR>
    nnoremap <buffer> md :BookmarkClear<CR>
    nnoremap <buffer> mx :BookmarkClearAll<CR>
    nnoremap <buffer> mh :BookmarkMoveUp<CR>
    nnoremap <buffer> ml :BookmarkMoveDown<CR>
    nnoremap <buffer> mg :BookmarkMoveToLine<CR>
endfun

fun! UnsetVimBookmarkMappings()
    silent! nunmap <buffer> mm
    silent! nunmap <buffer> mi
    silent! nunmap <buffer> mn
    silent! nunmap <buffer> mr
    silent! nunmap <buffer> ma
    silent! nunmap <buffer> md
    silent! nunmap <buffer> mx
    silent! nunmap <buffer> mh
    silent! nunmap <buffer> ml
    silent! nunmap <buffer> mg
endfun

au BufEnter * call SetVimBookmarkMappings()
autocmd FileType nerdtree call UnsetVimBookmarkMappings()

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
" vim-zoom
" =============================================================================
nmap <leader>,f <Plug>(zoom-toggle)

" =============================================================================
" no-neck-pain
" =============================================================================
nmap <leader>,n :NoNeckPain<CR>

lua <<EOF
require("no-neck-pain").setup({
  width = 100,
  -- Disables NNP if the last valid buffer in the list has been closed.
  disableOnLastBuffer = true,
  -- When `true`, disabling NNP kills every split/vsplit buffers except the main NNP buffer.
  killAllBuffersOnDisable = true,
})
EOF

" =============================================================================
" Floaterm
" =============================================================================
let g:floaterm_keymap_new    = ',n'
let g:floaterm_keymap_toggle = ',t'
let g:floaterm_keymap_prev   = ',b'
let g:floaterm_keymap_next   = ',s'
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8

" =============================================================================
" Colors
" =============================================================================
" hi! IndentBlanklineChar ctermfg=92 guifg=#586e75 gui=nocombine
" hi! IndentBlanklineSpaceChar ctermfg=92 guifg=#586e75 gui=nocombine

" Color was previously: #073642
hi! IndentBlanklineChar ctermfg=15 guifg=#234854 gui=nocombine
hi! IndentBlanklineSpaceChar ctermfg=15 guifg=#234854 gui=nocombine
hi! Comment cterm=NONE ctermfg=92 gui=NONE guifg=#586e75 guibg=NONE guisp=NONE
hi! Visual ctermbg=92 ctermfg=7 guibg=#586e75 guifg=#002b36 gui=nocombine guisp=none

" =============================================================================
" YAML
" =============================================================================
autocmd FileType yaml nnoremap <buffer> <C-f> :Prettier<CR>

" =============================================================================
" Rust
" =============================================================================
autocmd FileType rust nnoremap <buffer> <C-f> :RustFmt<CR>

" Must be after setting the color scheme.
" Pmenu:
" PmenuSel: selection
" GHListHl: Guihua List Highlight
" GHListDark: Guihui List
hi! Pmenu ctermfg=12 ctermbg=0 guifg=#839496 guibg=#073642 guisp=NONE
hi! FloatBorder ctermfg=1 guifg=#ffffff guibg=NONE guisp=NONE
hi! GHTextViewDark ctermfg=12 ctermbg=0 guifg=#93a1a1 guibg=#002b36 guisp=NONE
hi! NormalFloat ctermfg=12 ctermbg=7 guifg=#93a1a1 guibg=#002b36 guisp=NONE
" hi! PmenuSel ctermfg=12 ctermbg=7 guifg=#93a1a1 guibg=#002b36 guisp=none
" hi! PmenuThumb ctermfg=12 ctermbg=7 guifg=#93a1a1 guibg=#002b36 guisp=none
" hi! GHListHl ctermfg=12 ctermbg=7 guifg=#93a1a1 guibg=#002b36 guisp=none
" hi! GHListDark ctermfg=12 ctermbg=7 guifg=#93a1a1 guibg=#002b36 guisp=none
" hi! GHBgDark ctermfg=12 ctermbg=7 guifg=#93a1a1 guibg=#002b36 guisp=none

function! SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc


" =============================================================================
" Golang
" =============================================================================
autocmd FileType go nnoremap <buffer> <C-f> :GoFmt<CR>
let g:go_gopls_enabled = 0
let g:go_doc_keywordprg_enabled = 0
let g:go_metalinter_enabled = []
let g:go_metalinter_command = "golangci-lint"
let g:go_fmt_command = "golines"
let g:go_fmt_options = {
    \ 'golines': '-m 100',
    \ }
let g:go_fmt_autosave = 0
let g:go_imports_autosave = 0


" =============================================================================
" Haskell
" =============================================================================
autocmd FileType haskell nnoremap <buffer> <C-f> :Hindent<CR>
let g:hindent_on_save = 0
