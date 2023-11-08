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
        let g:python3_host_prog = 'python3'
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
Plug 'maxbrunsfeld/vim-yankstack'
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
    Plug 's1n7ax/nvim-window-picker', {'tag': 'v1.*'}

    " Completion
    Plug 'hrsh7th/nvim-cmp'                    " Completion framework
    Plug 'hrsh7th/cmp-vsnip'                   " Snippet completion source for nvim-cmp
    Plug 'hrsh7th/cmp-path'                    " Completion for paths
    Plug 'hrsh7th/cmp-buffer'                  " Completion from buffer
    Plug 'hrsh7th/cmp-cmdline'                 " Completion for :... commands
    Plug 'hrsh7th/vim-vsnip'                   " Snippet engine
    " Plug 'hrsh7th/vim-vsnip-integ'             " Snippet integration with compe

    " Status/Tab Line
    Plug 'nvim-lualine/lualine.nvim'           " Statusline (bottom)
    Plug 'kdheepak/tabline.nvim'               " Tabline (top)

    " Tabline
    Plug 'akinsho/bufferline.nvim', { 'tag': '*' }

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
    Plug 'johnfrankmorgan/whitespace.nvim'
    Plug 'tzachar/local-highlight.nvim'
    Plug 'f-person/auto-dark-mode.nvim'
    Plug 'sindrets/diffview.nvim'

    " Telescope
    Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' } " Improved LSP actions
    Plug 'nvim-telescope/telescope-live-grep-args.nvim'
    Plug 'nvim-telescope/telescope-ui-select.nvim' " Use telescope as native vim select popup, required from NVIM v0.7.0
    Plug 'nvim-telescope/telescope-fzy-native.nvim'
    " Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
    " Plug 'leandros/telescope-fzf-native.nvim', { 'do': 'make', 'branch': 'feature/windows_build_support' }

    " Docs
    " Must come after telescope.
    Plug 'amrbashir/nvim-docs-view', { 'on': 'DocsViewToggle'}

    " Code navigation
    " Plug 'ggandor/leap.nvim'
    Plug 'folke/flash.nvim'
    Plug 'folke/which-key.nvim'

    " LSP Requirements
    Plug 'neovim/nvim-lspconfig'               " Collection of common configurations for the Nvim LSP client
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'jose-elias-alvarez/null-ls.nvim'

    " LSP Tools
    Plug 'hrsh7th/cmp-nvim-lsp'                " LSP completion source for nvim-cmp
    Plug 'folke/lsp-colors.nvim'               " Highlight groups for trouble.nvim
    Plug 'folke/trouble.nvim'                  " Pretty diagnostics
    Plug 'nvim-lua/lsp-status.nvim'            " Plugin to show lsp status in statusline
    Plug 'rmagatti/goto-preview'               " Preview LSP definitions

    " navbuddy
    Plug 'SmiteshP/nvim-navic'
    Plug 'MunifTanjim/nui.nvim'
    Plug 'numToStr/Comment.nvim'               " Optional
    Plug 'SmiteshP/nvim-navbuddy'

    " LSP Language Plugins
    Plug 'simrat39/rust-tools.nvim'            " Improved LSP support for Rust
    Plug 'akinsho/flutter-tools.nvim'

    if has_navigator
        Plug 'ray-x/guihua.lua', {'do': 'cd lua/fzy && make' }
        Plug 'ray-x/navigator.lua'
    endif
    if has_lspsaga
        Plug 'tami5/lspsaga.nvim' " chose either lspsaga or navigator
      " Plug 'nvimdev/lspsaga.nvim' " chose either lspsaga or navigator
    endif

    " Debugging
    Plug 'puremourning/vimspector' " for vim (not neovim) support
    Plug 'mfussenegger/nvim-dap' " debug adapter for debugging
    Plug 'theHamsta/nvim-dap-virtual-text' " virtual text during debugging
    Plug 'rcarriga/nvim-dap-ui' " for nvim-dap
endif

" Prettier
" Make sure to also update the `autocmd` if a new `for` language is added.
Plug 'Chiel92/vim-autoformat', { 'for': ['gn', 'jbuild', 'opam', 'python', 'nix', 'hcl', 'elixir'] }
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install --frozen-lockfile --production',
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
Plug 'LnL7/vim-nix', { 'for': ['nix'], 'do': shellescape('nix profile install nixpkgs#nixpkgs-fmt') }
Plug 'elixir-editors/vim-elixir'

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

" Detect whether we're on a remote linux box.
fu! StartsWith(longer, shorter) abort
  return a:longer[0:len(a:shorter)-1] ==# a:shorter
endfunction
let g:isRemoteSession = ($STY == "")
let g:isDevDsk = StartsWith(hostname(), "dev-dsk")

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
set timeoutlen=500  " timeout for leader key
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

" =============================================================================
" Colors
" =============================================================================
" Theme Overrides

function! HighlightsDark() abort
  " --- Bufferline ---
  hi! BufferLineFill guibg=#073642

  " Color was previously: #073642
  " hi! IblScope guifg=#073642 guibg=none gui=nocombine
  hi! @ibl.scope.char.1 guibg=#073642
  hi! IblScope gui=nocombine guifg=#657b83 guibg=#073642
  hi! IblIndent guifg=#234854 guibg=none gui=nocombine
  hi! IblWhitespace guifg=#234854 guibg=none gui=nocombine
  hi! Comment cterm=NONE ctermfg=92 gui=NONE guifg=#586e75 guibg=NONE guisp=NONE
  hi! Visual ctermbg=92 ctermfg=7 guibg=#586e75 guifg=#002b36 gui=nocombine guisp=none

  " --- RUST ---
  " Pmenu:
  " PmenuSel: selection
  " GHListHl: Guihua List Highlight
  " GHListDark: Guihui List
  hi! Pmenu ctermfg=12 ctermbg=0 guifg=#839496 guibg=#073642 guisp=NONE
  hi! FloatBorder ctermfg=1 guifg=#ffffff guibg=NONE guisp=NONE
  hi! GHTextViewDark ctermfg=12 ctermbg=0 guifg=#93a1a1 guibg=#002b36 guisp=NONE
  hi! NormalFloat ctermfg=12 ctermbg=7 guifg=#93a1a1 guibg=#002b36 guisp=NONE
  hi! FloatShadow blend=80 guibg=#073642
  hi! FloatShadowThrough blend=100 guibg=#073642
  "hi! LocalHighlight cterm= gui= guifg=#dcd7ba guibg=#2d4f67

  " --- TreeSitter ---
  hi! TSDefinitionUsage guifg=none guibg=#073642 gui=underline guisp=none
endfunction

function! HighlightsLight() abort
  " --- Bufferline ---
  hi! BufferLineFill guibg=#eee8d5

  hi! @ibl.scope.char.1 guibg=#eee8d5
  hi! IblScope gui=nocombine guifg=#839496 guibg=#eee8d5
  hi! IblIndent guifg=#eee8d5 guibg=none gui=nocombine
  hi! IblWhitespace guifg=#eee8d5 guibg=none gui=nocombine
  hi! Comment cterm=NONE ctermfg=92 gui=NONE guifg=#93a1a1 guibg=NONE guisp=NONE
  hi! Visual ctermbg=92 ctermfg=7 guibg=#93a1a1 guifg=#fdf6e3 gui=nocombine guisp=none

  hi! Pmenu ctermfg=11 ctermbg=0 guifg=#657b83 guibg=#eee8d5 guisp=NONE
  hi! FloatBorder ctermfg=0 guifg=#000000 guibg=NONE guisp=NONE
  hi! GHTextViewDark ctermfg=10 ctermbg=15 guifg=#586e75 guibg=#fdf6e3 guisp=NONE
  hi! NormalFloat ctermfg=10 ctermbg=15 guifg=#586e75 guibg=#fdf6e3 guisp=NONE
  hi! FloatShadow blend=80 guibg=#eee8d5
  hi! FloatShadowThrough blend=100 guibg=#eee8d5
  "hi! LocalHighlight cterm= gui= guifg=#dcd7ba guibg=#2d4f67

  " --- TreeSitter ---
  hi! TSDefinitionUsage guifg=none guibg=#eee8d5 gui=underline guisp=none
endfunction

" Colorschemes usually reset all highlighting, including your own, when they
" are sourced, hence the autocmd group.
augroup MyColors
  autocmd!

  " Dark colors:
  if &background ==# 'dark'
    autocmd ColorScheme * call HighlightsDark()
  else
    autocmd ColorScheme * call HighlightsLight()
  endif
augroup END

" Theme
if has('nvim')
    set termguicolors
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set background=dark
let g:solarized_italics = 0
colorscheme solarized

" SOLARIZED HEX     16/8 TERMCOL  XTERM/HEX   L*A*B      RGB         HSB
" --------- ------- ---- -------  ----------- ---------- ----------- -----------
" base03    #002b36  8/4 brblack  234 #1c1c1c 15 -12 -12   0  43  54 193 100  21
" base02    #073642  0/4 black    235 #262626 20 -12 -12   7  54  66 192  90  26
" base01    #586e75 10/7 brgreen  240 #585858 45 -07 -07  88 110 117 194  25  46
" base00    #657b83 11/7 bryellow 241 #626262 50 -07 -07 101 123 131 195  23  51
" base0     #839496 12/6 brblue   244 #808080 60 -06 -03 131 148 150 186  13  59
" base1     #93a1a1 14/4 brcyan   245 #8a8a8a 65 -05 -02 147 161 161 180   9  63
" base2     #eee8d5  7/7 white    254 #e4e4e4 92 -00  10 238 232 213  44  11  93
" base3     #fdf6e3 15/7 brwhite  230 #ffffd7 97  00  10 253 246 227  44  10  99
" yellow    #b58900  3/3 yellow   136 #af8700 60  10  65 181 137   0  45 100  71
" orange    #cb4b16  9/3 brred    166 #d75f00 50  50  55 203  75  22  18  89  80
" red       #dc322f  1/1 red      160 #d70000 50  65  45 220  50  47   1  79  86
" magenta   #d33682  5/5 magenta  125 #af005f 50  65 -05 211  54 130 331  74  83
" violet    #6c71c4 13/5 brmagenta 61 #5f5faf 50  15 -45 108 113 196 237  45  77
" blue      #268bd2  4/4 blue      33 #0087ff 55 -10 -45  38 139 210 205  82  82
" cyan      #2aa198  6/6 cyan      37 #00afaf 60 -35 -05  42 161 152 175  74  63
" green     #859900  2/2 green     64 #5f8700 60 -20  65 133 153   0  68 100  60

" == DARK ==
" - base3
" - base2
" - base1   -> optional emphasized content
" - base0   -> body text/default code/primary content
" - base00  ->
" - base01  -> comments/secondary content
" - base02  -> background highlights
" - base03  -> background
"
" == LIGHT ==
" - base03
" - base02
" - base01  -> optional emphasized content
" - base00  -> body text/default code/primary content
" - base0   ->
" - base1   -> comments/secondary content
" - base2   -> background highlights
" - base3   -> background

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
au BufRead,BufNewFile *.tfvars set ft=hcl                       " HCL
au BufRead,BufNewFile *.ex,*.exs set ft=elixir                   " elixir
au BufRead,BufNewFile *.eex,*.leex,*.sface,*.lexs set ft=eelixir "elixir
au BufRead,BufNewFile mix.lock set ft=elixir                     "elixir
au BufRead,BufNewFile *.heex set ft=heex

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
  " Duplicated in `auto-dark-mode`
  if &background ==# 'dark'
    highlight ColorColumn guibg=#004653
  else
    highlight ColorColumn guibg=#eee8d5
  endif

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
" Strip ANSI Escapes
" =============================================================================
fun! StripAnsiEscapes()
  :%s/\%x1b\[[0-9;]*m//g
endfun

command! StripAnsi call StripAnsiEscapes()

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
" Close all floating windows
" =============================================================================
lua <<EOF
_G.CloseAllFloatingWindows = function()
  local closed_windows = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then  -- is_floating_window?
      vim.api.nvim_win_close(win, false)  -- do not force
      table.insert(closed_windows, win)
    end
  end
  print(string.format('Closed %d windows: %s', #closed_windows, vim.inspect(closed_windows)))
end
EOF
command! -nargs=* CloseAllFloatingWindows call v:lua.CloseAllFloatingWindows()


" =============================================================================
"                       ____  _             _
"                      |  _ \| |_   _  __ _(_)_ __  ___
"                      | |_) | | | | |/ _` | | '_ \/ __|
"                      |  __/| | |_| | (_| | | | | \__ \
"                      |_|   |_|\__,_|\__, |_|_| |_|___/
"                                     |___/
" =============================================================================
" PLUGINS (for search)

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
function vsnip_complete()
  cmp.complete({
    config = {
      sources = {
        { name = 'vsnip' }
      }
    }
  })
end
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
    ['<C-n>'] = cmp.mapping({
      i = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          cmp.complete()
        end
      end,
      c = cmp.mapping.select_next_item(),
      s = cmp.mapping.select_next_item(),
    }),
    --['<C-s>'] = cmp.mapping(vsnip_complete, { 'i' }),
    -- Add tab support
    ['<S-Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end,
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end,
    ['<C-,>'] = cmp.mapping.scroll_docs(-4),
    ['<C-.>'] = cmp.mapping.scroll_docs(4),
    ['<C-j>'] = cmp.mapping.close(),
    ['<CR>'] = function(fallback)
      if cmp.visible() and cmp.get_selected_entry() ~= nil then
        cmp.confirm({
          behavior = cmp.ConfirmBehavior.Insert,
          select = false,
        })
      else
        fallback()
      end
    end,
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
  automatic_installation = false,
  ensure_installed = {
    -- require separate setup
    "rust_analyzer",
    "yamlls",
    -- automatically setup
    "tsserver",
    --"eslint",
    "gopls",
    "bashls",
    "lua_ls",
    "vimls",
    "jedi_language_server", -- python
    "pylsp", -- depends on the above
    "rnix",
    "elixirls",
    "erlangls",
    "clangd",
    "cmake",
  },
}

local lspconfig = require('lspconfig')
local lsp_defaults = lspconfig.util.default_config
local lsp_status = require("lsp-status")
local navbuddy = require("nvim-navbuddy")

lsp_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lsp_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities(),
  lsp_status.capabilities
)
lsp_defaults.capabilities['semanticTokensProvider'] = nil

lsp_status.register_progress()


-- Global `on_attach`
local function on_attach(client, bufnr)
  -- This produces errors due to lspconfig bug: https://github.com/neovim/nvim-lspconfig/issues/2542
  --if client.server_capabilities then
  --  client.server_capabilities.semanticTokensProvider = nil
  --end

  -- setup buffer keymaps etc.
  lsp_status.on_attach(client)
  navbuddy.attach(client, bufnr)
end

local function on_init(client, init_result)
  -- disable highlighting from lsp
  if client.server_capabilities then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.semanticTokensProvider = false  -- turn off semantic tokens
  end
end

-- Rust
local rust_tools = require("rust-tools")
local extension_path = ''
local codelldb_path = ''
local liblldb_path = ''

-- Installing debugging capabilities:
-- 1. Download the CodeLLDB vscode extension.
-- 2. Find out where its installed. On linux, it's usually in $HOME/.vscode/extensions/...
-- 3. Update your configuration:
-- 4. Create a .vimspector.json

if vim.fn.has('win32') then
  extension_path = vim.env.HOME .. '/bin/codelldb-x86_64-windows/extension/'
  codelldb_path = extension_path .. 'adapter/codelldb.exe'
  liblldb_path = extension_path .. 'lldb/lib/liblldb.lib'
elseif vim.loop.os_uname().sysname == "Darwin" then
  extension_path = vim.env.HOME .. '/.vscode/extensions/vadimcn.vscode-lldb-1.9.0/'
  codelldb_path = extension_path .. 'adapter/codelldb'
  liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
end

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
    dap = {
      adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path)
    },
    server = {
      on_attach = on_attach,
      on_init = on_init,
      --capabilities = capabilities,
      flags = { allow_incremental_sync = false },
      commands = {
        RustOpenDocs = {
          function()
            vim.lsp.buf_request(
              vim.api.nvim_get_current_buf(),
              'experimental/externalDocs',
              vim.lsp.util.make_position_params(),
              function(err, url)
                if err then
                  error(tostring(err))
                elseif url then
                  vim.loop.spawn('open', { args = { '-a', 'firefox', '--args', url }})
                else
                  print('no documentation found')
                end
              end
            )
          end,
          description = 'Open documentation for the symbol under the cursor in default browser',
        },
      },
      settings = {
        ["rust-analyzer"] = {
          -- Exception for AL2
          vim.g["isDevDsk"] and {
            server = {
              path = '$HOME/.toolbox/bin/rust-analyzer',
            },
          } or {},
          assist = {
            importGranularity = "module",
            importPrefix = "by_self",
          },
          -- new format
          imports = {
            granularity = {
              group = "module",
            },
            prefix = "self",
          },
          cargo = {
            loadOutDirsFromCheck = true,
            buildScripts = {
              enable = true,
            },
          },
          procMacro = {
            enable = true,
            --attributes = {
            --  enable = true,
            --},
          },
          -- must've been changed in some version.
          --check = {
          --  command = "clippy",
          --},
          checkOnSave = {
            command = "clippy"
          },
          -- panicking too often
          --diagnostics = {
          --  experimental = {
          --    enable = true,
          --  },
          --},
        },
      },
    },
}
rust_tools.setup(rust_opts)

-- Flutter/Dart
require("flutter-tools").setup{
  lsp = {
    on_attach = on_attach,
  },
}

-- Yaml
lspconfig["yamlls"].setup {
  settings = {
    yaml = {
      keyOrdering = false
    }
  }
}

-- Remaining servers
local lsp_servers = {
  "tsserver",
  --"eslint",
  "gopls",
  "bashls",
  "lua_ls",
  "vimls",
  "jedi_language_server",
  "pylsp",
  "rnix",
  "elixirls",
  "erlangls",
  "clangd",
  "cmake",
}
for _, server in ipairs(lsp_servers) do
  lspconfig[server].setup {
    on_attach = on_attach,
    on_init = on_init,
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

vim.keymap.set('n', '<leader>dt', ':call v:lua.toggle_diagnostics()<CR>',  {noremap = true, silent = true, desc = "Toggle LSP Diagnostics"})
EOF

function Refresh()
    lua vim.lsp.stop_client(vim.lsp.get_active_clients())
    sleep 500m
    edit
endfunction
command RefreshLSP call Refresh()

" =============================================================================
" Linting
" =============================================================================
lua <<EOF
local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.diagnostics.mypy,
        --null_ls.builtins.diagnostics.eslint,
        --null_ls.builtins.completion.spell,
        --null_ls.builtins.diagnostics.typos,
    },
})
EOF

" =============================================================================
" navbuddy
" =============================================================================
lua <<EOF
local navbuddy = require("nvim-navbuddy")
local actions = require("nvim-navbuddy.actions")

navbuddy.setup {
  window = {
    border = "single",  -- "rounded", "double", "solid", "none"
  },
  use_default_mappings = false,
  mappings = {
      ["<esc>"] = actions.close(),        -- Close and cursor to original location
      ["q"] = actions.close(),

      ["n"] = actions.next_sibling(),     -- down
      ["r"] = actions.previous_sibling(), -- up

      ["b"] = actions.parent(),           -- Move to left panel
      ["s"] = actions.children(),         -- Move to right panel
      ["0"] = actions.root(),             -- Move to first panel

      ["v"] = actions.visual_name(),      -- Visual selection of name
      ["V"] = actions.visual_scope(),     -- Visual selection of scope

      ["y"] = actions.yank_name(),        -- Yank the name to system clipboard "+
      ["Y"] = actions.yank_scope(),       -- Yank the scope to system clipboard "+

      ["i"] = actions.insert_name(),      -- Insert at start of name
      ["I"] = actions.insert_scope(),     -- Insert at start of scope

      ["a"] = actions.append_name(),      -- Insert at end of name
      ["A"] = actions.append_scope(),     -- Insert at end of scope

      ["x"] = actions.rename(),           -- Rename currently focused symbol

      ["d"] = actions.delete(),           -- Delete scope

      ["f"] = actions.fold_create(),      -- Create fold of current scope
      ["F"] = actions.fold_delete(),      -- Delete fold of current scope

      ["c"] = actions.comment(),          -- Comment out current scope

      ["<enter>"] = actions.select(),     -- Goto selected symbol
      ["o"] = actions.select(),

      ["N"] = actions.move_down(),        -- Move focused node down
      ["R"] = actions.move_up(),          -- Move focused node up

      ["<C-i>"] = actions.vsplit(),       -- Open selected node in a vertical split
      ["<C-t>"] = actions.hsplit(),       -- Open selected node in a horizontal split

      ["t"] = actions.telescope({         -- Fuzzy finder at current level.
          layout_config = {               -- All options that can be
              height = 0.60,              -- passed to telescope.nvim's
              width = 0.60,               -- default can be passed here.
              prompt_position = "top",
              preview_width = 0.50
          },
          layout_strategy = "horizontal"
      }),

      ["g?"] = actions.help(),            -- Open mappings help window
    },
    lsp = {
      preference = {'pylsp'},      -- list of lsp server names in order of preference
    },
}

vim.keymap.set('n', '<leader>t', ':Navbuddy<CR>', { noremap = true, silent = true, desc = "Navbuddy" })

EOF

" =============================================================================
" Debugging
" =============================================================================
let g:vimspector_enable_mappings = 'HUMAN'
let g:vimspector_install_gadgets = [ 'CodeLLDB' ]

lua <<EOF
local vimspector_bindings = {
  {'n', '<leader>bl', ':call vimspector#Launch()<CR>', 'Launch Debugger' },
  {'n', '<leader>bq', ':VimspectorReset<CR>', 'Reset Debugger' },
  {'n', '<leader>bz', '<Plug>VimspectorRestart', 'Restart Debugger' },
  {'n', '<leader>bc', '<Plug>VimspectorContinue', 'Continue' },
  {'n', '<leader>bd', '<Plug>VimspectorStop', 'Stop Debugging' },
  {'n', '<leader>bt', '<Plug>VimspectorRunToCursor', 'Run To Cursor' },
  {'n', '<leader>bn', '<Plug>VimspectorStepOver', 'Step Over' },
  {'n', '<leader>bsi', '<Plug>VimspectorStepInto', 'Step Into' },
  {'n', '<leader>bso', '<Plug>VimspectorStepOut', 'Step Out' },
  {'n', '<leader>br', '<Plug>VimspectorToggleBreakpoint', 'Toggle Breakpoint' },
  {'n', '<leader>be', ':VimspectorEval', 'Eval' },
  {'n', '<leader>bw', ':VimspectorWatch', 'Watch Value' },
  {'n', '<leader>bo', ':VimspectorShowOutput', 'Show Output' },
  {'n', '<leader>bi', '<Plug>VimspectorBalloonEval', 'Balloon Eval' },
  {'x', '<leader>bi', '<Plug>VimspectorBalloonEval', 'Balloon Eval' },
}

for _, kb in ipairs(vimspector_bindings) do
  vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
end

EOF

" Custom Telescope Picker with all commands.
lua <<EOF
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

function _G.dap_actions_picker(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "debugger",
    finder = finders.new_table {
      results = {
        "LAUNCH",
        "Toggle Breakpoint",
        "■ Stop",
        "▶ Continue",
        "▷ Pause",
        "↷ Step Over",
        "→ Step In",
        "← Step Out",
        "⟲ Restart",
        "✕ Reset",
        "List Breakpoints",
        "Quit Debugger",
      },
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local index = selection.index
        local binds = {
          [1] = function()
            vim.cmd("call vimspector#Launch()")
          end,
          [2] = function()
            vim.cmd("call vimspector#ToggleBreakpoint()")
          end,
          [3] = function()
            vim.cmd("call vimspector#Stop( { 'interactive': v:false } )")
          end,
          [4] = function()
            vim.cmd("call vimspector#Continue()")
          end,
          [5] = function()
            vim.cmd("call vimspector#Pause()")
          end,
          [6] = function()
            vim.cmd("call vimspector#StepOver()")
          end,
          [7] = function()
            vim.cmd("call vimspector#StepInto()")
          end,
          [8] = function()
            vim.cmd("call vimspector#StepOut()")
          end,
          [9] = function()
            vim.cmd("call vimspector#Restart()")
          end,
          [10] = function()
            vim.cmd("call vimspector#Reset( { 'interactive': v:false } )")
          end,
          [11] = function()
            vim.cmd("call vimspector#ListBreakpoints()")
          end,
          [12] = function()
            vim.cmd("call vimspector#Reset()")
          end,
        };
        local bind = binds[index]
        bind()
        --print(vim.inspect(selection))
        --print('index:' .. vim.inspect(index))
        --print('bind:' .. vim.inspect(bind))
        --print(vim.inspect(binds))
        --vim.api.nvim_put({ selection[1] }, "", false, true)
      end)
      return true
    end,
  }):find()
end

EOF

nmap <leader>ab :call v:lua.dap_actions_picker()<CR>

" =============================================================================
" TROUBLE
" =============================================================================
lua << EOF
require("trouble").setup {
  action_keys = { -- key mappings for actions in the trouble list
    -- map to {} to remove a mapping, for example:
    -- close = {},
    close = "q", -- close the list
    cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
    refresh = "A", -- manually refresh
    jump = {"<cr>", "<tab>"}, -- jump to the diagnostic or open / close folds
    open_split = { "<c-i>" }, -- open buffer in new split
    open_vsplit = { "<c-t>" }, -- open buffer in new vsplit
    open_tab = { "<c-t>" }, -- open buffer in new tab
    jump_close = {"o"}, -- jump to the diagnostic and close the list
    toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
    switch_severity = "s", -- switch "diagnostics" severity filter level to HINT / INFO / WARN / ERROR
    toggle_preview = "P", -- toggle auto_preview
    hover = "K", -- opens a small popup with the full multiline message
    preview = "p", -- preview the diagnostic location
    close_folds = {"zM", "zm"}, -- close all folds
    open_folds = {"zR", "zr"}, -- open all folds
    toggle_fold = {"zA", "za"}, -- toggle fold of current file
    previous = "r", -- previous item
    next = "n" -- next item
  },
}
EOF

nnoremap <leader>xx <cmd>TroubleToggle workspace_diagnostics<CR>


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

-- Due to the ability to change between dark & light themes, we need to put this
-- in a function that we can call from the callback.
function lualine_setup()
  require'lualine'.setup {
    options = {
      icons_enabled = false,
      theme = (vim.opt.background:get() == 'dark' and custom_solarized_dark or 'solarized_light'),
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
end

lualine_setup()

EOF

" =============================================================================
" TABLINE
" =============================================================================
" Should be below lualine.
lua <<EOF
local bufferline = require("bufferline")

function bufferline_setup()
  bufferline.setup {
    options = {
      mode = 'tabs',
      show_tab_indicators = false, -- don't need them with mode=tabs
      --style_preset = bufferline.style_preset.minimal,
      -- disable mouse
      right_mouse_command = nil,
      left_mouse_command = nil,
      middle_mouse_command = nil,
      diagnostics = "nvim_lsp",
      separator_style = {'|', '|'},
      hover = {
        enabled = false,
      },
      --indicator = {
      --    style = 'underline',
      --},
      show_close_icon = false,
      show_buffer_close_icons = false,
      buffer_close_icon = '󰅖',
      close_icon = '',
      offsets = {
          {
              filetype = "NvimTree",
              text = "File Explorer",
              text_align = "center",
              separator = true,
          },
      },
      diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or ""
          return " " .. icon .. count
      end
    }
  }
end

bufferline_setup()

EOF

" lua <<EOF
" require'tabline'.setup {
"     -- Defaults configuration options
"     enable = true,
"     options = {
"         section_separators = {'', ''},
"         component_separators = {'', ''},
"         max_bufferline_percent = 66, -- set to nil by default, and it uses vim.o.columns * 2/3
"         show_tabs_always = false, -- this shows tabs only when there are more than one tab or if the first tab is named
"         show_devicons = true, -- this shows devicons in buffer section
"         show_bufnr = false, -- this appends [bufnr] to buffer section,
"         show_filename_only = true, -- shows base filename only instead of relative path in filename
"         modified_icon = "+ ", -- change the default modified icon
"         modified_italic = false, -- set to true by default; this determines whether the filename turns italic if modified
"         show_tabs_only = true,
"     }
" }
" EOF


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
saga.setup {
    use_saga_diagnostic_sign = true,
    -- diagnostic signs
    error_sign = "",
    warn_sign = "",
    hint_sign = "",
    infor_sign = "",
    --error_sign = 'E',
    --warn_sign = 'W',
    --hint_sign = 'H',
    --infor_sign = 'I',
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
      --scroll_down = '<C-f>',scroll_up = '<C-b>'
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

inoremap <silent><c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent><c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent>K <cmd>lua vim.lsp.buf.hover({ popup_opts = { border = single, max_width = 80 }})<CR>
nnoremap <silent><Leader>re <cmd>lua vim.lsp.buf.rename()<CR>

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
    " Not avaliable in new lspsaga.
    " inoremap <silent><c-k> <cmd>:Lspsaga signature_help<CR>
    " nnoremap <silent><c-k> <cmd>:Lspsaga signature_help<CR>
    " nnoremap <silent>K <cmd>:Lspsaga hover_doc<CR>

    nnoremap <silent>gd <cmd>:Lspsaga preview_definition<CR>
    nnoremap <silent><Leader>rn <cmd>:Lspsaga rename<CR>
    nnoremap <silent><Leader>k <cmd>lua require'lspsaga.diagnostic'.show_cursor_diagnostics()<CR>
    nnoremap <silent> <S-h> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>
    nnoremap <silent> <S-l> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>
    nnoremap <silent> [e :Lspsaga diagnostic_jump_next<CR>
    nnoremap <silent> ]e :Lspsaga diagnostic_jump_prev<CR>
else
    nnoremap <silent><Leader>k <cmd>lua vim.diagnostic.open_float(0, { scope = "line" })<CR>
    nnoremap <silent> [e <cmd>lua vim.diagnostic.goto_next()<CR>
    nnoremap <silent> ]e <cmd>lua vim.diagnostic.goto_prev()<CR>
endif

lua <<EOF
local _border = "single"

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = _border
  }
)

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, {
    border = _border
  }
)

vim.diagnostic.config{
  float={border=_border}
}

require('lspconfig.ui.windows').default_options = {
  border = _border
}

EOF


" =============================================================================
" GitSigns
" =============================================================================
lua << EOF
local function gitsigns_keymap_attach(bufnr)
    local function opts(desc)
      return { desc = 'git: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    --vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
    --vim.api.nvim_buf_set_keymap(bufnr, 'n', 'hs', '<cmd>lua require"gitsigns".stage_hunk()<CR>', {})

    vim.keymap.set('n', '<leader>ss', '<cmd>Gitsigns stage_hunk<CR>', opts('Stage Hunk'))
    vim.keymap.set('n', '<leader>su', '<cmd>Gitsigns undo_stage_hunk<CR>', opts('Undo Staging Hunk'))
    vim.keymap.set('n', '<leader>sr', '<cmd>Gitsigns reset_hunk<CR>', opts('Reset Hunk'))
    vim.keymap.set('n', '<leader>sR', '<cmd>Gitsigns reset_buffer<CR>', opts('Reset Buffer'))
    vim.keymap.set('n', '<leader>sp', '<cmd>Gitsigns preview_hunk<CR>', opts('Preview Hunk'))
    vim.keymap.set('n', '<leader>sb', '<cmd>lua require"gitsigns".blame_line{full=true}<CR>', opts('Blame Line'))
    vim.keymap.set('n', '<leader>sS', '<cmd>Gitsigns stage_buffer<CR>', opts('Stage Buffer'))
    vim.keymap.set('n', '<leader>sU', '<cmd>Gitsigns reset_buffer_index<CR>', opts('Reset Buffer Index'))

    vim.keymap.set('v', '<leader>sr', ':Gitsigns reset_hunk<CR>', opts('ResetHunk (Visual)'))
    vim.keymap.set('v', '<leader>ss', ':Gitsigns stage_hunk<CR>', opts('StageHunk (Visual)'))
end

require('gitsigns').setup({
  on_attach = gitsigns_keymap_attach,
  signs = {
    add          = { text = '│' },
    change       = { text = '│' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  _signs_staged_enable = true,
})
EOF


" =============================================================================
" Treesitter
" =============================================================================
lua <<EOF
require'nvim-treesitter.configs'.setup {
    ensure_installed = {'rust', 'json', 'javascript', 'typescript', 'tsx', 'vim', 'lua', 'go', 'haskell', 'bash', 'markdown', 'markdown_inline', 'python'},
    auto_install = false,
    highlight = {
        enable = true,
        disable = { 'typescript' },
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
" leap
" =============================================================================
"lua <<EOF
"require('leap').setup {
"  case_sensitive = false,
"  safe_labels = {
"    "t", "e", "u", "c", "/",
"    "T", "E", "L", "H", "M", "U", "G", "?", "Z"
"  },
"}

"-- Greying out the search
"vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })

"-- Search in both directions. Caveats apply.
"vim.keymap.set({"n", "x", "o"}, "t", "<cmd>lua require('leap').leap { target_windows = { vim.fn.win_getid() } }<CR>", {silent = true})

"-- Search in all windows. Same caveats apply as above.
"vim.keymap.set('n', 'gt', function()
"  local focusable_windows_on_tabpage = vim.tbl_filter(
"    function (win) return vim.api.nvim_win_get_config(win).focusable end,
"    vim.api.nvim_tabpage_list_wins(0)
"  )
"  require('leap').leap { target_windows = focusable_windows_on_tabpage }
"end)


"-- Default actions:
"--vim.keymap.set({"n", "x", "o"}, "t", "<Plug>(leap-forward-to)", {silent = true})
"--vim.keymap.set({"n", "x", "o"}, "T", "<Plug>(leap-backward-to)", {silent = true})
"--vim.keymap.set({"n", "x", "o"}, "gt", "<Plug>(leap-cross-window)", {silent = true})

"EOF

" =============================================================================
" flash.nvim
" =============================================================================
lua <<EOF
require('flash').setup {
  labels = "ctieobnrsjduaxphlmwfvyz",
  char = {
    enabled = false,
    keys = {},
  },
  modes = {
    search = {
      enabled = false,
    },
  },
}

-- Highlights
vim.api.nvim_set_hl(0, 'FlashBackdrop', { link = 'Comment' })
vim.api.nvim_set_hl(0, 'FlashMatch', { link = 'Search' })
vim.api.nvim_set_hl(0, 'FlashCurrent', { link = 'IncSearch' })
vim.api.nvim_set_hl(0, 'FlashLabel', { link = 'WildMenu' })

-- This mimics leap.nvim:
--vim.api.nvim_set_hl(0, 'FlashLabel', { cterm = { underline = true, nocombine = true }, ctermfg=9, underline = true, nocombine = true, fg='#ccff88' })

-- Remove default flash.nvim mapping for comma (,)
vim.keymap.del({ 'n', 'o', 'x' }, ',')

-- Keymaps
vim.keymap.set({"n", "x", "o"}, "t", "<cmd>lua require('flash').jump()<CR>", { silent = true, desc = 'Jump' })
vim.keymap.set({"n", "x", "o"}, "T", "<cmd>lua require('flash').treesitter_search()<CR>", { silent = true, desc = 'Treesitter Jump' })
EOF

" =============================================================================
" which-key
" =============================================================================
lua <<EOF
local wk = require("which-key")
wk.setup {}
wk.register({
  ['<C-W>'] = {
    name = 'window',
    H	= 'move current window to the far left',
    J	= 'move current window to the very bottom',
    K	= 'move current window to the very top',
    L	= 'move current window to the far right',
  },
})

wk.register({
  b = {
    name = '+debugger',
  },
  [','] = {
    name = '+zoom',
  },
  a = {
    name = '+picker',
  },
  c = {
    name = '+codeaction',
  },
  d = {
    name = '+lsp',
  },
  f = {
    name = '+findfiles',
  },
  g = {
    name = '+diagnostics',
  },
  n = {
    name = '+neogen',
  },
  q = {
    name = '+quickfix',
  },
  r = {
    name = '+rename',
  },
  s = {
    name = '+git',
  },
  x = {
    name = '+trouble',
  },
}, { prefix = '<leader>' })
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

" =============================================================================
" goto-preview
" =============================================================================
lua <<EOF
require('goto-preview').setup {
  width = 120,
  height = 15,
  default_mappings = false,
  stack_floating_preview_windows = false, -- Whether to nest floating windows
}

local gotopreview_bindings = {
  { 'n', '<leader>dd', "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", 'Goto Definition' },
  { 'n', '<leader>dy', "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", 'Goto Type Definition' },
  { 'n', '<leader>di', "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", 'Goto Implementation' },
  { 'n', '<leader>dg', "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>", 'Goto Declaration' },
  { 'n', '<leader>dq', "<cmd>lua require('goto-preview').close_all_win()<CR>", 'Close all Floating Windows' },
  { 'n', '<leader>dr', "<cmd>lua require('goto-preview').goto_preview_references()<CR>", 'Goto References' },
}

for _, kb in ipairs(gotopreview_bindings) do
  vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
end
EOF

" Code navigation shortcuts
" nnoremap <silent> <leader>dd <cmd>lua vim.lsp.buf.definition()<CR>
" nnoremap <silent> <leader>di <cmd>split \| lua vim.lsp.buf.definition()<CR>
" nnoremap <silent> <leader>dt <cmd>vsplit \| lua vim.lsp.buf.definition()<CR>
" nnoremap <silent> <leader>i <cmd>lua vim.lsp.buf.implementation()<CR>
" nnoremap <silent> <leader>y <cmd>lua vim.lsp.buf.type_definition()<CR>
" nnoremap <silent> <leader>rr <cmd>lua vim.lsp.buf.references()<CR>

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
local hooks = require "ibl.hooks"
hooks.register(
  hooks.type.WHITESPACE,
  hooks.builtin.hide_first_space_indent_level
)

function ibl_setup()
  require("ibl").setup {
      indent = {
        char = '│',
      },
      exclude = {
        filetypes = {
         'lspinfo',
         'packer',
         'checkhealth',
         'help',
         'man',
         'gitcommit',
         'TelescopePrompt',
         'TelescopeResults',
         '',
        },
      },
      whitespace = {
        remove_blankline_trail = true,
      },
  }
end

ibl_setup()

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
" whitespace nvim
" =============================================================================
lua <<EOF
require('whitespace-nvim').setup({
  -- configuration options and their defaults

  -- `highlight` configures which highlight is used to display
  -- trailing whitespace
  highlight = 'errorMsg',

  -- `ignored_filetypes` configures which filetypes to ignore when
  -- displaying trailing whitespace
  ignored_filetypes = { 'TelescopePrompt', 'Trouble', 'help', 'mason', 'floaterm', 'Terminal', 'gitcommit', 'vim-plug', 'lspinfo' },
})
EOF

" =============================================================================
" local highlight
" =============================================================================
lua <<EOF
require('local-highlight').setup({
  file_types = {'rust', 'typescript', 'typescript.tsx', 'javascript', 'javascript.jsx', 'vim', 'bash'},
  hlgroup = 'TSDefinitionUsage',
})
EOF

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

" =============================================================================
" nvim-tree
" =============================================================================
lua <<EOF
require'window-picker'.setup({
    autoselect_one = true,
    include_current_win = false,
    selection_chars = 'ENCTIRSGOB',
    use_winbar = 'never', -- "always" | "never" | "smart"

    -- the foreground (text) color of the picker
    fg_color = '#ededed',

    -- if you have include_current_win == true, then current_win_hl_color will
    -- be highlighted using this background color
    current_win_hl_color = '#e35e4f',

    -- all the windows except the current window will be highlighted using this
    -- color
    other_win_hl_color = '#44cc41',
})

local function nvim_tree_attach(bufnr)
    local api = require('nvim-tree.api')

    local function opts(desc)
      return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    -- use all default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- remove mappings
    vim.keymap.del('n', 'r', { buffer = bufnr })
    vim.keymap.del('n', 'e', { buffer = bufnr })
    vim.keymap.del('n', '-', { buffer = bufnr })

    -- add mappings
    vim.keymap.set('n', 'C', api.tree.change_root_to_node, opts('CD'))
    vim.keymap.set('n', '<C-a>', api.tree.reload, opts('Refresh'))
    vim.keymap.set('n', 'R', api.fs.rename, opts('Rename'))
    vim.keymap.set('n', 'u', api.tree.change_root_to_parent, opts('Up'))
    vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
end

require("nvim-tree").setup({
  sort_by = "case_sensitive",
  sync_root_with_cwd = true, -- Changes the tree root directory on `DirChanged` and refreshes the tree.
  reload_on_bufenter = true, -- Automatically reloads the tree on `BufEnter` nvim-tree.
  on_attach = nvim_tree_attach,
  view = {
    adaptive_size = true,
    width = {
      max = 40,
    },
  },
  renderer = {
    group_empty = true,
    add_trailing = true,
    root_folder_label = ":~:s?$?/..?",
    indent_width = 2,
  },
  filters = {
    dotfiles = false, -- toggle via 'H'.
  },
  actions = {
    open_file = {
      quit_on_open = true,
      window_picker = {
        enable = true,
        picker = require('window-picker').pick_window,
      },
    },
    change_dir = {
      global = true,
    },
  },
  git = {
    ignore = false, -- show files ignored by Git. Toggle via 'I'.
  },
})
EOF

map <Leader>e :NvimTreeToggle<CR>

" Fallback
nnoremap <C-f> :echo " == NO FORMATTER == "<CR>


" =============================================================================
" vim-autoformat Settings.
" =============================================================================
if has_key(g:plugs, 'vim-autoformat')
    let g:formatdef_astyle_objc = '"astyle --mode=c"'
    let g:formatdef_gnformat = '"gn format --stdin"'
    let g:formatdef_ocpindent = '"ocp-indent"'
    let g:formatdef_tffmt = '"terraform fmt -"'
    let g:formatdef_nixfmt = '"nixpkgs-fmt"'
    let g:formatdef_mixfmt = '"mix format -"'
    let g:formatdef_flake8 = '"python3 -m flake8 -"'
    let g:formatdef_black = '"python3 -m black -"'
    let g:formatdef_isort = '"python3 -m isort -"'

    let g:formatters_objc = ['astyle_objc']
    let g:formatters_gn = ['gnformat']
    let g:formatters_hcl = ['tffmt']
    let g:formatters_nix = ['nixfmt']
    let g:formatters_elixir = ['mixfmt']
    let g:formatters_python = ['flake8', 'black', 'isort']
    let g:run_all_formatters_python = 1

    " let g:formatdef_prettier_ts = '"yarn --silent prettier --parser=typescript --stdin"'
    " let g:formatdef_prettier_js = '"yarn --silent prettier --stdin"'
    " let g:formatters_javascript = ['prettier_js']
    " let g:formatters_typescript = ['prettier_ts']
    " let g:formatters_rust = ['rustfmt']

    autocmd FileType gn nnoremap <buffer> <C-f> :Autoformat<CR>
    autocmd FileType jbuild nnoremap <buffer> <C-f> :Autoformat<CR>
    autocmd FileType opam nnoremap <buffer> <C-f> :Autoformat<CR>
    autocmd FileType python nnoremap <buffer> <C-f> :Autoformat<CR>
    autocmd FileType nix nnoremap <buffer> <C-f> :Autoformat<CR>
    autocmd FileType hcl nnoremap <buffer> <C-f> :Autoformat<CR>
    autocmd FileType elixir nnoremap <buffer> <C-f> :Autoformat<CR>
    autocmd FileType gn nnoremap <buffer> <C-f> :Autoformat<CR>
endif

" =============================================================================
" vim-prettier Settings.
" =============================================================================
autocmd! User vim-prettier nnoremap <buffer> <C-f> :Prettier<CR>
if has_key(g:plugs, 'vim-prettier')
    let g:prettier#config#trailing_comma = 'all'
    let g:prettier#config#arrow_parens = 'always'
    let g:prettier#config#bracket_spacing = 'true'

    autocmd FileType javascript nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType javascript.tsx nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType typescript nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType typescript.tsx nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType css nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType less nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType scss nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType json nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType graphql nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType markdown nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType vue nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType yaml nnoremap <buffer> <C-f> :Prettier<CR>
    autocmd FileType html nnoremap <buffer> <C-f> :Prettier<CR>
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
    autocmd FileType cs noremap <buffer> <c-f> :call UncrustifyWrapper('cs')<CR>
    autocmd FileType cs vnoremap <buffer> <c-f> :call RangeUncrustifyWrapper('cs')<CR>
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
local lga_actions = require("telescope-live-grep-args.actions")

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
    live_grep_args = {
      auto_quoting = true, -- enable/disable auto-quoting
      mappings = { -- extend mappings
        i = {
          ["<C-k>"] = lga_actions.quote_prompt(),
          ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
        },
      },
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
require('telescope').load_extension('live_grep_args')

local telescope_bindings = {
  {'n', '<leader>fn', "<cmd>lua require('telescope.builtin').resume()<cr>", 'Telescope: Resume' },
  {'n', '<leader>gr', "<cmd>lua require('telescope.builtin').lsp_references()<cr>", 'LSP: Find References' },
  {'n', '<leader>gd', "<cmd>lua require('telescope.builtin').diagnostics()<cr>", 'LSP: Show Diagnostics' },
  {'n', '<leader>ca', "<cmd>lua vim.lsp.buf.code_action()<cr>", 'LSP: Code Actions' },
  {'v', '<leader>ca', "<cmd>lua vim.lsp.buf.range_code_action()<cr>", 'LSP: Code Actions' },
  {'n', '<leader>gi', "<cmd>lua require('telescope.builtin').lsp_implementations()<cr>", 'LSP: Show Implementations' },
  {'n', '<leader>gg', "<cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>", 'LSP: Show Document Symbols' },
  {'n', '<leader>ge', "<cmd>lua require('telescope.builtin').lsp_workspace_symbols()<cr>", 'LSP: Show Workspace Symbols' },
  {'n', '<leader>gt', "<cmd>lua require('telescope.builtin').lsp_type_definitions()<cr>", 'LSP: Show Type Definitions' },
  {'n', '<leader>ff', "<cmd>lua require('telescope.builtin').find_files()<cr>", 'Find Files' },
  {'n', '<leader>fg', "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", 'Live GREP' },
  {'n', '<leader>fb', "<cmd>lua require('telescope.builtin').buffers()<cr>", 'Show Open Buffers' },
  {'n', '<leader>fh', "<cmd>lua require('telescope.builtin').help_tags()<cr>", 'Show Help Tags' },
  {'n', '<leader>fm', "<cmd>lua require('telescope.builtin').marks()<cr>", 'Show Marks' },
  {'n', '<leader>fs', "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>", 'Fuzzy Find (Current Buf)' },
  {'n', '<leader>v', "<cmd>lua require('telescope.builtin').treesitter()<cr>", 'Show Treesitter Symbols' },
}

for _, kb in ipairs(telescope_bindings) do
  vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
end

EOF

" =============================================================================
" LeaderF
" =============================================================================
" Unmap <leader>b to have it trigger which-key
autocmd BufReadPost,BufWinEnter * silent! unmap <leader>b
let g:Lf_ShortcutF = '<Leader>o'
let g:Lf_UseVersionControlTool = 0
let g:Lf_ShowRelativePath = 1
let g:Lf_PreviewCode = 0
let g:Lf_WindowHeight = 0.2
let g:Lf_ShowDevIcons = 1
let g:Lf_ShowHidden = 1
let g:Lf_UseCache = 0
let g:Lf_StlSeparator = {
    \ 'left': '',
    \ 'right': ''
    \ }
let g:Lf_JumpToExistingWindow = 0
" let g:Lf_RgConfig = [
"     \ "--glob=!git/*",
"     \ "--hidden"
" \ ]
let g:Lf_WildIgnore = {
    \ 'dir': ['.svn','.git','.p4','.perforce','.plastic','node_modules','temp','Temp','out','_out','_build','extern','build','env'],
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
let g:Lf_PreviewResult = {
        \ 'File': 0,
        \ 'Buffer': 0,
        \ 'Mru': 0,
        \ 'Tag': 0,
        \ 'BufTag': 0,
        \ 'Function': 0,
        \ 'Line': 0,
        \ 'Colorscheme': 0,
        \ 'Rg': 0,
        \ 'Gtags': 0
        \}

" let g:Lf_RootMarkers = ['.git', '.hg', '.svn', '.depotroot', '.projroot', '.p4', '.perforce', '.plastic']

lua <<EOF
local lf_bindings = {
  { 'n', '<Leader>o', ':LeaderfFile<CR>', 'Open File' },
  { 'n', '<Leader>bb', ':LeaderfBuffer<CR>', 'Find Buffer' },
  { 'n', '<Leader>z', ':LeaderfMruCwd<CR>', 'Open Recently Used' },
}

for _, kb in ipairs(lf_bindings) do
  vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
end

EOF

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

let g:VM_maps["Add Cursor Down"]       = '<C-h>'
let g:VM_maps["Add Cursor Up"]         = '<C-l>'
let g:VM_maps["Goto Next"] = ']'
let g:VM_maps["Goto Prev"] = '['
let g:VM_maps["Find Next"] = 'h'
let g:VM_maps["Find Prev"] = 'l'
let g:VM_maps["Skip Region"] = 'q'
let g:VM_maps["Remove Region"] = 'Q'
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

lua <<EOF
local wk = require("which-key")
wk.register({
  [','] = {
    name = '+floaterm',
    n = 'New Terminal',
    t = 'Toggle Terminal',
    b = 'Previous Terminal',
    s = 'Next Terminal',
  },
}, {})
EOF

" =============================================================================
" Docs
" =============================================================================
lua << EOF
  require("docs-view").setup {
    position = "bottom",
    height = 10,
    --width = 60,
    update_mode = 'auto',
  }
EOF

nnoremap f :DocsViewToggle<CR>

" =============================================================================
" diffview.nvim
" =============================================================================
lua <<EOF
  require("diffview").setup({
    view = {
      merge_tool = {
        disable_diagnostics = true,
      },
    },
    hooks = {
      view_opened = function(view)
        vim.g.diagnostics_active = false
        vim.diagnostic.reset()
        vim.cmd "LspStop"
      end,
      view_enter = function(view)
        vim.g.diagnostics_active = false
        vim.diagnostic.reset()
        vim.cmd "LspStop"
      end,
    },
  })
EOF

" -----------------------------------
" ALWAYS KEEP AT THE ABSOLUTE BOTTOM!
" -----------------------------------
" =============================================================================
" auto-dark-mode
" =============================================================================
lua <<EOF
local auto_dark_mode = require('auto-dark-mode')
vim.g["custom#isdarkmode"] = 1

if not vim.g["isRemoteSession"] then
  auto_dark_mode.setup({
    update_interval = 5000,
    set_dark_mode = function()
      vim.g["custom#isdarkmode"] = 1

      vim.api.nvim_set_option('background', 'dark')
      vim.cmd('call HighlightsDark()')
      vim.cmd('colorscheme solarized')
      vim.cmd('highlight ColorColumn guibg=#004653')

      -- Plugins:
      lualine_setup()
      ibl_setup()
      bufferline_setup()

      -- We'll need to setup custom highlights again.
      vim.cmd('call HighlightsDark()')
    end,

    set_light_mode = function()
      vim.g["custom#isdarkmode"] = 0

      vim.api.nvim_set_option('background', 'light')
      vim.cmd('call HighlightsLight()')
      vim.cmd('colorscheme solarized')
      vim.cmd('highlight ColorColumn guibg=#eee8d5')

      -- Plugins:
      lualine_setup()
      ibl_setup()
      bufferline_setup()

      -- We'll need to setup custom highlights again.
      vim.cmd('call HighlightsLight()')
    end,
  })
end
EOF


" =============================================================================
"             | |    __ _ _ __   __ _ _   _  __ _  __ _  ___  ___
"             | |   / _` | '_ \ / _` | | | |/ _` |/ _` |/ _ \/ __|
"             | |__| (_| | | | | (_| | |_| | (_| | (_| |  __/\__ \
"             |_____\__,_|_| |_|\__, |\__,_|\__,_|\__, |\___||___/
"                               |___/             |___/
" =============================================================================

" =============================================================================
" YAML
" =============================================================================
autocmd FileType yaml nnoremap <buffer> <C-f> :Prettier<CR>

" =============================================================================
" Rust
" =============================================================================
autocmd FileType rust nnoremap <buffer> <C-f> :RustFmt<CR>

" To view all groups: :so $VIMRUNTIME/syntax/hitest.vim
" Or to test terminal colors: :so $VIMRUNTIME/syntax/colortest.vim
nmap <leader>sp :call <SID>SynStack()<CR>
function! <SID>SynStack()
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

" =============================================================================
" Dart
" =============================================================================
autocmd FileType dart nnoremap <buffer> <C-f> :lua vim.lsp.buf.format({ async = true })<CR>
