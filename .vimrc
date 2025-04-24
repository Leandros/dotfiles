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
let has_navigator = 1
let has_lspsaga = 0

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
    Plug 'nvim-neotest/nvim-nio'               " Required for neotest
    Plug 'antoinemadec/FixCursorHold.nvim'
    Plug 'rcarriga/nvim-notify'                " Notification framework
    Plug 's1n7ax/nvim-window-picker', {'tag': 'v2.*'}

    " Completion
    Plug 'hrsh7th/nvim-cmp'                    " Completion framework
    Plug 'hrsh7th/cmp-vsnip'                   " Snippet completion source for nvim-cmp
    Plug 'hrsh7th/cmp-path'                    " Completion for paths
    Plug 'hrsh7th/cmp-buffer'                  " Completion from buffer
    Plug 'hrsh7th/cmp-cmdline'                 " Completion for :... commands
    Plug 'hrsh7th/vim-vsnip'                   " Snippet engine
    " Plug 'hrsh7th/vim-vsnip-integ'             " Snippet integration with compe

    " Statusline (bottom)
    Plug 'nvim-lualine/lualine.nvim'

    " Tabline (Top)
    " Plug 'kdheepak/tabline.nvim'
    Plug 'akinsho/bufferline.nvim', { 'tag': '*' }

    " Treesitter
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
    Plug 'nvim-treesitter/playground'

    " Misc
    Plug 'lewis6991/gitsigns.nvim'             " Showins git changes in the gutter
    Plug 'danymat/neogen'                      " Generating documentation comments
    Plug 'lukas-reineke/indent-blankline.nvim' " Showing indentation lines
    Plug 'kevinhwang91/nvim-bqf'               " Get preview in quickfix
    Plug 'windwp/nvim-autopairs'               " Automatically close braces
    Plug 'windwp/nvim-ts-autotag'
    Plug 'voldikss/vim-floaterm'               " Floating terminals. Spooky!
    Plug 'nvim-tree/nvim-tree.lua'
    Plug 'johnfrankmorgan/whitespace.nvim'
    Plug 'tzachar/local-highlight.nvim'
    Plug 'f-person/auto-dark-mode.nvim'
    Plug 'sindrets/diffview.nvim'
    Plug 'LudoPinelli/comment-box.nvim'
    Plug 'mhartington/formatter.nvim'

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
    "Plug 'jose-elias-alvarez/null-ls.nvim'

    " LSP Tools
    Plug 'hrsh7th/cmp-nvim-lsp'                " LSP completion source for nvim-cmp
    Plug 'folke/lsp-colors.nvim'               " Highlight groups for trouble.nvim
    Plug 'folke/trouble.nvim'                  " Pretty diagnostics
    Plug 'nvim-lua/lsp-status.nvim'            " Plugin to show lsp status in statusline
    Plug 'rmagatti/goto-preview'               " Preview LSP definitions
    Plug 'nvim-neotest/neotest'
    Plug 'chrisgrieser/nvim-lsp-endhints'      " Old school end hints

    " navbuddy
    Plug 'SmiteshP/nvim-navic'
    Plug 'MunifTanjim/nui.nvim'
    Plug 'numToStr/Comment.nvim'               " Optional
    Plug 'SmiteshP/nvim-navbuddy'

    " LSP Language Plugins
    Plug 'mrcjkb/rustaceanvim', { 'tag': 'v5.*' }
    Plug 'akinsho/flutter-tools.nvim'
    Plug 'saecki/crates.nvim', { 'tag': 'stable' }

    Plug 'folke/snacks.nvim'

    " Rust
    " Plug 'Canop/nvim-bacon'

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
Plug 'Vimjas/vim-python-pep8-indent', { 'for': ['python'] }
Plug 'nickeb96/fish.vim', { 'for': ['fish'] }
Plug 'pearofducks/ansible-vim'

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
  " Set correct colors. The autodetected colors are not ideal.
  hi! BufferLineFill guibg=#002b36
  hi! BufferLineTab guifg=#586e75 guibg=#002028

  " --- Bufferline Reset ---
  hi! clear BufferLineHint
  hi! clear BufferLineWarningVisible
  hi! clear BufferLineModifiedSelected
  hi! clear BufferLineErrorDiagnosticSelected
  hi! clear BufferLineBackground
  hi! clear BufferLineModified
  hi! clear BufferLineInfo
  hi! clear BufferLineDuplicateVisible
  hi! clear BufferLineBuffer
  hi! clear BufferLineTruncMarker
  hi! clear BufferLineGroupSeparator
  hi! clear BufferLineGroupLabel
  hi! clear BufferLineTabSelected
  hi! clear BufferLineTabClose
  hi! clear BufferLineCloseButton
  hi! clear BufferLineCloseButtonVisible
  hi! clear BufferLineCloseButtonSelected
  hi! clear BufferLineBufferVisible
  hi! clear BufferLineBufferSelected
  hi! clear BufferLineNumbers
  hi! clear BufferLineNumbersSelected
  hi! clear BufferLineNumbersVisible
  hi! clear BufferLineDiagnosticVisible
  hi! clear BufferLineDiagnosticSelected
  hi! clear BufferLineHintVisible
  hi! clear BufferLineHintSelected
  hi! clear BufferLineHintDiagnostic
  hi! clear BufferLineHintDiagnosticVisible
  hi! clear BufferLineHintDiagnosticSelected
  hi! clear BufferLineInfoVisible
  hi! clear BufferLineInfoSelected
  hi! clear BufferLineInfoDiagnostic
  hi! clear BufferLineInfoDiagnosticVisible
  hi! clear BufferLineInfoDiagnosticSelected
  hi! clear BufferLineDiagnostic
  hi! clear BufferLineWarningSelected
  hi! clear BufferLineWarningDiagnostic
  hi! clear BufferLineWarningDiagnosticVisible
  hi! clear BufferLineWarningDiagnosticSelected
  hi! clear BufferLineErrorVisible
  hi! clear BufferLineErrorSelected
  hi! clear BufferLineErrorDiagnostic
  hi! clear BufferLineErrorDiagnosticVisible
  hi! clear BufferLineError
  hi! clear BufferLineModifiedVisible
  hi! clear BufferLineSeparator
  hi! clear BufferLineIndicatorVisible
  hi! clear BufferLinePickSelected
  hi! clear BufferLinePickVisible
  hi! clear BufferLineOffsetSeparator
  hi! clear BufferLineSeparatorVisible
  hi! clear BufferLineTabSeparator
  hi! clear BufferLineTabSeparatorSelected
  hi! clear BufferLineIndicatorSelected
  hi! clear BufferLineSeparatorSelected
  hi! clear BufferLineDuplicate
  hi! clear BufferLineDuplicateSelected
  hi! clear BufferLineWarning
  hi! clear BufferLinePick
  hi! clear BufferLineDevIconDefaultSelected

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

  " --- LSP ---
  hi! LspInlayHint cterm=NONE ctermfg=92 gui=NONE guifg=#586e75 guibg=NONE guisp=NONE " same as Comment

  " --- TreeSitter ---
  hi! TSDefinitionUsage guifg=none guibg=#073642 gui=underline guisp=none

  " --- Fish ---
  hi! fishParameter guibg=none ctermbg=0
  hi! fishOption guibg=none ctermbg=0
endfunction

function! HighlightsLight() abort
  " Set correct colors. The autodetected colors are not ideal.
  hi! BufferLineFill guibg=#fdf6e3
  hi! BufferLineTab guifg=#93a1a1 guibg=#fdf6e3
  hi! BufferLineTabSelected guifg=#93a1a1 guibg=#fdf6e3
  hi! BufferLineBufferSelected guifg=#93a1a1 guibg=#fdf6e3

  " --- Bufferline ---
  hi! clear BufferLineHint
  hi! clear BufferLineWarningVisible
  hi! clear BufferLineModifiedSelected
  hi! clear BufferLineErrorDiagnosticSelected
  hi! clear BufferLineBackground
  hi! clear BufferLineModified
  hi! clear BufferLineInfo
  hi! clear BufferLineDuplicateVisible
  hi! clear BufferLineBuffer
  hi! clear BufferLineTruncMarker
  hi! clear BufferLineGroupSeparator
  hi! clear BufferLineGroupLabel
  hi! clear BufferLineTabSelected
  hi! clear BufferLineTabClose
  hi! clear BufferLineCloseButton
  hi! clear BufferLineCloseButtonVisible
  hi! clear BufferLineCloseButtonSelected
  hi! clear BufferLineBufferVisible
  hi! clear BufferLineBufferSelected
  hi! clear BufferLineNumbers
  hi! clear BufferLineNumbersSelected
  hi! clear BufferLineNumbersVisible
  hi! clear BufferLineDiagnosticVisible
  hi! clear BufferLineDiagnosticSelected
  hi! clear BufferLineHintVisible
  hi! clear BufferLineHintSelected
  hi! clear BufferLineHintDiagnostic
  hi! clear BufferLineHintDiagnosticVisible
  hi! clear BufferLineHintDiagnosticSelected
  hi! clear BufferLineInfoVisible
  hi! clear BufferLineInfoSelected
  hi! clear BufferLineInfoDiagnostic
  hi! clear BufferLineInfoDiagnosticVisible
  hi! clear BufferLineInfoDiagnosticSelected
  hi! clear BufferLineDiagnostic
  hi! clear BufferLineWarningSelected
  hi! clear BufferLineWarningDiagnostic
  hi! clear BufferLineWarningDiagnosticVisible
  hi! clear BufferLineWarningDiagnosticSelected
  hi! clear BufferLineErrorVisible
  hi! clear BufferLineErrorSelected
  hi! clear BufferLineErrorDiagnostic
  hi! clear BufferLineErrorDiagnosticVisible
  hi! clear BufferLineError
  hi! clear BufferLineModifiedVisible
  hi! clear BufferLineSeparator
  hi! clear BufferLineIndicatorVisible
  hi! clear BufferLinePickSelected
  hi! clear BufferLinePickVisible
  hi! clear BufferLineOffsetSeparator
  hi! clear BufferLineSeparatorVisible
  hi! clear BufferLineTabSeparator
  hi! clear BufferLineTabSeparatorSelected
  hi! clear BufferLineIndicatorSelected
  hi! clear BufferLineSeparatorSelected
  hi! clear BufferLineDuplicate
  hi! clear BufferLineDuplicateSelected
  hi! clear BufferLineWarning
  hi! clear BufferLinePick
  hi! clear BufferLineDevIconDefaultSelected

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

  " --- LSP ---
  hi! LspInlayHint cterm=NONE ctermfg=92 gui=NONE guifg=#93a1a1 guibg=NONE guisp=NONE " same as Comment

  " --- TreeSitter ---
  hi! TSDefinitionUsage guifg=none guibg=#eee8d5 gui=underline guisp=none

  " --- Fish ---
  hi! fishParameter guibg=none ctermbg=0
  hi! fishOption guibg=none ctermbg=0
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
au BufRead,BufNewFile *.ds set filetype=rgbds                     " GameBoy Assembly
au BufRead,BufNewFile *.fl,*.flex,*.l,*.lm setlocal ft=lex        " Flex
au BufRead,BufNewFile *.y,*.ypp,*.ym setlocal ft=yacc             " Bison
au BufRead,BufNewFile *.man setlocal ft=groff                     " Groff/Troff
au BufRead,BufNewFile *.mm setlocal ft=objcpp                     " Objective-C++
au BufRead,BufNewFile *.m setlocal ft=objc                        " Objective-C
au BufRead,BufNewFile *.jsx set ft=javascript.jsx                 " Javascript
au BufRead,BufNewFile *.tsx set ft=typescript.tsx                 " TypescriptX
au BufRead,BufNewFile *.ts set ft=typescript                      " Typescript
au BufRead,BufNewFile *.nomad set ft=hcl                          " HCL
au BufRead,BufNewFile *.tf set ft=hcl                             " HCL
au BufRead,BufNewFile *.hcl set ft=hcl                            " HCL
au BufRead,BufNewFile *.tfvars set ft=hcl                         " HCL
au BufRead,BufNewFile *.ex,*.exs set ft=elixir                    " elixir
au BufRead,BufNewFile *.eex,*.leex,*.sface,*.lexs set ft=eelixir  " elixir
au BufRead,BufNewFile mix.lock set ft=elixir                      " elixir
au BufRead,BufNewFile *.heex set ft=heex                          " elixir
au BufRead,BufNewFile Config set ft=conf                          " Brazil config
au BufRead,BufNewFile *.proto set ft=proto                        " Protobuf

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

" Split moving
nnoremap <C-W>B <C-W>H
nnoremap <C-W>N <C-W>J
nnoremap <C-W>R <C-W>K
nnoremap <C-W>S <C-W>L

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
autocmd FileType hcl setlocal comments=:#

" Use Dashes in identifiers
autocmd FileType hcl setlocal iskeyword+=-

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
autocmd FileType proto setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType html setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType htmldjango setlocal ts=2 sts=2 sw=2 expandtab

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
" Auto Pairs (must come before completion)
" =============================================================================
lua <<EOF
local Rule = require('nvim-autopairs.rule')
local npairs = require('nvim-autopairs')
local cond = require('nvim-autopairs.conds')

npairs.setup({
  disable_filetype = {
    'TelescopePrompt',
    'TelescopeResults',
    'Trouble',
    'help',
    'mason',
    'floaterm',
    'Terminal',
    'gitcommit',
    'vim-plug',
    'lspinfo',
    'vim',
    'packer',
    'checkhealth',
    'man',
  },
})

local Rule = require("nvim-autopairs.rule")
npairs.add_rules({
  Rule("<", ">", { "-html", "-javascriptreact", "-typescriptreact" })
    :with_pair(cond.not_after_regex("[%w%.]"))
    :with_pair(cond.before_regex("%a+:?:?$", 3))
    :with_move(function(opts)
      return opts.char == ">"
    end),
  Rule("```", "```", { "rust", "markdown", "vimwiki", "rmarkdown", "rmd", "pandoc", "quarto" })
      :with_pair(cond.not_before_char('`', 3)),
  Rule("```.*$", "```", { "rust", "markdown", "vimwiki", "rmarkdown", "rmd", "pandoc", "quarto" }):only_cr():use_regex(true),
})
EOF

" =============================================================================
" autotag (autoclose html)
" =============================================================================
lua <<EOF
require('nvim-ts-autotag').setup({
  opts = {
    -- Defaults
    enable_close = true, -- Auto close tags
    enable_rename = true, -- Auto rename pairs of tags
    enable_close_on_slash = true, -- Auto close on trailing </
  },
  aliases = {
    ["htmldjango"] = "html",
  },
  -- Also override individual filetype configs, these take priority.
  -- Empty by default, useful if one of the "opts" global settings
  -- doesn't work well in a specific filetype
  per_filetype = {
    ["html"] = {
      --enable_close = false
    },
    ["htmldjango"] = {
      enable_close = true, -- Auto close tags
      enable_rename = true, -- Auto rename pairs of tags
      enable_close_on_slash = true, -- Auto close on trailing </
    }
  }
})
EOF

" =============================================================================
" Completion
" =============================================================================
" Must come before LSP.
" See https://github.com/hrsh7th/nvim-cmp#basic-configuration
lua <<EOF
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
      local is_jumpable = vim.api.nvim_cmd({
        cmd = "echo",
        args = { "vsnip#jumpable(-1)" },
      }, { output = true })

      if cmp.visible() then
        cmp.select_prev_item()
      elseif is_jumpable == "0" then
        return
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
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on('confirm_done', function()
  cmp_autopairs.on_confirm_done()
end)


EOF

" =============================================================================
" LSP INSTALLER
" =============================================================================
lua << EOF
local registry = require("mason-registry")
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

-- Exception for AL2 - prefer the manually installed rust-analyzer
if vim.g['isDevDsk'] then
  vim.env.PATH = os.getenv('HOME') .. '/.cargo/bin:' .. vim.env.PATH
end

-- Mostly Supported Servers:
--  "tsserver",
--  "eslint",
--  "gopls",
--  "bashls",
--  "lua_ls",
--  "vimls",
--  "jedi_language_server", -- python
--  "pylsp", -- depends on the above
--  "rnix",
--  "elixirls",
--  "erlangls",
--  "clangd",
--  "cmake",
require('mason-lspconfig').setup {
  automatic_installation = false,
  ensure_installed = {
    "yamlls",
    "bashls",
    "lua_ls",
    "vimls",
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
-- https://github.com/neovim/neovim/issues/23291
lsp_defaults.capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

lsp_status.register_progress()


-- Global `on_attach`
local function on_attach(client, bufnr)
  -- This produces errors due to lspconfig bug: https://github.com/neovim/nvim-lspconfig/issues/2542
  --if client.server_capabilities then
  --  client.server_capabilities.semanticTokensProvider = nil
  --end

  if vim.g['has_navigator'] ~= 0 then
    require('navigator.lspclient.mapping').setup({ client=client, bufnr=bufnr }) -- setup navigator keymaps here,
    require('navigator.dochighlight').documentHighlight(bufnr)
    if client:supports_method('textDocument/codeAction', bufnr) then
      require('navigator.codeAction').code_action_prompt(bufnr, {})
    end

    local navigator_bindings = {
      { 'n', '<c-]>', "<cmd>lua require('navigator.definition').definition()<CR>", '' },
      { 'n', 'gd', "<cmd>lua require('navigator.definition').definition_preview()<CR>", 'LSP: Preview Definition' },
      { 'n', '<leader>rn', "<cmd>lua require('navigator.rename').rename()<CR>", 'LSP: Rename Symbol' },
      { 'n', '<leader>k', "<cmd>lua require('navigator.diagnostics').show_diagnostics()<CR>", 'LSP: Show Diagnostic Under Cursor' },
    }
    for _, kb in ipairs(navigator_bindings) do
      vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4], buffer = bufnr })
    end
  end

  -- setup buffer keymaps etc.
  lsp_status.on_attach(client)
  if client:supports_method('textDocument/documentSymbol', bufnr)
    and client.server_capabilities.documentSymbolProvider then
    navbuddy.attach(client, bufnr)
  end

  -- Turn on inlay hints
  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
end

local function on_init(client, init_result)
  -- disable highlighting from lsp
  if client.server_capabilities then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.semanticTokensProvider = false  -- turn off semantic tokens
  end
end

-- Borders
local _border = {
  -- Second argument is the highlight group name.
  { '┌', 'FloatBorder' },
  { '─', 'FloatBorder' },
  { '┐', 'FloatBorder' },
  { '│', 'FloatBorder' },
  { '┘', 'FloatBorder' },
  { '─', 'FloatBorder' },
  { '└', 'FloatBorder' },
  { '│', 'FloatBorder' },
}

-- Starting from v0.11 nvim has builtin borders.
if vim.fn.has('nvim-0.11') == 1 then
  vim.o.winborder = 'rounded'
end

-- Add the border on hover and on signature help popup window
local handlers = {
  ['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = _border }),
  ['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = _border }),
  -- Disable virtual text for diagnostics.
  ['textDocument/publishDiagnostics'] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false, }
  ),
}


-- Add border to the diagnostic popup window
vim.diagnostic.config({
    -- Enabled
    --virtual_text = {
    --    prefix = '■ ', -- Could be '●', '▎', 'x', '■', , 
    --},
    -- Disabled
    virtual_text = false,
    signs = true,
    float = { border = _border },
    -- Available from v0.11:
    virtual_lines = { current_line = true },
})

require('lspconfig.ui.windows').default_options = {
  border = _border
}

-- Crates.nvim
require("crates").setup {
  lsp = {
    enabled = true,
    on_attach = function(client, bufnr)
      -- the same on_attach function as for your other lsp's
      local crates = require("crates")
      local opts = { silent = true, buffer = bufnr, noremap = false }
      local show_versions_popup = function()
        crates.show_versions_popup()
        crates.focus_popup()
      end
      local show_features_popup = function()
        crates.show_features_popup()
        crates.focus_popup()
      end
      local show_dependencies_popup = function()
        crates.show_dependencies_popup()
        crates.focus_popup()
      end
      vim.keymap.set('n', '<leader>cv', show_versions_popup, vim.tbl_extend('force', opts, { desc = 'view crate versions' }))
      vim.keymap.set('n', '<leader>cf', show_features_popup, vim.tbl_extend('force', opts, { desc = 'view crate features' }))
      vim.keymap.set('n', '<leader>cd', show_dependencies_popup, vim.tbl_extend('force', opts, { desc = 'view crate dependencies' }))

      local wk = require("which-key")
      wk.add({{ "<Leader>c", group = "crates.io", icon = "" }})
    end,
    actions = true,
    completion = true,
    hover = true,
  },
  popup = {
    border = _border,
    keys = {
      hide = { "q", "<esc>" },
      open_url = { "<cr>" },
      select = { "<cr>" },
      select_alt = { "s" },
      toggle_feature = { "<cr>" },
      copy_value = { "yy" },
      goto_item = { "gd", "K", "<C-LeftMouse>" },
      jump_forward = { "<c-n>" },
      jump_back = { "<c-r>", "<C-RightMouse>" },
    },
  },
  completion = {
    crates = {
      enabled = true, -- disabled by default
      max_results = 8, -- The maximum number of search results to display
      min_chars = 3, -- The minimum number of charaters to type before completions begin appearing
    },
  },
}

-- Rust
vim.g.rustaceanvim = function()
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

  local rust_analyzer_capabilities = vim.tbl_deep_extend(
    'force',
    lsp_defaults.capabilities,
    -- https://github.com/rust-lang/rust-analyzer/issues/12613
    { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } }
  );

  local cfg = require('rustaceanvim.config')
  return {
    -- Plugin configuration
    ---@type rustaceanvim.tools.Opts
    tools = {
      reload_workspace_from_cargo_toml = true,
      float_win_config = {
        border = 'rounded',
      },
    },

    -- DAP configuration
    ---@type rustaceanvim.dap.Opts
    dap = {
      adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path)
    },

    -- LSP configuration
    ---@type rustaceanvim.lsp.ClientOpts
    server = {
      on_attach = on_attach,
      on_init = on_init,
      handlers = handlers,
      capabilities = rust_analyzer_capabilities,
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
        CargoReload = {
          function()
            local util = require 'lspconfig.util'
            local bufnr = 0 -- current buffer
            bufnr = util.validate_bufnr(bufnr)
            local clients = util.get_lsp_clients { bufnr = bufnr, name = 'rust-analyzer' }
            for _, client in ipairs(clients) do
              vim.notify 'Reloading Cargo Workspace'
              client.request('rust-analyzer/reloadWorkspace', nil, function(err)
                if err then
                  print('error:' .. tostring(err))
                  error(tostring(err))
                end
                vim.notify 'Cargo workspace reloaded'
              end, 0)
            end
          end,
          description = 'Reload current cargo workspace',
        },
      },
      -- If rust-analyzer isn't working, try the following:
      -- 1. `cargo clean`
      -- 2. `rm -rf target`
      -- 3. `rm Cargo.lock && cargo build`
      default_settings = {
        -- Options documented here: https://rust-analyzer.github.io/book/configuration.html
        ["rust-analyzer"] = {
          cargo = {
            features = "all",
            --cfgs = {"debug_assertions", "miri", "unix"},
            --features = {},
            --noDefaultFeatures = true,

            -- Optional enable:
            -- targets = nil,
            -- allTargets = true,
            targetDir = true,
            -- extraEnv = { CARGO_TARGET_DIR = '.ra_target' },
            -- target = "x86_64-unknown-linux-gnu",

            autoreload = false,
            buildScripts = {
              enable = true,
            },
          },

          -- Disable `cargo check` on save. Use `bacon-ls` instead.
          checkOnSave = false,
          check = {
            command = "check",
            -- Clippy eats more resources and takes longer.
            -- command = "clippy",

            -- Use command or overrideCommand:
            -- overrideCommand = "clippy --tests --all-features --all-targets --message-format json-diagnostic-rendered-ansi",
          },

          diagnostics = {
            enable = false,
            experimental = {
              enable = false,
            },
          },

          hover = {
            memoryLayout = {
              niches = true,
            },
            show = {
              enumVariants = 20,
              fields = 20,
            },
          },

          completion = {
            fullFunctionSignatures = {
              enable = true,
            },
          },

          imports = {
            -- Enable for `no_std` projects.
            preferNoStd = false,
            granularity = {
              group = "module",
            },
            prefix = "self",
          },

          inlayHints = {
            -- Whether to show inlay hints for closure captures
            closureCaptureHints = { enable = true },
            -- Whether to show inlay type hints for return types of closures.
            closureReturnTypeHints = { enable = true },
            -- Whether to show implicit drop hints
            implicitDrops = { enable = true },
            -- Whether to show generic type parameter name inlay hints
            genericParameterHints = { type = { enable = true } },
          },

          lru = {
            -- defaults to 128
            capacity = 512,
          },
          -- nil means pick automatically
          -- numThreads = nil,

          procMacro = {
            enable = true,
            attributes = {
              enable = true,
            },
          },

          --rustfmt = {
          --  -- Only available on nightly.
          --  rangeFormatting = { enable = false },
          --},

          workspace = {
            symbol = {
              search = {
                -- defaults to 128
                limit = 64,
              },
            },
          },
        },
      },
    },
  }
end -- rust config

require("mason-lspconfig").setup_handlers {
    -- The first entry (without a key) will be the default handler
    -- and will be called for each installed server that doesn't have
    -- a dedicated handler.
    function (server_name) -- default handler (optional)
        lspconfig[server_name].setup {
          on_attach = on_attach,
          on_init = on_init,
          handlers = handlers,
          capabilities = lsp_defaults.capabilities,
        }
    end,
    -- Next, you can provide a dedicated handler for specific servers.
    ["rust_analyzer"] = function ()
      --custom setup here ...
    end,
    ["yamlls"] = function ()
      lspconfig["yamlls"].setup {
        settings = {
          yaml = {
            keyOrdering = false
          }
        }
      }
    end
}

-- Rust Analyzer is special. We might install it in a multitude of ways.
if not registry.is_installed('rust-analyzer') then
  --custom setup here ...
end

if vim.fn.executable('bacon-ls') ~= 0 then
  -- find location with: `:lua =require('vim.lsp.log').get_filename()`
  --vim.lsp.set_log_level('debug')
  --if vim.fn.has 'nvim-0.5.1' == 1 then
  --  require('vim.lsp.log').set_format_func(vim.inspect)
  --end

  require("lspconfig").bacon_ls.setup({
    cmd = { 'bacon-ls' },
    --cmd = { '/local/home/gerstarv/github/bacon-ls/target/release/bacon-ls' },
    single_file_support = false,
    on_attach = on_attach,
    on_init = on_init,
    handlers = handlers,
    capabilities = lsp_defaults.capabilities,
    init_options = {
      updateOnSave = true,
      updateOnSaveWaitMillis = 200,
      updateOnChange = false,
      runBaconInBackground = false,
      synchronizeAllOpenFilesWaitMillis = 1000,
      -- BETA:
      useCargoBackend = true,
      cargoEnv = "CARGO_TARGET_DIR=.checkTarget",
      cargoCommandArguments = "check --tests --all-targets --message-format json-diagnostic-rendered-ansi",
      -- Clippy takes longer.
      -- cargoCommandArguments = "clippy --tests --all-targets --message-format json-diagnostic-rendered-ansi",

      -- This copies the entire source tree to a temporary directory, and will
      -- therefore not work for most cases.
      updateOnChange = false,
      updateOnChangeCooldownMillis = 5000,
    },
  })
end

if vim.fn.executable('fish-lsp') ~= 0 then
  require('lspconfig').fish_lsp.setup({
    on_attach = on_attach,
    on_init = on_init,
    handlers = handlers,
    capabilities = lsp_defaults.capabilities,
  })
end

-- Custom CargoReload
function cargo_reload()
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.name == 'rust-analyzer' then
      client.commands['CargoReload'][1]()
    end
  end
end

vim.api.nvim_create_user_command('CargoReload', cargo_reload, {})

-- Flutter/Dart
require("flutter-tools").setup{
  lsp = {
    on_attach = on_attach,
  },
}

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
" lua <<EOF
" local null_ls = require("null-ls")

" null_ls.setup({
"     sources = {
"         --null_ls.builtins.diagnostics.mypy,
"         --null_ls.builtins.diagnostics.eslint,
"         --null_ls.builtins.completion.spell,
"         --null_ls.builtins.diagnostics.typos,
"     },
" })
" EOF

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

nnoremap <leader>xd <cmd>TroubleToggle workspace_diagnostics<CR>


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
if vim.g['has_navigator'] ~= 0 then
  -- default mapping
  --maps = {
  --  close_view = '<C-e>',
  --  send_qf = '<C-q>',
  --  save = '<C-s>',
  --  jump_to_list = '<C-w>k',
  --  jump_to_preview = '<C-w>j',
  --  prev = '<C-p>',
  --  next = '<C-n>',
  --  pageup = '<C-b>',
  --  pagedown = '<C-f>',
  --  confirm = '<C-o>',
  --  split = '<C-s>',
  --  vsplit = '<C-v>',
  --  tabnew = '<C-t>',
  --}

  require('guihua.maps').setup({
    maps = {
      close_view = '<C-x>',
      prev = '<C-r>',
      next = '<C-n>',
    }
  })

  require'navigator'.setup({
    -- lsp servers are installed via `mason`.
    mason = true,
    -- disable all lsp server integration, requires manual setup via `on_attach`.
    lsp = {
      disable_lsp = 'all',
      format_on_save = false,
      diagnostic = {
        underline = true,
        virtual_text = true, -- show virtual for diagnostic message
        update_in_insert = false, -- don't update diagnostic message in insert mode
        float = {
          focusable = true,
          sytle = 'minimal',
          border = 'rounded',
          source = 'always',
          header = '',
          prefix = '',
        },
      },
    },

    border = 'single',
    --border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"},
    transparency = nil,
    on_attach = function(client, bufnr)
        --print("navigator on_attach")
    end,

    default_mapping = false,
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
  })
end

EOF


" =============================================================================
" LSPSAGA
" =============================================================================
lua <<EOF
if vim.g['has_lspsaga'] ~= 0 then
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
        quit = 'q',
        exec = '<CR>'
      },
      rename_action_keys = {
        quit = '<C-c>',
        exec = '<CR>'
      },
      definition_preview_icon = '➤',
      border_style = "single",
      rename_prompt_prefix = '➤',
      server_filetype_map = {}
  }
end
EOF

lua <<EOF
local lsp_bindings = {
  { 'i', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', 'LSP: Signature Help' },

  { 'n', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', 'LSP: Signature Help' },
  { 'n', 'K', '<cmd>lua vim.lsp.buf.hover({ popup_opts = { border = single, max_width = 120 }})<CR>', 'LSP: Hover Docs' },
  { 'n', '<leader>re', '<cmd>lua vim.lsp.buf.rename()<CR>', 'LSP: Rename' },

  { 'n', '[e', "<cmd>lua vim.diagnostic.goto_next({ border = 'rounded', max_width = 80 })<CR>", 'LSP: Next Diagnostic' },
  { 'n', ']e', "<cmd>lua vim.diagnostic.goto_prev({ border = 'rounded', max_width = 80 })<CR>", 'LSP: Prev Diagnostic' },
}

if vim.g['has_lspsaga'] ~= 0 then
  local lspsaga_bindings = {
    { 'n', 'gd', "<cmd>:Lspsaga preview_definition<CR>", 'LSP: Preview Definition' },
    { 'n', '<Leader>rn', "<cmd>:Lspsaga rename<CR>", 'LSP: Rename' },
    { 'n', '<Leader>k', "<cmd>lua require'lspsaga.diagnostic'.show_cursor_diagnostics()<CR>", 'LSP: Show Diagnostic Under Cursor' },
    { 'n', '<S-h>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", '' },
    { 'n', '<S-l>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", '' },
  }
  for _, kb in ipairs(lspsaga_bindings) do table.insert(lsp_bindings, kb) end
end

if vim.g['has_navigator'] ~= 0 then
  local navigator_bindings = {
    { 'n', '<c-]>', "<cmd>lua require('navigator.definition').definition()<CR>", '' },
    { 'n', 'gd', "<cmd>lua require('navigator.definition').definition_preview()<CR>", 'LSP: Preview Definition' },
    { 'n', '<leader>rn', "<cmd>lua require('navigator.rename').rename()<CR>", 'LSP: Rename Symbol' },
    { 'n', '<leader>k', "<cmd>lua require('navigator.diagnostics').show_diagnostics()<CR>", 'LSP: Show Diagnostic Under Cursor' },
  }
  for _, kb in ipairs(navigator_bindings) do table.insert(lsp_bindings, kb) end
end


for _, kb in ipairs(lsp_bindings) do
  vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
end

EOF

" nnoremap <silent><Leader>k <cmd>lua vim.diagnostic.open_float(0, { scope = "line" })<CR>


" =============================================================================
" GitSigns
" =============================================================================
lua << EOF
local function gitsigns_keymap_attach(bufnr)
  local autocmd = vim.api.nvim_create_autocmd
  local function opts(desc)
    return { desc = 'git: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  --vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
  --vim.api.nvim_buf_set_keymap(bufnr, 'n', 'hs', '<cmd>lua require"gitsigns".stage_hunk()<CR>', {})

  local function blame_file()
    local function cb(opts)
      print('callback!' .. vim.inspect(opts))
      vim.keymap.set('n', 'r', '<Up>', { noremap = true, silent = true, buffer = opts.buf })
    end
    require("gitsigns").blame(cb)
  end

  vim.keymap.set('n', '<leader>ss', '<cmd>Gitsigns stage_hunk<CR>', opts('Stage Hunk'))
  vim.keymap.set('n', '<leader>su', '<cmd>Gitsigns undo_stage_hunk<CR>', opts('Undo Staging Hunk'))
  vim.keymap.set('n', '<leader>sr', '<cmd>Gitsigns reset_hunk<CR>', opts('Reset Hunk'))
  vim.keymap.set('n', '<leader>sR', '<cmd>Gitsigns reset_buffer<CR>', opts('Reset Buffer'))
  vim.keymap.set('n', '<leader>sp', '<cmd>Gitsigns preview_hunk<CR>', opts('Preview Hunk'))
  vim.keymap.set('n', '<leader>sb', '<cmd>lua require"gitsigns".blame_line{full=true, ignore_whitespace=true}<CR>', opts('Blame Line'))
  vim.keymap.set('n', '<leader>sB', blame_file, opts('Blame File'))
  vim.keymap.set('n', '<leader>sS', '<cmd>Gitsigns stage_buffer<CR>', opts('Stage Buffer'))
  vim.keymap.set('n', '<leader>sU', '<cmd>Gitsigns reset_buffer_index<CR>', opts('Reset Buffer Index'))

  vim.keymap.set('v', '<leader>sr', ':Gitsigns reset_hunk<CR>', opts('ResetHunk (Visual)'))
  vim.keymap.set('v', '<leader>ss', ':Gitsigns stage_hunk<CR>', opts('StageHunk (Visual)'))

  autocmd('FileType', {
    pattern = 'gitsigns-blame',
    callback = function(opts)
      vim.keymap.set('n', 'r', '<Up>', { noremap = false, silent = true, buffer = opts.buf })
    end,
  })
end

require('gitsigns').setup({
  on_attach = gitsigns_keymap_attach,
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`

  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',

  signs = {
    add          = { text = '│' },
    change       = { text = '│' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '┃' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = true,
})
EOF


" =============================================================================
" Treesitter
" =============================================================================
lua <<EOF
require'nvim-treesitter.configs'.setup {
    ensure_installed = {'rust', 'json', 'javascript', 'typescript', 'tsx', 'vim', 'lua', 'go', 'haskell', 'bash', 'markdown', 'markdown_inline', 'python', 'html'},
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
wk.add({
  { "<C-W>", group = "window" },
  { "<C-W>H", desc = "move current window to the far left" },
  { "<C-W>J", desc = "move current window to the very bottom" },
  { "<C-W>K", desc = "move current window to the very top" },
  { "<C-W>L", desc = "move current window to the far right" },
})

wk.add({
  { "<leader>,", group = "zoom" },
  { "<leader>a", group = "picker" },
  { "<leader>b", group = "debugger" },
  { "<leader>c", group = "codeaction" },
  { "<leader>d", group = "lsp" },
  { "<leader>f", group = "findfiles" },
  { "<leader>g", group = "diagnostics/+jump" },
  { "<leader>n", group = "neogen" },
  { "<leader>q", group = "quickfix" },
  { "<leader>r", group = "rename" },
  { "<leader>s", group = "git" },
  { "<leader>x", group = "trouble" },
})
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
  --debug = true,
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
  ignored_filetypes = {
    'TelescopePrompt',
    'Trouble',
    'help',
    'mason',
    'floaterm',
    'Terminal',
    'gitcommit',
    'vim-plug',
    'lspinfo',
    'crates.nvim',
  },
})
EOF

" =============================================================================
" local highlight
" =============================================================================
lua <<EOF
require('local-highlight').setup({
  animate = false,
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
  hint = 'floating-big-letter',
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
    preserve_window_proportions = true,
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
" formatter.nvim
" =============================================================================
lua <<EOF
-- Utilities for creating configurations
local util = require "formatter.util"
local autocmd = vim.api.nvim_create_autocmd

local filetypes = {
  sh = {
    require("formatter.filetypes.sh").shfmt,
  },
  python = {
    require("formatter.filetypes.python").black,
    --require("formatter.filetypes.python").isort,
  },
  rust = {
    require("formatter.filetypes.rust").rustfmt,
  },
  lua = {
    require("formatter.filetypes.lua").stylua,
  },
  javascript = {
    require("formatter.filetypes.javascript").prettier,
  },
  ["javascript.tsx"] = {
    require("formatter.filetypes.javascriptreact").prettier,
  },
  typescript = {
    require("formatter.filetypes.typescript").prettier,
  },
  ["typescript.tsx"] = {
    require("formatter.filetypes.typescriptreact").prettier,
  },
  css = {
    require("formatter.filetypes.css").prettier,
  },
  json = {
    require("formatter.filetypes.json").prettier,
  },
  yaml = {
    require("formatter.filetypes.yaml").prettier,
  },
  html = {
    require("formatter.filetypes.html").prettier,
  },
  htmldjango = {
    require("formatter.filetypes.html").prettier,
  },
  vue = {
    require("formatter.filetypes.vue").prettier,
  },
  hcl = {
    function()
      return {
        exe = 'tofu',
        args = {
          'fmt',
        },
        stdin = false,
      }
    end,
  },
}

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup {
  -- Enable or disable logging
  logging = true,
  -- Set the log level
  log_level = vim.log.levels.WARN,
  -- All formatter configurations are opt-in
  filetype = vim.tbl_deep_extend("force", filetypes, {
    -- Use the special "*" filetype for defining formatter configurations on
    -- any filetype
    ["*"] = {
      -- "formatter.filetypes.any" defines default configurations for any filetype
      --require("formatter.filetypes.any").remove_trailing_whitespace,
      -- Remove trailing whitespace without 'sed'
      require("formatter.filetypes.any").substitute_trailing_whitespace,
    }
  })
}

for k,_ in pairs(filetypes) do
  -- equivalent: autocmd FileType gn nnoremap <buffer> <C-f> :Autoformat<CR>
  if k == "javascriptreact" then
    k = "javascript.tsx"
  elseif k == "typescriptreact" then
    k = "typescript.tsx"
  end
  autocmd('FileType', {
    pattern = k,
    callback = function(opts)
      vim.keymap.set('n', '<C-f>', ':FormatWriteLock<CR>', { noremap = false, silent = true, buffer = opts.buf })
    end,
  })
end

EOF

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

    autocmd FileType c noremap <buffer> <C-f> :call UncrustifyWrapper('c')<CR>
    autocmd FileType c vnoremap <buffer> <C-f> :call RangeUncrustifyWrapper('c')<CR>
    autocmd FileType cs noremap <buffer> <C-f> :call UncrustifyWrapper('cs')<CR>
    autocmd FileType cs vnoremap <buffer> <C-f> :call RangeUncrustifyWrapper('cs')<CR>
    autocmd FileType cpp noremap <buffer> <C-f> :call UncrustifyWrapper('cpp')<CR>
    autocmd FileType cpp vnoremap <buffer> <C-f> :call RangeUncrustifyWrapper('cpp')<CR>
    autocmd FileType objc noremap <buffer> <C-f> :call UncrustifyWrapper('objc')<CR>
    autocmd FileType objc vnoremap <buffer> <C-f> :call RangeUncrustifyWrapper('objc')<CR>
    autocmd FileType objcpp noremap <buffer> <C-f> :call UncrustifyWrapper('objcpp')<CR>
    autocmd FileType objcpp vnoremap <buffer> <C-f> :call RangeUncrustifyWrapper('objcpp')<CR>
endif

" =============================================================================
" Vsnip
" =============================================================================
" Snippet syntax described here:
" <https://github.com/Microsoft/language-server-protocol/blob/master/snippetSyntax.md>

" Expand
imap <expr> <C-n>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-n>'
smap <expr> <C-n>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-n>'

" Expand or jump
imap <expr> <C-s>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-s>'
smap <expr> <C-s>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-s>'

" Jump forward or backward
imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
" Issues: <https://github.com/hrsh7th/nvim-cmp/issues/770>
imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'

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
  {'n', '<leader>gn', "<cmd>lua require('telescope.builtin').diagnostics({ bufnr = 0 })<cr>", 'LSP: Show Current File Diagnostics' },
  {'n', '<leader>ca', "<cmd>lua vim.lsp.buf.code_action()<cr>", 'LSP: Code Actions' },
  {'v', '<leader>ca', "<cmd>lua vim.lsp.buf.code_action({ range = { start = vim.api.nvim_buf_get_mark(vim.api.nvim_get_current_buf(), '<'), ['end'] = vim.api.nvim_buf_get_mark(vim.api.nvim_get_current_buf(), '>') }})<cr>", 'LSP: Code Actions' },
  {'n', '<leader>gi', "<cmd>lua require('telescope.builtin').lsp_implementations()<cr>", 'LSP: Show Implementations' },
  {'n', '<leader>gg', "<cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>", 'LSP: Show Document Symbols' },
  {'n', '<leader>ge', "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<cr>", 'LSP: Show Workspace Symbols' },
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
lua <<EOF

local ej_bindings = {
  { 'n', '<Leader>h',  '<Plug>EnhancedJumpsOlder', 'EJ: Jump Older' },
  { 'n', '<Leader>l',  '<Plug>EnhancedJumpsNewer', 'EJ: Jump Newer' },
  { 'n', '<Leader>gh', '<Plug>EnhancedJumpsLocalOlder', 'EJ: Jump Older (Local)' },
  { 'n', '<Leader>gl', '<Plug>EnhancedJumpsLocalNewer', 'EJ: Jump Newer (Local)' },
}

for _, kb in ipairs(ej_bindings) do
  vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
end

EOF

" =============================================================================
" Vim Visual Multi (VM)
" =============================================================================
" TODO?: Add 'custom motions':
" <https://github.com/mg979/vim-visual-multi/blob/a6975e7c1ee157615bbc80fc25e4392f71c344d4/doc/vm-settings.txt#L124>

" Find default mappings here:
" <https://github.com/mg979/vim-visual-multi/blob/a6975e7c1ee157615bbc80fc25e4392f71c344d4/autoload/vm/maps/all.vim#L80>
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
let g:VM_maps["Replace"]   = '' " previously 'R'
let g:VM_maps["Replace Characters"]   = '' " previously 'r'
let g:VM_maps["Replace Pattern"] = ''
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

lua <<EOF
local augroup = vim.api.nvim_create_augroup   -- Create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd   -- Create autocommand
local mark_bindings = {
  {'n', 'mm', ':BookmarkToggle<CR>', 'Toggle' },
  {'n', 'mi', ':BookmarkAnnotate<CR>', 'Annotate' },
  {'n', 'mn', ':BookmarkNext<CR>', 'Next' },
  {'n', 'mr', ':BookmarkPrev<CR>', 'Prev' },
  {'n', 'ma', ':BookmarkShowAll<CR>', 'Show All' },
  {'n', 'md', ':BookmarkClear<CR>', 'Clear' },
  {'n', 'mx', ':BookmarkClearAll<CR>', 'Clear All' },
  {'n', 'mh', ':BookmarkMoveUp<CR>', 'Move Up' },
  {'n', 'ml', ':BookmarkMoveDown<CR>', 'Move Down' },
  {'n', 'mg', ':BookmarkMoveToLine<CR>', 'Move To Line' },
  {'n', 'mA', "<cmd>lua require('telescope.builtin').marks()<cr>", 'Show All (Telescope)' },
};

autocmd('BufEnter', {
  pattern = '*',
  callback = function()
    -- Don't set mappings in nerdtree
    if vim.bo.filetype == 'nerdtree' then
      return
    end

    for _, kb in ipairs(mark_bindings) do
      vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4], buffer = true })
    end
  end,
})

autocmd('FileType', {
  pattern = 'nerdtree',
  callback = function()
    for _, kb in ipairs(mark_bindings) do
      vim.keymap.del(kb[1], kb[2], { buffer = true })
    end
  end,
})
EOF

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
let g:floaterm_keymap_new    = ',a'
let g:floaterm_keymap_toggle = ',n'
let g:floaterm_keymap_prev   = ',b'
let g:floaterm_keymap_next   = ',s'
let g:floaterm_keymap_kill   = ',Q'
let g:floaterm_keymap_hide   = ',q'
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8

" This will insert a `,` into the terminal.
tnoremap   <silent>   ,,   <C-\><C-n>i,

lua <<EOF
local wk = require("which-key")
wk.add({
  { ",", group = "floaterm", mode = { "n", "t" } },
  { ",b", desc = "Previous Terminal", mode = { "n", "t" } },
  { ",a", desc = "New Terminal", mode = { "n", "t" } },
  { ",s", desc = "Next Terminal", mode = { "n", "t" } },
  { ",n", desc = "Toggle Terminal", mode = { "n", "t" } },
  { ",Q", desc = "Kill Terminal", mode = { "n", "t" } },
  { ",q", desc = "Hide Terminal", mode = { "n", "t" } },
  { ",,", desc = "Insert `,`", mode = { "n", "t" } },
})
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
" Keybinds:
" [c -> jump to next
" ]c -> jump to prev
lua <<EOF
local actions = require("diffview.actions")
require("diffview").setup({
  view = {
    merge_tool = {
      layout = "diff4_mixed",
      disable_diagnostics = true,
    },
  },
  keymaps = {
    disable_defaults = false,
    diff4 = {
      -- Mappings in 4-way diff layouts
      { { "n", "x" }, "1do", actions.diffget("base"), { desc = "Obtain the diff hunk from the BASE version of the file" } },
      { { "n", "x" }, "2do", actions.diffget("ours"), { desc = "Obtain the diff hunk from the OURS version of the file" } },
      { { "n", "x" }, "3do", actions.diffget("theirs"), { desc = "Obtain the diff hunk from the THEIRS version of the file" } },
      { "n",          "g?", actions.help({ "view", "diff4" }), { desc = "Open the help panel" } },
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

"   ┣━━━━━━━━━━━━━━━━━━━━━━━━━┫ comment-box.nvim ┣━━━━━━━━━━━━━━━━━━━━━━━━━┫
lua <<EOF
require('comment-box').setup({
  comment_style = "line",
  doc_width = 80, -- width of the document
  box_width = 60, -- width of the boxes
})

local wk = require("which-key")
wk.add({
  { "<Leader>c", group = "Boxes", icon = "" },
  { "<Leader>cb", "<Cmd>CBlcbox3<CR>", desc = "Box Title Heavy" },
  { "<Leader>cbl", "<Cmd>CBllbox3<CR>", desc = "Box Title Left" },
  { "<Leader>cbs", "<Cmd>CBlcbox2<CR>", desc = "Box Title Light" },
  { "<Leader>ct", "<Cmd>CBccline11<CR>", desc = "Line Title (Center)" },
  { "<Leader>ctl", "<Cmd>CBllline9<CR>", desc = "Line Title (Left)" },
  { "<Leader>cl", "<Cmd>CBline0<CR>", desc = "Line" },
  { "<Leader>cm", "<Cmd>CBllbox18<CR>", desc = "Box Enclosed" },
  { "<Leader>cx", "<Cmd>CBd<CR>", desc = "Remove a box" },
})
EOF

"   ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫ neotest ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
lua <<EOF
require('neotest').setup {
  adapters = {
   require('rustaceanvim.neotest'),
  },
}

local wk = require("which-key")
wk.add({
  { "<Leader>x", group = "Test", icon = "" },
  { "<leader>xx", function() require('neotest').run.run() end, desc = "Test Nearest" },
  { "<leader>xa", function() require('neotest').run.run(vim.fn.expand("%")) end, desc = "Test File" },
  { "<leader>xo", function() require('neotest').output.open({ enter = true }) end, desc = "Open Output" },
  { "<leader>xp", function() require('neotest').output_panel.toggle() end, desc = "Open Output Panel" },
  { "<leader>xq", function() require('neotest').output_panel.clear() end, desc = "Clear Output Panel" },
  { "<leader>xw", function() require('neotest').run.attach() end, desc = "Test Watch" },
})
EOF

"   ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━┫ lsp endhints ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
lua <<EOF
require("lsp-endhints").setup {
	icons = {
		type = "⮜ ",
		parameter = "↳ ",
		offspec = "⮜ ", -- hint kind not defined in official LSP spec
		unknown = "⮾ ", -- hint kind is nil
	},
	label = {
		truncateAtChars = 80,
		padding = 0,
		marginLeft = 0,
		sameKindSeparator = ", ",
	},
	autoEnableHints = true,
}
EOF


"          ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
"          ┃           ALWAYS KEEP AT THE ABSOLUTE BOTTOM!            ┃
"          ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
" =============================================================================
" auto-dark-mode
" =============================================================================
lua <<EOF
local auto_dark_mode = require('auto-dark-mode')
vim.g["custom#isdarkmode"] = 1

function enable_dark_mode()
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
end

function enable_light_mode()
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
end

vim.api.nvim_create_user_command('EnableLightMode', enable_light_mode, {})
vim.api.nvim_create_user_command('EnableDarkMode', enable_dark_mode, {})

if not vim.g["isRemoteSession"] then
  auto_dark_mode.setup({
    update_interval = 5000,
    set_dark_mode = function()
      enable_dark_mode()
    end,

    set_light_mode = function()
      enable_light_mode()
    end,
  })
end
EOF

lua <<EOF
local snacks = require('snacks')
snacks.toggle.profiler():map("<leader>pp")
EOF


" =============================================================================
"             | |    __ _ _ __   __ _ _   _  __ _  __ _  ___  ___
"             | |   / _` | '_ \ / _` | | | |/ _` |/ _` |/ _ \/ __|
"             | |__| (_| | | | | (_| | |_| | (_| | (_| |  __/\__ \
"             |_____\__,_|_| |_|\__, |\__,_|\__,_|\__, |\___||___/
"                               |___/             |___/
" =============================================================================

" =============================================================================
" Rust
" =============================================================================
" Formatting replaced with `formatter.nvim`

" To view all groups: :so $VIMRUNTIME/syntax/hitest.vim
" Or to test terminal colors: :so $VIMRUNTIME/syntax/colortest.vim
nmap <leader>sP :call <SID>SynStack()<CR>
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
