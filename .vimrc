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
" Plugin 'xuhdev/SingleCompile'
" Plugin 'tpope/vim-fugitive'
" Plugin 'airblate/vim-gitgutter'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'jiangmiao/auto-pairs'
Plugin 'ervandew/supertab'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'easymotion/vim-easymotion'
Plugin 'tpope/vim-commentary'
Plugin 'ctrlpvim/ctrlp.vim'
" Plugin 'rking/ag.vim'
Plugin 'Chiel92/vim-autoformat'
Plugin 'jeffkreeftmeijer/vim-numbertoggle'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-lua-ftplugin'
" Plugin 'Yggdroot/indentLine'
Plugin 'tmux-plugins/vim-tmux-focus-events'
Plugin 'scrooloose/nerdtree'
Plugin 'Xuyuanp/nerdtree-git-plugin'
Plugin 'elzr/vim-json'
Plugin 'qpkorr/vim-bufkill'
Plugin 'xolox/vim-easytags'
Plugin 'majutsushi/tagbar'
Plugin 'jelera/vim-javascript-syntax'

" Enable if really desired.
" Plugin 'Valloric/YouCompleteMe'

call vundle#end()
filetype plugin indent on

" General
set shell=$SHELL    " Set the default shell
set fileencoding=utf-8 " Set the encoding written to file
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

" Improve performance
"set ttyfast
"set lazyredraw

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
set background=dark
colorscheme solarized

" Custom Filetypes
au BufRead,BufNewFile *.ds set filetype=rgbds


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

" Move by words
" nnoremap B B
nnoremap S W

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

" No clue???
" nnoremap <C-B> <C-W><C-H>
" nnoremap <C-N> <C-W><C-J>
" nnoremap <C-R> <C-W><C-K>
" nnoremap <C-S> <C-W><C-L>

" Move page up / down
"nnoremap ( <PageDown>
"nnoremap ) <PageUp>
"vnoremap ( <PageDown>
"vnoremap ) <PageUp>

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
nnoremap <CR> o<Esc>
inoremap <C-O> <Esc>o
" inoremap  <Esc>o

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

" Split Creating
nnoremap <C-i> :vnew<CR>
nnoremap <C-t> :new<CR>

" Split killing
nnoremap <C-q> :BD<CR>
nnoremap <C-w> :bd<CR>

" Tagbar
nmap <Leader>c :TagbarToggle<CR>

" ReMap NERDTree Keys.
let NERDTreeMapRefresh='<C-a>'
let NERDTreeMapRefreshRoot=''
let NERDTreeMapOpenSplit='t'
let NERDTreeMapOpenVSplit='i'

let NERDTreeMapChdir='C'
let NERDTreeMapUpdir='u'
" let NERDTreeMapNextSibling='N'
" let NERDTreeMapPrevSibling='R'


" Open NERDTree
map <Leader>e :NERDTreeToggle<CR>

" NERDTree options
let NERDTreeShowHidden = 1
let NERDTreeQuitOnOpen = 1
let NERDTreeMinimalUI = 1
let NERDTreeAutoDeleteBuffer = 1


" Open NERDTree when no files specified.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Close VIM if only tab left is NERDTree
" Nope. Closing buffers is getting harder with that.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" NERDTress File highlighting
function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
 exec 'autocmd filetype nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
 exec 'autocmd filetype nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
endfunction

call NERDTreeHighlightFile('jade', 'green', 'none', 'green', '#151515')
call NERDTreeHighlightFile('ini', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('md', 'blue', 'none', '#3366FF', '#151515')
call NERDTreeHighlightFile('yml', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('config', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('conf', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('json', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('html', 'yellow', 'none', 'yellow', '#151515')
call NERDTreeHighlightFile('styl', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan', '#151515')
call NERDTreeHighlightFile('coffee', 'Red', 'none', 'red', '#151515')
call NERDTreeHighlightFile('js', 'Red', 'none', '#ffa500', '#151515')
call NERDTreeHighlightFile('php', 'Magenta', 'none', '#ff00ff', '#151515')


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

  " except for mail
  autocmd FileType mail set colorcolumn=72
else
  au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
endif

" Airline Settings
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#whitespace#mixed_indent_algo = 0

" Setup Airline font
if has('gui_running')
    set guifont=Menlo\ Patched:h11
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
let g:EasyMotion_startofline = 0 " keep cursor column when JK motion

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

" NumberToggle config
let g:NumberToggleTrigger="<C-o>"

" Indent Line settings
let g:indentLine_enabled = 1
" let g:indentLine_leadingSpaceEnabled = 1
" let g:indentLine_char = ''
let g:indentLine_color_term = 239
let g:indentLine_char = '┊'
let g:indentLine_leadingSpaceChar = '·'
let g:indentLine_concealcursor = '' " (default 'inc')
let g:indentLine_conceallevel = 2 " (default 2)
let g:indentLine_noConcealCursor = 1
let g:indentLine_faster = 1

" Fix JSON conceal level Yggdroot/indentLine#140
let g:vim_json_syntax_conceal = 0

" easytags async
let g:easytags_async = 1
let g:easytags_always_enabled = 1
let g:easytags_events = ['BufWinEnter', 'BufWritePost']

" tagbar
let g:tagbar_autoclose = 1
let g:tagbar_autofocus = 1
let g:tagbar_sort = 0
let g:tagbar_autopreview = 0
let g:tagbar_map_toggleautoclose = 't'

" CtrlP
let g:ctrlp_map = '<Leader>o'
let g:ctrlp_show_hidden = 1
let g:ctrlp_prompt_mappings = {
            \    'PrtSelectMove("j")': ['<c-n>'],
            \    'PrtSelectMove("k")': ['<c-r>'],
            \    'PrtCurLeft()': ['<c-b>'],
            \    'PrtCurRight()': ['<c-s>'],
            \    'ToggleRegex()': ['<c-a>'],
            \    'CreateNewFile()': ['<c-y>'],
            \    'MarkToOpen()': ['<c-z>'],
            \    'OpenMulti()': ['<c-o>'],
            \    'PrtHistory(-1)': [],
            \    'ToggleType(-1)': [],
            \    'AcceptSelection("h")': []
            \ }

" Shell command
command! -complete=shellcmd -nargs=+ Shell call s:RunShellCommand(<q-args>)
function! s:RunShellCommand(cmdline)
  echo a:cmdline
  let expanded_cmdline = a:cmdline
  for part in split(a:cmdline, ' ')
     if part[0] =~ '\v[%#<]'
        let expanded_part = fnameescape(expand(part))
        let expanded_cmdline = substitute(expanded_cmdline, part, expanded_part, '')
     endif
  endfor
  botright new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  call setline(1, 'You entered:    ' . a:cmdline)
  call setline(2, 'Expanded Form:  ' .expanded_cmdline)
  call setline(3,substitute(getline(2),'.','=','g'))
  execute '$read !'. expanded_cmdline
  setlocal nomodifiable
  1
endfunction

