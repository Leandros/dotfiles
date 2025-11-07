-- Start LSP with :LspStart lua_ls
vim.cmd([[ set nocompatible ]])
vim.cmd([[ filetype on ]])

-- Docs:
-- * https://github.com/nanotee/nvim-lua-guide
-- * https://neovim.io/doc/user/lua-guide.html
-- * https://www.notonlycode.org/neovim-lua-config/

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before plugins load
vim.keymap.set("n", "<SPACE>", "<Nop>", { noremap = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Python paths
if vim.fn.has("win32") == 1 or vim.fn.has("win16") == 1 then
  vim.g.python3_host_prog = "C:\\Python310\\python.exe"
else
  local venv_path = vim.fn.stdpath("data") .. "/python3-venv"
  if vim.fn.filereadable(venv_path .. "/bin/python3") == 0 then
    print("Python3 VENV not created, run: python3 -m venv " .. venv_path)
    print("source the venv: . " .. venv_path .. "/bin/activate")
    print("install pynvim: pip install pynvim")
    print("falling back to system python")
    vim.g.python3_host_prog = "python3"
  else
    vim.g.python3_host_prog = venv_path .. "/bin/python3"
  end
end

-- Ugly workaround until vim fixes
if vim.fn.has("python3") == 1 then vim.cmd("silent! python3 1") end

-- Check whether we're running on a remote session/linux box.
vim.g["isRemoteSession"] = vim.env.STY == ""
vim.g["isDevDsk"] = vim.startswith(vim.fn.hostname(), "dev-dsk")

-- Exception for AL2 - prefer the manually installed rust-analyzer
if vim.g["isDevDsk"] then vim.env.PATH = os.getenv("HOME") .. "/.cargo/bin:" .. vim.env.PATH end

-- Configuration
vim.g["has_navigator"] = 0

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Language / Shell                     ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
vim.o.langmenu = "en_US.UTF-8"
-- equivalent to: let $LANG='en_US'
vim.env.LANG = "en_US"

-- Set the default shell
if vim.fn.has("win32") == 1 or vim.fn.has("win16") == 1 then
  vim.cmd([[
    source $VIMRUNTIME/delmenu.vim
    source $VIMRUNTIME/menu.vim
  ]])
  vim.o.shell = "cmd.exe"
  vim.o.shellcmdflag = "/C"
else
  vim.o.shell = vim.env.SHELL
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                         General                         ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
vim.o.fileencoding = "utf-8"
vim.o.encoding = "utf-8"
vim.o.cursorline = true
vim.o.ttyfast = true
vim.o.emoji = true
vim.opt.clipboard:append("unnamed")

-- Recently vim (nvim > 0.5.0) can merge signcolumn and number column into one
vim.o.signcolumn = "number"

vim.cmd("syntax enable")
vim.o.hidden = true -- Hide buffer, instead of closing it.
vim.o.number = true -- Always show line numbers.
vim.o.hlsearch = true -- Hightlight found searches.
vim.o.incsearch = true -- Show matched searches as you type.
vim.o.ignorecase = true -- Ignore case when searching.
vim.o.smartcase = true -- Ignore case if search pattern is all lowercase, case-sensitive otherwise.
vim.o.wrapscan = false -- Do not wrap when searching

vim.o.history = 1000 -- Larger command history.
vim.o.undolevels = 1000 -- Undo ALL the changes.
vim.o.visualbell = true -- Don't beep.
vim.o.errorbells = false -- Don't beep.

vim.o.backup = false -- Disable backup. set noswapfile can disable the .swp file.
vim.o.writebackup = false
vim.o.swapfile = false

-- Indentation is 4 spaces, and not a tab
vim.o.tabstop = 4 -- A tab is 4 spaces.
vim.o.softtabstop = 0 -- How tabs behave when editing
vim.o.autoindent = true -- Autoindent.
vim.o.copyindent = true -- Copy the previous indent on autoindenting.
vim.o.shiftwidth = 4 -- Number of spaces used for autoindent.
vim.o.expandtab = true -- Expand <Tab> into spaces
vim.o.smarttab = true -- Insert 'tabs' on start of line, according to shiftwidth instead of tabstop.
vim.o.scrolloff = 3 -- 3 lines of buffer above and below the cursor

-- Don't automatically insert line breaks
vim.o.textwidth = 0

-- Set mapping and key timeouts
vim.o.timeout = true
vim.o.timeoutlen = 500 -- timeout for leader key
vim.o.ttimeoutlen = 10 -- timeout for esc key
vim.o.updatetime = 300 -- 300ms of no cursor movement to trigger CursorHold

-- Show if leader key is pressed
vim.o.showcmd = true
vim.o.cmdheight = 2 -- Give more space for displaying messages.
vim.o.laststatus = 2

-- Correct backspace
vim.o.backspace = "indent,eol,start"

-- Improve breaks
vim.o.showbreak = ">>>"
vim.o.breakindent = true

-- Disable mouse
vim.o.mouse = "c"
vim.opt.sessionoptions:append("tabpages,globals") -- store tabpages and globals in session

-- Disable ZZ to close vim
vim.keymap.set("n", "Z", "<Nop>", { noremap = true })
vim.keymap.set("n", "ZZ", "<Nop>", { noremap = true })

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Runtime path
vim.opt.rtp:append("/opt/homebrew/opt/fzf")

-- ━━ Completion ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Set completeopt to have a better completion experience
-- :help completeopt
-- menuone: popup even when there's only one match
-- noinsert: Do not insert text until a selection is made
-- noselect: Do not select, force user to select one from the menu
vim.o.completeopt = "menuone,noinsert,noselect"

-- Avoid showing extra messages when using completion
vim.opt.shortmess:append("c")

-- ━━ Undo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Write undo tree to a file to resume from next time the file is opened.
if vim.fn.has("persistent_undo") == 1 then
  vim.o.undolevels = 2000 -- The number of undo items to remember
  vim.o.undofile = true -- Save undo history to files locally
  vim.o.undodir = vim.env.HOME .. "/.vimundo" -- Set the directory of the undofile
  if not vim.fn.isdirectory(vim.fn.expand(vim.o.undodir)) then vim.fn.mkdir(vim.fn.expand(vim.o.undodir), "p") end
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                       Performance                       ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
vim.g.loaded_matchparen = 1 -- Don't show matching parens.
vim.o.showmatch = false -- Don't show matching braces.
vim.g.matchparen_timeout = 2
vim.g.matchparen_insert_timeout = 2

-- Syntax highlighting for lua in .vimrc
vim.g.vimsyn_embed = "l"

-- Not required anymore.
vim.o.lazyredraw = false

-- Disable syntax highlighting long lines
vim.o.synmaxcol = 300

-- Disable syntax highlighting in large files
vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  pattern = "*",
  command = 'if getfsize(expand("%")) > 10000000 | set syntax=OFF | endif',
})

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Buffer switching                     ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Improve :b switch menu
-- vim.o.wildchar = vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
-- vim.o.wildchar = vim.fn.char2nr("<Tab>")
vim.cmd("set wildchar=<Tab>")
vim.o.wildmenu = true
vim.o.wildmode = "full"

-- Jump to buffers with Ngb
-- let c = 1
-- while c <= 99
--   execute "nnoremap " . c . "gb :" . c . "b\<CR>"
--   let c += 1
-- endwhile

-- Cygwin cursor fix.
vim.cmd([[
  let &t_ti.="\e[1 q"
  let &t_SI.="\e[5 q"
  let &t_EI.="\e[1 q"
  let &t_te.="\e[0 q"
]])

-- When running as diff.
if vim.api.nvim_get_option_value("diff", { scope = "global" }) then
  vim.o.modifiable = true
  vim.o.readonly = false
  --   if tabpagenr('$') == 1
  --     nnoremap ZZ :wqall<cr>
  --   endif
end

-- C-I acting as Tab replacement
if vim.env.TERM == "screen-256color" then
  vim.cmd([[
    autocmd UIEnter * if v:event.chan ==# 0 | call chansend(v:stderr, "\x1b[>1u") | endif
    autocmd UILeave * if v:event.chan ==# 0 | call chansend(v:stderr, "\x1b[<1u") | endif
  ]])
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Custom filetypes                     ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
--- Set a custom file type based on a pattern.
---@param pattern string File name pattern (e.g., `*.c`)
---@param filetype string Which file type to apply.
local function setft(pattern, filetype)
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = pattern,
    callback = function() vim.o.ft = filetype end,
  })
end

setft("*.ds", "rgbds") -- GameBoy Assembly
setft("*.fl,*.flex,*.l,*.lm", "lex") -- Flex
setft("*.y,*.ypp,*.ym", "yacc") -- Bison
setft("*.man", "groff") -- Groff/Troff
setft("*.mm", "objcpp") -- Objective-C++
setft("*.m", "objc") -- Objective-C
setft("*.jsx", "javascript.jsx") -- Javascript
setft("*.tsx", "typescript.tsx") -- TypescriptX
setft("*.ts", "typescript") -- Typescript
setft("*.nomad", "hcl") -- HCL
setft("*.tf", "hcl") -- HCL
setft("*.hcl", "hcl") -- HCL
setft("*.tfvars", "hcl") -- HCL
setft("*.ex,*.exs", "elixir") -- elixir
setft("*.eex,*.leex,*.sface,*.lexs", "eelixir") -- elixir
setft("mix.lock", "elixir") -- elixir
setft("*.heex", "heex") -- elixir
setft("Config", "conf") -- Brazil config
setft("*.proto", "proto") -- Protobuf

-- ━━ Indent ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--- Create a new autocmd for some events
---@param group integer|nil Autocmd group
---@param events table Which event to listen to
---@param pattern string Pattern for triggering
---@param callback function Called when triggered
local function autocmd(group, events, pattern, callback)
  vim.api.nvim_create_autocmd(events, {
    pattern = pattern,
    group = group,
    callback = callback,
  })
end

--- Create a new autocmd for the filetype.
---@param filetype string File type used for triggering.
---@param callback function Called when triggered.
local function auft(filetype, callback)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = filetype,
    callback = callback,
  })
end

--- Change how many spaces are used for indents
---@param filetype string Which file type to apply to
---@param indent integer How many spaces to indent with
local function setindent(filetype, indent)
  auft(filetype, function()
    vim.opt_local.ts = indent
    vim.opt_local.sts = indent
    vim.opt_local.sw = indent
    vim.opt_local.expandtab = true
  end)
end

-- Setup `:Make`
auft("typescript", function() vim.o.makeprg = "tsc $*" end)
auft("typescript.tsx", function() vim.o.makeprg = "tsc $*" end)

-- Setup comment string
auft("javascript", function() vim.opt_local.commentstring = "/* %s */" end)
auft("javascript.jsx", function() vim.opt_local.commentstring = "/* %s */" end)
auft("typescript", function() vim.opt_local.commentstring = "/* %s */" end)
auft("typescript.tsx", function() vim.opt_local.commentstring = "/* %s */" end)
auft("lalrpop", function() vim.opt_local.commentstring = "// %s" end)
auft("hcl", function() vim.opt_local.commentstring = "# %s" end)
auft("hcl", function() vim.opt_local.comments = ":#" end)

-- Use Dashes in identifiers
auft("hcl", function() vim.opt_local.iskeyword = vim.o.iskeyword .. "-" end)

-- Use Tabs in Makefiles
auft("make", function() vim.opt_local.expandtab = false end)

-- Setup indents
setindent("json", 2)
setindent("lua", 2)
setindent("gn", 2)
setindent("yaml", 2)
setindent("hcl", 2)
setindent("vim", 2)
setindent("helm", 2)
setindent("gn", 2)
setindent("json", 2)
setindent("javascript", 2)
setindent("javascript", 2)
setindent("typescript", 2)
setindent("typescript", 2)
setindent("haskell", 2)
setindent("proto", 2)
setindent("html", 2)
setindent("htmldjango", 2)

-- Disable automatic line breaking
auft("helm", function() vim.opt_local.tw = 0 end)

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                   Set syntax options                    ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Highlight trailing whitespace in c files
vim.g["c_space_errors"] = 1
-- Custom no-fold in my c.vim
vim.g["c_no_block_fold"] = 1
-- Don't fold comments
vim.g["c_no_comment_fold"] = 1
-- Don't fold #if 0 blocks
vim.g["c_no_if0_fold"] = 1

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                       Keybindings                       ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
--- Create a new mapping for all modes.
---@param lhs string Keybind
---@param rhs string Action
---@param opts vim.api.keyset.keymap|nil Options
local function noremap(lhs, rhs, opts)
  local opts_ = vim.tbl_deep_extend("keep", { noremap = true }, opts or {})
  vim.keymap.set("", lhs, rhs, opts_)
end
--- Create a new mapping for normal mode.
---@param lhs string Keybind
---@param rhs string Action
---@param opts vim.api.keyset.keymap|nil Options
local function nnoremap(lhs, rhs, opts)
  local opts_ = vim.tbl_deep_extend("keep", { noremap = true }, opts or {})
  vim.keymap.set("n", lhs, rhs, opts_)
end
--- Create a new mapping for insert mode.
---@param lhs string Keybind
---@param rhs string Action
---@param opts vim.api.keyset.keymap|nil Options
local function inoremap(lhs, rhs, opts)
  local opts_ = vim.tbl_deep_extend("keep", { noremap = true }, opts or {})
  vim.keymap.set("i", lhs, rhs, opts_)
end
--- Create a new mapping for visual mode.
---@param lhs string Keybind
---@param rhs string Action
---@param opts vim.api.keyset.keymap|nil Options
local function vnoremap(lhs, rhs, opts)
  local opts_ = vim.tbl_deep_extend("keep", { noremap = true }, opts or {})
  vim.keymap.set("v", lhs, rhs, opts_)
end
--- like ":map" but for Insert mode
---@param lhs string Keybind
---@param rhs string Action
---@param opts vim.api.keyset.keymap|nil Options
local function imap(lhs, rhs, opts)
  local opts_ = vim.tbl_deep_extend("keep", { noremap = false }, opts or {})
  vim.keymap.set("i", lhs, rhs, opts_)
end
--- like ":map" but for select mode
---@param lhs string Keybind
---@param rhs string Action
---@param opts vim.api.keyset.keymap|nil Options
local function smap(lhs, rhs, opts)
  local opts_ = vim.tbl_deep_extend("keep", { noremap = false }, opts or {})
  vim.keymap.set("s", lhs, rhs, opts_)
end

-- Keybindings are set below the lazy.nvim invocation

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Folding config                      ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
local augrp_vim = vim.api.nvim_create_augroup("config.vimrc", { clear = true })
-- Set foldmethod indent AND manual
autocmd(augrp_vim, { "BufReadPre" }, "*", function() vim.opt_local.foldmethod = "indent" end)
autocmd(augrp_vim, { "BufWinEnter" }, "*", function()
  if vim.o.fdm == "indent" then vim.opt_local.foldmethod = "manual" end
end)
-- Open all folds at startup
autocmd(augrp_vim, { "BufRead" }, "*", function() vim.cmd("normal zR") end)

local augrp_ftcs = vim.api.nvim_create_augroup("config.filetype_cs", { clear = true })
-- Set folding by syntax for C# (Unity) files
autocmd(augrp_ftcs, { "FileType" }, "cs", function() vim.opt_local.foldmethod = "syntax" end)
autocmd(augrp_ftcs, { "FileType" }, "cs", function() vim.api.nvim_buf_set_var(0, "match_words", "s*#s*region.*$:s*#s*endregion") end)
-- Close all folds
autocmd(augrp_ftcs, { "BufRead" }, "*.cs", function() vim.cmd("normal zM") end)

local augrp_ftcxx = vim.api.nvim_create_augroup("config.filetype_cpp", { clear = true })
-- Create custom doxygen comment style
autocmd(augrp_ftcxx, { "FileType" }, "cpp", function() vim.cmd("syn region doxygenComment start='/*!' end='*/' fold") end)
autocmd(augrp_ftcxx, { "FileType" }, "cpp", function() vim.cmd("hi link doxygenComment cError") end)
-- Fold based on our custom syntax.
autocmd(augrp_ftcxx, { "FileType" }, "cpp", function() vim.opt_local.foldmethod = "syntax" end)
-- Close all folds.
autocmd(augrp_ftcxx, { "BufRead" }, "*.cxx,*.hxx,*.cpp,*.hpp", function() vim.cmd("normal zM") end)

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                   Set 80 column limit                   ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Set 80 column limit
vim.o.colorcolumn = "80"
-- except for mail
autocmd(nil, { "FileType" }, "mail", function() vim.o.colorcolumn = "72" end)

-- Duplicated in `auto-dark-mode`
if vim.o.background == "dark" then
  vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#004653" })
else
  vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#eee8d5" })
end

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                        Commands                         ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Invoke P4
vim.api.nvim_create_user_command("P4", ":cexpr system('p4.py <args> '.expand('%:p')) | e! | copen", {
  nargs = "+",
})

-- Change current working directory
nnoremap(",cd", ":cd %:p:h<CR>:pwd<CR>")

-- Never mess when file opened without sudo.
-- Previous: cmap w!! w !sudo tee % >/dev/null
vim.cmd([[cnoreabbrev w!! w ! sudo tee % > /dev/null]])

-- ━━ Profiling ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.api.nvim_create_user_command(
  "ProfileStart",
  function()
    vim.cmd([[
    :profile start profile.log
    :profile func *
    :profile file *
  ]])
  end,
  { bang = true }
)

vim.api.nvim_create_user_command("ProfileEnd", function()
  vim.cmd([[
    :profile pause
    :noautocmd qall!
  ]])
end, { bang = true })

-- ━━ Strip trailing whitespace ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.api.nvim_create_user_command("StripWhitespace", function()
  local l = vim.fn.line(".")
  local c = vim.fn.col(".")
  vim.cmd([[:%s/\s\+$//e]])
  vim.fn.cursor(l, c)
end, { bang = true })

-- ━━ Strip ANSI escapes ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.api.nvim_create_user_command("StripAnsi", function()
  local l = vim.fn.line(".")
  local c = vim.fn.col(".")
  vim.cmd([[:%s/\%x1b\[[0-9;]*m//g]])
  vim.fn.cursor(l, c)
end, { bang = true })

-- ━━ Minify JSON ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.api.nvim_create_user_command("JsonMinify", function()
  vim.cmd([[
    %s/\ //g
    %s/\n//g
  ]])
end, { bang = true })

-- ━━ Shell command ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.cmd([[
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
]])

-- ━━ Make ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.cmd([[
  function! RunMake(...)
     write
     echo 'make ' . join(a:000, ' ')
     call s:RunShellCommand('make '.join(a:000, ' '))
  endfunction
  command! -nargs=* Make :call RunMake(<f-args>)
]])

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃               Increment numbers in a row                ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
_G.Incr = function()
  local a = vim.fn.line(".") - vim.fn.line("'<")
  local c = vim.fn.virtcol("'<")
  if a < 0 then vim.cmd("normal! " .. c .. "|" .. a .. "\\<C-a>") end
  vim.cmd([[normal `<]])
end

vnoremap("<C-a>", ":call v:lua.Incr()<CR>")

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                      Buffer moving                      ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
vim.api.nvim_create_user_command("MarkWindowSwap", function() vim.g.markedWinNum = vim.fn.winnr() end, { bang = true })

vim.api.nvim_create_user_command("DoWindowSwap", function()
  -- Mark destination
  local curnum = vim.fn.winnr()
  local curbuf = vim.fn.bufnr("%")
  vim.cmd(vim.g.markedWinNum .. "wincmd w")
  -- Switch to source and shuffle dest->source
  local markedbuf = vim.fn.bufnr("%")
  -- Hide and open so that we aren't prompted and keep history
  vim.cmd("hide buf" .. curbuf)
  -- Switch to dest and shuffle source->dest
  vim.cmd(curnum .. "wincmd w")
  -- Hide and open so that we aren't prompted and keep history
  vim.cmd("hide buf" .. markedbuf)
end, { bang = true })

nnoremap("<Leader>m", ":MarkWindowSwap()<CR>", { silent = true })
nnoremap("<Leader>u", ":DoWindowSwap()<CR>", { silent = true })

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                    Close all buffers                    ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
vim.api.nvim_create_user_command("CloseBuffers", function()
  local curr = vim.fn.bufnr("%")
  local last = vim.fn.bufnr("$")
  if curr > 1 then vim.cmd('silent! execute "1,"' .. (curr - 1) .. "bd") end
  if curr < last then vim.cmd("silent! execute " .. (curr + 1) .. "," .. last .. "bd") end
end, { bang = true })

nnoremap("<Leader>w", ":CloseBuffers<CR>", { silent = true })

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃               Close all floating windows                ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
_G.CloseAllFloatingWindows = function()
  local closed_windows = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then -- is_floating_window?
      vim.api.nvim_win_close(win, false) -- do not force
      table.insert(closed_windows, win)
    end
  end
  print(string.format("Closed %d windows: %s", #closed_windows, vim.inspect(closed_windows)))
end

vim.api.nvim_create_user_command("CloseAllFloatingWindows", _G.CloseAllFloatingWindows, {
  bang = true,
  nargs = "*",
})

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                       Colorscheme                       ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- SOLARIZED HEX     16/8 TERMCOL  XTERM/HEX   L*A*B      RGB         HSB
-- --------- ------- ---- -------  ----------- ---------- ----------- -----------
-- base03    #002b36  8/4 brblack  234 #1c1c1c 15 -12 -12   0  43  54 193 100  21
-- base02    #073642  0/4 black    235 #262626 20 -12 -12   7  54  66 192  90  26
-- base01    #586e75 10/7 brgreen  240 #585858 45 -07 -07  88 110 117 194  25  46
-- base00    #657b83 11/7 bryellow 241 #626262 50 -07 -07 101 123 131 195  23  51
-- base0     #839496 12/6 brblue   244 #808080 60 -06 -03 131 148 150 186  13  59
-- base1     #93a1a1 14/4 brcyan   245 #8a8a8a 65 -05 -02 147 161 161 180   9  63
-- base2     #eee8d5  7/7 white    254 #e4e4e4 92 -00  10 238 232 213  44  11  93
-- base3     #fdf6e3 15/7 brwhite  230 #ffffd7 97  00  10 253 246 227  44  10  99
-- yellow    #b58900  3/3 yellow   136 #af8700 60  10  65 181 137   0  45 100  71
-- orange    #cb4b16  9/3 brred    166 #d75f00 50  50  55 203  75  22  18  89  80
-- red       #dc322f  1/1 red      160 #d70000 50  65  45 220  50  47   1  79  86
-- magenta   #d33682  5/5 magenta  125 #af005f 50  65 -05 211  54 130 331  74  83
-- violet    #6c71c4 13/5 brmagenta 61 #5f5faf 50  15 -45 108 113 196 237  45  77
-- blue      #268bd2  4/4 blue      33 #0087ff 55 -10 -45  38 139 210 205  82  82
-- cyan      #2aa198  6/6 cyan      37 #00afaf 60 -35 -05  42 161 152 175  74  63
-- green     #859900  2/2 green     64 #5f8700 60 -20  65 133 153   0  68 100  60--
--
-- == DARK ==
-- - base3
-- - base2
-- - base1   -> optional emphasized content
-- - base0   -> body text/default code/primary content
-- - base00  ->
-- - base01  -> comments/secondary content
-- - base02  -> background highlights
-- - base03  -> background
--
-- == LIGHT ==
-- - base03
-- - base02
-- - base01  -> optional emphasized content
-- - base00  -> body text/default code/primary content
-- - base0   ->
-- - base1   -> comments/secondary content
-- - base2   -> background highlights
-- - base3   -> background

local function clear_bufferline_highlights()
  local highlights = {
    "BufferLineHint",
    "BufferLineWarningVisible",
    "BufferLineModifiedSelected",
    "BufferLineErrorDiagnosticSelected",
    "BufferLineBackground",
    "BufferLineModified",
    "BufferLineInfo",
    "BufferLineDuplicateVisible",
    "BufferLineBuffer",
    "BufferLineTruncMarker",
    "BufferLineGroupSeparator",
    "BufferLineGroupLabel",
    "BufferLineTabSelected",
    "BufferLineTabClose",
    "BufferLineCloseButton",
    "BufferLineCloseButtonVisible",
    "BufferLineCloseButtonSelected",
    "BufferLineBufferVisible",
    "BufferLineBufferSelected",
    "BufferLineNumbers",
    "BufferLineNumbersSelected",
    "BufferLineNumbersVisible",
    "BufferLineDiagnosticVisible",
    "BufferLineDiagnosticSelected",
    "BufferLineHintVisible",
    "BufferLineHintSelected",
    "BufferLineHintDiagnostic",
    "BufferLineHintDiagnosticVisible",
    "BufferLineHintDiagnosticSelected",
    "BufferLineInfoVisible",
    "BufferLineInfoSelected",
    "BufferLineInfoDiagnostic",
    "BufferLineInfoDiagnosticVisible",
    "BufferLineInfoDiagnosticSelected",
    "BufferLineDiagnostic",
    "BufferLineWarningSelected",
    "BufferLineWarningDiagnostic",
    "BufferLineWarningDiagnosticVisible",
    "BufferLineWarningDiagnosticSelected",
    "BufferLineErrorVisible",
    "BufferLineErrorSelected",
    "BufferLineErrorDiagnostic",
    "BufferLineErrorDiagnosticVisible",
    "BufferLineError",
    "BufferLineModifiedVisible",
    "BufferLineSeparator",
    "BufferLineIndicatorVisible",
    "BufferLinePickSelected",
    "BufferLinePickVisible",
    "BufferLineOffsetSeparator",
    "BufferLineSeparatorVisible",
    "BufferLineTabSeparator",
    "BufferLineTabSeparatorSelected",
    "BufferLineIndicatorSelected",
    "BufferLineSeparatorSelected",
    "BufferLineDuplicate",
    "BufferLineDuplicateSelected",
    "BufferLineWarning",
    "BufferLinePick",
    "BufferLineDevIconDefaultSelected",
  }
  for _, name in ipairs(highlights) do
    vim.api.nvim_set_hl(0, name, {})
  end
end

---
---@param name string highlight namen
---@param opts vim.api.keyset.highlight Options
local function hi(name, opts) vim.api.nvim_set_hl(0, name, opts) end

local function setup_highlights_dark()
  -- Reset bufferline.
  clear_bufferline_highlights()

  -- Set correct colors. The autodetected colors are not ideal.
  hi("BufferLineFill", { bg = "#002b36" })
  hi("BufferLineTab", { fg = "#586e75", bg = "#002028" })
  hi("BufferLineIndicatorSelected", { fg = "#2aa198", bg = "#002b36" })
  hi("BufferLineSeparator", { fg = "#002028", bg = "#002028" })

  -- Color was previously: #073642
  -- hi("IblScope", { fg="#073642", bg="none", gui="nocombine", })
  hi("@ibl.scope.char.1", { bg = "#073642" })
  hi("IblScope", { nocombine = true, fg = "#657b83", bg = "#073642" })
  hi("IblIndent", { fg = "#234854", bg = "none", nocombine = true })
  hi("IblWhitespace", { fg = "#234854", bg = "none", nocombine = true })
  hi("Comment", { ctermfg = 92, fg = "#586e75", bg = "NONE", sp = "NONE" })
  hi("Visual", { ctermbg = 92, ctermfg = 7, bg = "#586e75", fg = "#002b36", nocombine = true, sp = "none" })

  -- --- RUST ---
  -- Pmenu:
  -- PmenuSel: selection
  -- GHListHl: Guihua List Highlight
  -- GHListDark: Guihui List
  hi("Pmenu", { ctermfg = 12, ctermbg = 0, fg = "#839496", bg = "#073642", sp = "NONE" })
  hi("FloatBorder", { ctermfg = 1, fg = "#ffffff", bg = "NONE", sp = "NONE" })
  hi("GHTextViewDark", { ctermfg = 12, ctermbg = 0, fg = "#93a1a1", bg = "#002b36", sp = "NONE" })
  hi("NormalFloat", { ctermfg = 12, ctermbg = 7, fg = "#93a1a1", bg = "#002b36", sp = "NONE" })
  hi("FloatShadow", { blend = 80, bg = "#073642" })
  hi("FloatShadowThrough", { blend = 100, bg = "#073642" })
  --hi("LocalHighlight", { fg="#dcd7ba", bg="#2d4f67", })

  -- - LSP ---
  hi("LspInlayHint", { ctermfg = 92, fg = "#586e75", bg = "NONE", sp = "NONE" })

  -- - TreeSitter ---
  hi("TSDefinitionUsage", { fg = "none", bg = "#073642", underline = true, sp = "none" })
  hi("TreesitterContextSeparator", { fg = "#2aa198" })

  -- - Fish ---
  hi("fishParameter", { bg = "none", ctermbg = 0 })
  hi("fishOption", { bg = "none", ctermbg = 0 })
end

local function setup_highlights_light()
  -- Reset bufferline.
  clear_bufferline_highlights()

  -- Set correct colors. The autodetected colors are not ideal.
  hi("BufferLineFill", { bg = "#fdf6e3" })
  hi("BufferLineTab", { fg = "#93a1a1", bg = "#fdf6e3" })
  hi("BufferLineTabSelected", { fg = "#93a1a1", bg = "#fdf6e3" })
  hi("BufferLineBufferSelected", { fg = "#93a1a1", bg = "#fdf6e3" })
  hi("BufferLineIndicatorSelected", { fg = "#268bd2" })
  hi("BufferLineSeparator", { fg = "#fdf6e3", bg = "#fdf6e3" })

  -- Reset some special rules.
  hi("@ibl.scope.char.1", { bg = "#eee8d5" })
  hi("IblScope", { nocombine = true, fg = "#839496", bg = "#eee8d5" })
  hi("IblIndent", { fg = "#eee8d5", bg = "none", nocombine = true })
  hi("IblWhitespace", { fg = "#eee8d5", bg = "none", nocombine = true })
  hi("Comment", { ctermfg = 92, fg = "#93a1a1", bg = "NONE", sp = "NONE" })
  hi("Visual", { ctermbg = 92, ctermfg = 7, bg = "#93a1a1", fg = "#fdf6e3", nocombine = true, sp = "none" })

  hi("Pmenu", { ctermfg = 11, ctermbg = 0, fg = "#657b83", bg = "#eee8d5", sp = "NONE" })
  hi("FloatBorder", { ctermfg = 0, fg = "#000000", bg = "NONE", sp = "NONE" })
  hi("GHTextViewDark", { ctermfg = 10, ctermbg = 15, fg = "#586e75", bg = "#fdf6e3", sp = "NONE" })
  hi("NormalFloat", { ctermfg = 10, ctermbg = 15, fg = "#586e75", bg = "#fdf6e3", sp = "NONE" })
  hi("FloatShadow", { blend = 80, bg = "#eee8d5" })
  hi("FloatShadowThrough", { blend = 100, bg = "#eee8d5" })

  -- - LSP ---
  -- Same as comment.
  hi("LspInlayHint", { ctermfg = 92, fg = "#93a1a1", bg = "NONE", sp = "NONE" })

  -- - TreeSitter ---
  hi("TSDefinitionUsage", { fg = "none", bg = "#eee8d5", underline = true, sp = "none" })
  hi("TreesitterContextSeparator", { fg = "#268bd2" })

  -- - Fish ---
  hi("fishParameter", { bg = "none", ctermbg = 0 })
  hi("fishOption", { bg = "none", ctermbg = 0 })
end

local function init_solarized_scheme()
  require("solarized").setup({
    variant = "autumn",
    on_highlights = function(colors)
      local yellow = colors.yellow
      local green = colors.green
      local cyan = colors.cyan
      local orange = colors.orange
      local base0 = colors.base0
      local base03 = colors.base03
      local blue = colors.blue
      local violet = colors.violet

      ---@type solarized.highlights
      local groups = {
        Constant = { fg = cyan },
        Special = { fg = orange },
        IncSearch = { fg = base03, bg = yellow, bold = true },
        Search = { fg = base03, bg = yellow, bold = false },
        ["@constant.builtin"] = { fg = yellow },
        ["@punctuation.delimiter"] = { fg = green },
        ["@punctuation.special"] = { fg = orange },
        ["@function.macro"] = { fg = orange },
        ["@variable.builtin"] = { fg = orange },
        ["@variable.parameter"] = { fg = base0 },
        ["@type.builtin"] = { fg = yellow },
        ["@number"] = { fg = cyan },
        ["@attribute.builtin"] = { fg = orange },
        ["@module"] = { fg = blue },
        ["@markup.link"] = { fg = violet, underline = false },
        ["@markup.link.url"] = { fg = violet, underline = false },
        ["@markup.heading.1"] = { fg = colors.red },
        ["@markup.heading.2"] = { fg = colors.orange },
        ["@markup.heading.3"] = { fg = colors.violet },
        ["@markup.heading.4"] = { fg = colors.blue },
        ["@markup.heading.5"] = { fg = colors.cyan },
        ["@markup.heading.6"] = { fg = colors.green },
        NvimTreeNormal = { bg = base03 },
        NvimTreeFolderName = { fg = blue },
        NvimTreeExecFile = { fg = cyan, bold = true },
        MasonNormal = { bg = base03 },
        NormalFloat = { bg = base03 },
        WhichKeyNormal = { bg = base03 },
        TelescopeNormal = { bg = base03 },
        FlashLabel = { fg = colors.base04, bg = "#ffffff", bold = true },
        FloatTitle = { fg = base0, bg = "NONE" },
      }

      return groups
    end,
  })
end

-- Apply custom highlights.
local setup_augroup = vim.api.nvim_create_augroup("config.SetupColorscheme", { clear = true })
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  pattern = "*",
  group = setup_augroup,
  callback = function()
    if vim.o.background == "dark" then
      setup_highlights_dark()
    else
      setup_highlights_light()
    end
  end,
})

-- Toggling between dark and light mode.
vim.g["custom#isdarkmode"] = 1

function EnableDarkMode()
  vim.g["custom#isdarkmode"] = 1

  vim.o.background = "dark"
  init_solarized_scheme()
  setup_highlights_dark()
  vim.cmd("colorscheme solarized")
  vim.cmd("highlight ColorColumn guibg=#004653")

  -- Plugins:
  lualine_setup()
  ibl_setup()
  bufferline_setup()

  -- We'll need to setup custom highlights again.
  setup_highlights_dark()
end

function EnableLightMode()
  vim.g["custom#isdarkmode"] = 0

  vim.o.background = "light"
  init_solarized_scheme()
  setup_highlights_light()
  vim.cmd("colorscheme solarized")
  vim.cmd("highlight ColorColumn guibg=#eee8d5")

  -- Plugins:
  lualine_setup()
  ibl_setup()
  bufferline_setup()

  -- We'll need to setup custom highlights again.
  setup_highlights_light()
end

vim.api.nvim_create_user_command("EnableLightMode", EnableLightMode, {})
vim.api.nvim_create_user_command("EnableDarkMode", EnableDarkMode, {})

-- ============================================================================
--                       ____  _             _
--                      |  _ \| |_   _  __ _(_)_ __  ___
--                      | |_) | | | | |/ _` | | '_ \/ __|
--                      |  __/| | |_| | (_| | | | | \__ \
--                      |_|   |_|\__,_|\__, |_|_| |_|___/
--                                     |___/
-- ============================================================================
-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                         Plugins                         ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

local _Logger = nil
---@diagnostic disable-next-line: unused-function,unused-local
local function get_logger()
  if _Logger == nil then _Logger = require("logger"):new({ log_level = "debug", prefix = "init.lua", echo_messages = true }) end
  return _Logger
end

local _border = {
  -- Second argument is the highlight group name.
  { "┌", "FloatBorder" },
  { "─", "FloatBorder" },
  { "┐", "FloatBorder" },
  { "│", "FloatBorder" },
  { "┘", "FloatBorder" },
  { "─", "FloatBorder" },
  { "└", "FloatBorder" },
  { "│", "FloatBorder" },
}

local function make_lsp_defaults()
  local lspconfig = require("lspconfig")
  local lsp_defaults = lspconfig.util.default_config
  local lsp_status = require("lsp-status")

  lsp_defaults.capabilities =
    vim.tbl_deep_extend("force", lsp_defaults.capabilities, require("cmp_nvim_lsp").default_capabilities(), lsp_status.capabilities)
  lsp_defaults.capabilities["semanticTokensProvider"] = nil
  -- https://github.com/neovim/neovim/issues/23291
  lsp_defaults.capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

  return lsp_defaults
end

-- Global `on_attach`
local function on_attach(client, bufnr)
  -- This produces errors due to lspconfig bug: https://github.com/neovim/nvim-lspconfig/issues/2542
  --if client.server_capabilities then
  --  client.server_capabilities.semanticTokensProvider = nil
  --end

  if vim.g["has_navigator"] ~= 0 then
    require("navigator.lspclient.mapping").setup({ client = client, bufnr = bufnr }) -- setup navigator keymaps here,
    require("navigator.dochighlight").documentHighlight(bufnr)
    if client:supports_method("textDocument/codeAction", bufnr) then
      require("navigator.codeAction").code_action_prompt(client, bufnr, {})
    end

    local navigator_bindings = {
      { "n", "<c-]>", "<cmd>lua require('navigator.definition').definition()<CR>", "" },
      { "n", "gd", "<cmd>lua require('navigator.definition').definition_preview()<CR>", "LSP: Preview Definition" },
      { "n", "<leader>rn", "<cmd>lua require('navigator.rename').rename()<CR>", "LSP: Rename Symbol" },
      { "n", "<leader>k", "<cmd>lua require('navigator.diagnostics').show_diagnostics()<CR>", "LSP: Show Diagnostic Under Cursor" },
    }
    for _, kb in ipairs(navigator_bindings) do
      vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4], buffer = bufnr })
    end
  else
    local alt_lsp_bindings = {
      { "n", "<leader>k", "<cmd>lua vim.diagnostic.open_float({ scope = 'line' })<CR>", "LSP: Show Diagnostic Under Cursor" },
    }

    for _, kb in ipairs(alt_lsp_bindings) do
      vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
    end
  end

  local lsp_bindings = {
    { "i", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help({ border = 'single', max_width = 120 })<CR>", "LSP: Signature Help" },

    { "n", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help({ border = 'single', max_width = 120 })<CR>", "LSP: Signature Help" },
    { "n", "K", "<cmd>lua vim.lsp.buf.hover({ border = 'single', max_width = 120 })<CR>", "LSP: Hover Docs" },
    { "n", "<leader>re", "<cmd>lua vim.lsp.buf.rename()<CR>", "LSP: Rename" },
    { "n", "[e", "<cmd>lua vim.diagnostic.goto_next({ border = 'rounded', max_width = 80 })<CR>", "LSP: Next Diagnostic" },
    { "n", "]e", "<cmd>lua vim.diagnostic.goto_prev({ border = 'rounded', max_width = 80 })<CR>", "LSP: Prev Diagnostic" },
  }

  for _, kb in ipairs(lsp_bindings) do
    vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
  end

  -- setup buffer keymaps etc.
  require("lsp-status").on_attach(client)
  if client:supports_method("textDocument/documentSymbol", bufnr) and client.server_capabilities.documentSymbolProvider then
    require("nvim-navbuddy").attach(client, bufnr)
  end

  -- Turn on inlay hints
  vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
end

local function on_init(client)
  -- disable highlighting from lsp
  if client.server_capabilities then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.semanticTokensProvider = false -- turn off semantic tokens
  end
end

-- https://lazy.folke.io/spec
---@type LazySpec
local spec = {
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.termguicolors = true
      vim.o.background = "dark"
      vim.cmd([[
        let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
        let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
      ]])
      init_solarized_scheme()
      vim.cmd("colorscheme solarized")
      vim.cmd("highlight ColorColumn guibg=#004653")
    end,
  },
  {
    "Joakker/lua-json5",
    priority = 999,
    build = "./install.sh",
  }, -- end json5

  -- ━━ Vimscript Plugins ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  { "rmagatti/logger.nvim" },
  { "AndrewRadev/bufferize.vim" },
  { "nvim-lua/plenary.nvim" },
  { "rcarriga/nvim-notify" },
  { "tpope/vim-commentary" },
  -- { "tpope/vim-repeat" " remaps <c-r> },
  { "tpope/vim-surround" },
  { "tpope/vim-speeddating" },
  {
    "Konfekt/FastFold",
    init = function() vim.g.fastfold_fold_command_suffixes = {} end,
  },
  { "mhinz/vim-grepper" },
  { "maxbrunsfeld/vim-yankstack" },
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      -- TODO?: Add 'custom motions':
      -- <https://github.com/mg979/vim-visual-multi/blob/a6975e7c1ee157615bbc80fc25e4392f71c344d4/doc/vm-settings.txt#L124>

      -- Find default mappings here:
      -- <https://github.com/mg979/vim-visual-multi/blob/a6975e7c1ee157615bbc80fc25e4392f71c344d4/autoload/vm/maps/all.vim#L80>

      vim.g.VM_default_mappings = 0
      vim.g.VM_mouse_mappings = 0
      -- See: https://github.com/mg979/vim-visual-multi/issues/241
      vim.g.VM_maps = {
        ["Exit"] = "<C-C>", -- quit VM
        ["Find Under"] = "<C-g>", -- replace C-n
        ["Find Subword Under"] = "<C-g>", -- replace visual C-n
        ["Toggle Mappings"] = "<CR>", -- toggle VM buffer mappings
        ["Undo"] = "u",
        ["Redo"] = "j",

        ["Add Cursor Down"] = "<C-h>",
        ["Add Cursor Up"] = "<C-l>",
        ["Goto Next"] = "]",
        ["Goto Prev"] = "[",
        ["Find Next"] = "h",
        ["Find Prev"] = "l",
        ["Skip Region"] = "q",
        ["Remove Region"] = "Q",
        ["Replace"] = "", -- previously 'R'
        ["Replace Characters"] = "", -- previously 'r'
        ["Replace Pattern"] = "",
        ["Motion h"] = "b",
        ["Motion j"] = "n",
        ["Motion k"] = "r",
        ["Motion l"] = "s",
      }

      vim.cmd([[
        function! VM_Start()
          let g:yankring_record_enabled = 0
          if exists("AutoPairsToggle")
            call AutoPairsToggle()
          endif

          " Add mappings here if desired:
          " Example: nmap <buffer> b <Left>
        endfunction
      ]])

      vim.cmd([[
        function! VM_Exit()
          let g:yankring_record_enabled = 1
          if exists("AutoPairsToggle")
            call AutoPairsToggle()
          endif

          " And unmap them again here:
          " Example: nunmap <buffer> b
        endfunction
      ]])
    end,
  },

  -- General plugins
  {
    "junegunn/vim-easy-align",
    config = function()
      vim.keymap.set("x", "ga", "<Plug>(EasyAlign)", { noremap = false })
      vim.keymap.set("n", "ga", "<Plug>(EasyAlign)", { noremap = false })
    end,
  },
  { "junegunn/vim-peekaboo" },
  {
    "MattesGroeger/vim-bookmarks",
    config = function()
      vim.g.bookmark_no_default_key_mappings = 1
      ---@diagnostic disable-next-line: redefined-local
      local autocmd = vim.api.nvim_create_autocmd -- Create autocommand
      local mark_bindings = {
        { "mm", ":BookmarkToggle<CR>", mode = "n", desc = "Toggle" },
        { "mi", ":BookmarkAnnotate<CR>", mode = "n", desc = "Annotate" },
        { "mn", ":BookmarkNext<CR>", mode = "n", desc = "Next" },
        { "mr", ":BookmarkPrev<CR>", mode = "n", desc = "Prev" },
        { "ma", ":BookmarkShowAll<CR>", mode = "n", desc = "Show All" },
        { "md", ":BookmarkClear<CR>", mode = "n", desc = "Clear" },
        { "mx", ":BookmarkClearAll<CR>", mode = "n", desc = "Clear All" },
        { "mh", ":BookmarkMoveUp<CR>", mode = "n", desc = "Move Up" },
        { "ml", ":BookmarkMoveDown<CR>", mode = "n", desc = "Move Down" },
        { "mg", ":BookmarkMoveToLine<CR>", mode = "n", desc = "Move To Line" },
        { "mA", "<cmd>lua require('telescope.builtin').marks()<cr>", mode = "n", desc = "Show All (Telescope)" },
      }

      autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          -- Don't set mappings in nerdtree
          if vim.bo.filetype == "nerdtree" then return end

          for _, kb in ipairs(mark_bindings) do
            vim.keymap.set(kb["mode"], kb[1], kb[2], { noremap = false, desc = kb["desc"], buffer = true })
          end
        end,
      })

      autocmd("FileType", {
        pattern = "nerdtree",
        callback = function()
          for _, kb in ipairs(mark_bindings) do
            vim.keymap.del(kb[1], kb[2], { buffer = true })
          end
        end,
      })
    end,
  },
  {
    "vim-scripts/EnhancedJumps",
    lazy = false,
    dependencies = { "vim-scripts/ingo-library" },
    config = function()
      local ej_bindings = {
        { "n", "<Leader>h", "<Plug>EnhancedJumpsOlder", "EJ: Jump Older" },
        { "n", "<Leader>l", "<Plug>EnhancedJumpsNewer", "EJ: Jump Newer" },
        { "n", "<Leader>gh", "<Plug>EnhancedJumpsLocalOlder", "EJ: Jump Older (Local)" },
        { "n", "<Leader>gl", "<Plug>EnhancedJumpsLocalNewer", "EJ: Jump Newer (Local)" },
      }

      for _, kb in ipairs(ej_bindings) do
        vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
      end
    end,
  },

  -- My own plugins/forks
  { "leandros/vim-misc" },
  { "leandros/QFEnter" },
  { "leandros/vim-bufkill" },

  -- ━━ Syntax plugins ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  { "dummyunit/vim-fastbuild", ft = { "fastbuild" } },
  { "wlangstroth/vim-racket", ft = { "racket" } },
  { "luochen1990/rainbow", ft = { "scheme", "lisp", "racket" } },
  { "leandros/hlsl.vim", ft = { "hlsl" } },
  { "leandros/vim-gn", ft = { "gn" } },
  { "aexpl/vim-aexpl", ft = { "aexpl" } },
  { "jparise/vim-graphql", ft = { "graphql" } },
  { "qnighy/lalrpop.vim", ft = { "lalrpop" } },
  { "rust-lang/rust.vim", ft = { "rust" } },
  { "cespare/vim-toml", ft = { "toml" }, branch = "main" },
  { "NoahTheDuke/vim-just" },
  { "jvirtanen/vim-hcl" },
  { "towolf/vim-helm" },
  {
    "fatih/vim-go",
    build = function() vim.cmd(":GoUpdateBinaries") end,
  },
  { "alx741/vim-hindent" },
  {
    "LnL7/vim-nix",
    ft = { "nix" },
    build = function() vim.cmd([[shellescape("nix profile install nixpkgs#nixpkgs-fmt")]]) end,
  },
  { "elixir-editors/vim-elixir" },
  { "Vimjas/vim-python-pep8-indent", ft = { "python" } },
  { "nickeb96/fish.vim", ft = { "fish" } },
  { "pearofducks/ansible-vim" },
  { "imsnif/kdl.vim" },
  { "maxbane/vim-asm_ca65" },
  { "leafgarland/typescript-vim" },
  { "pangloss/vim-javascript" },
  { "elzr/vim-json" },

  -- ━━ Prettier ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  {

    "cofyc/vim-uncrustify",
    ft = { "cpp", "c", "cs", "objc", "objcpp" },
    config = function()
      _G.GetUncrustifyCfg = function()
        local filename = vim.api.nvim_buf_get_name(0)
        local files = vim.fs.find({ ".uncrustify.cfg" }, { upward = true, path = vim.fs.dirname(filename), type = "file" })
        if #files == 0 then return 0 end
        vim.g.uncrustify_cfg_file_path = files[1]
        return 1
      end

      _G.UncrustifyWrapper = function(language)
        _G.GetUncrustifyCfg()
        vim.cmd("call Uncrustify('" .. language .. "')")
      end

      _G.RangeUncrustifyWrapper = function(language)
        _G.GetUncrustifyCfg()
        vim.cmd("call('Uncrustify2', extend('" .. language .. "', , [a:firstline, a:lastline])")
      end

      -- stylua: ignore start
      autocmd(nil, { "FileType" }, "c", function() noremap("<C-f>", ":call v:lua.UncrustifyWrapper('c')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "c", function() vnoremap("<C-f>", ":call v:lua.RangeUncrustifyWrapper('c')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "cs", function() noremap("<C-f>", ":call v:lua.UncrustifyWrapper('cs')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "cs", function() vnoremap("<C-f>", ":call v:lua.RangeUncrustifyWrapper('cs')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "cpp", function() noremap("<C-f>", ":call v:lua.UncrustifyWrapper('cpp')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "cpp", function() vnoremap("<C-f>", ":call v:lua.RangeUncrustifyWrapper('cpp')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "objc", function() noremap("<C-f>", ":call v:lua.UncrustifyWrapper('objc')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "objc", function() vnoremap("<C-f>", ":call v:lua.RangeUncrustifyWrapper('objc')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "objcpp", function() noremap("<C-f>", ":call v:lua.UncrustifyWrapper('objcpp')<CR>", { buffer = true }) end)
      autocmd(nil, { "FileType" }, "objcpp", function() vnoremap("<C-f>", ":call v:lua.RangeUncrustifyWrapper('objcpp')<CR>", { buffer = true }) end)
      -- stylua: ignore end
    end,
  },

  -- ━━ Autopairs ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  {
    "windwp/nvim-autopairs",
    lazy = false,
    priority = 999,
    config = function()
      local Rule = require("nvim-autopairs.rule")
      local npairs = require("nvim-autopairs")
      local cond = require("nvim-autopairs.conds")

      npairs.setup({
        disable_filetype = {
          "TelescopePrompt",
          "TelescopeResults",
          "Trouble",
          "help",
          "mason",
          "floaterm",
          "Terminal",
          "gitcommit",
          "vim-plug",
          "lspinfo",
          "vim",
          "packer",
          "checkhealth",
          "man",
          "guihua",
          "guihua_rust",
          "clap_input",
        },
      })

      npairs.add_rules({
        Rule("<", ">", { "-html", "-javascriptreact", "-typescriptreact" })
          :with_pair(cond.not_after_regex("[%w%.]"))
          :with_pair(cond.before_regex("%a+:?:?$", 3))
          :with_move(function(opts) return opts.char == ">" end),
        Rule("```", "```", { "rust", "markdown", "vimwiki", "rmarkdown", "rmd", "pandoc", "quarto" }):with_pair(
          cond.not_before_char("`", 3)
        ),
        Rule("```.*$", "```", { "rust", "markdown", "vimwiki", "rmarkdown", "rmd", "pandoc", "quarto" }):only_cr():use_regex(true),
      })
    end,
  },

  -- ━━ autotag (autoclose html) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  {
    "windwp/nvim-ts-autotag",
    opts = {
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
        },
      },
    },
  },

  -- ━━ Completion ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Snippet syntax described here:
  -- <https://github.com/Microsoft/language-server-protocol/blob/master/snippetSyntax.md>
  {
    "hrsh7th/vim-vsnip",
    init = function()
      -- Expand
      imap("<C-n>", "vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-n>'", { expr = true })
      smap("<C-n>", "vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-n>'", { expr = true })

      -- Expand or jump
      imap("<C-s>", "vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-s>'", { expr = true })
      smap("<C-s>", "vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-s>'", { expr = true })

      -- Jump forward or backward
      imap("<Tab>", "vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'", { expr = true })
      smap("<Tab>", "vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'", { expr = true })
      -- Issues: <https://github.com/hrsh7th/nvim-cmp/issues/770>
      imap("<S-Tab>", "vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'", { expr = true })
      smap("<S-Tab>", "vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'", { expr = true })

      -- If you want to use snippet for multiple filetypes, you can `g:vsnip_filetypes` for it.
      vim.g.vsnip_filetypes = {
        javascriptreact = { "javascript" },
        typescriptreact = { "javascript" },
      }
    end,
  }, -- end vim-vsnip

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSP completion source for nvim-cmp
      "hrsh7th/cmp-vsnip", -- Snippet completion source for nvim-cmp
      "hrsh7th/cmp-path", -- Completion for paths
      "hrsh7th/cmp-buffer", -- Completion from buffer
      "hrsh7th/cmp-cmdline", -- Completion for :... commands
      "windwp/nvim-autopairs",
    },
    config = function()
      local cmp = require("cmp")

      -- local function vsnip_complete()
      --   cmp.complete({
      --     config = {
      --       sources = {
      --         { name = 'vsnip' }
      --       }
      --     }
      --   })
      -- end

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local feedkey = function(key, mode) vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true) end

      --local selectopts = { behavior = cmp.SelectBehavior.Select }
      local selectopts = { behavior = cmp.SelectBehavior.Insert }

      cmp.setup({
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },

        completion = {
          completeopt = vim.o.completeopt,
        },

        preselect = cmp.PreselectMode.None,

        -- Enable LSP snippets
        snippet = {
          expand = function(args) vim.fn["vsnip#anonymous"](args.body) end,
        },

        --formatting = {
        --  format = function (entry, vim_item)
        --    vim_item.dup = { buffer = 1, path = 1, nvim_lsp = 0 }
        --  end
        --},

        mapping = {
          ["<C-r>"] = cmp.mapping.select_prev_item(selectopts),
          ["<C-n>"] = cmp.mapping({
            i = function()
              if cmp.visible() then
                cmp.select_next_item(selectopts)
              else
                cmp.complete()
              end
            end,
            c = cmp.mapping.select_next_item(selectopts),
            s = cmp.mapping.select_next_item(selectopts),
          }),
          --['<C-s>'] = cmp.mapping(vsnip_complete, { 'i' }),
          -- Add tab support
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item(selectopts)
            elseif vim.fn["vsnip#jumpable"](-1) == 1 then
              feedkey("<Plug>(vsnip-jump-prev)", "")
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item(selectopts)
            elseif vim.fn["vsnip#available"](1) == 1 then
              feedkey("<Plug>(vsnip-expand-or-jump)", "")
            elseif has_words_before() then
              cmp.complete()
            else
              fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
            end
          end, { "i", "s" }),

          ["<C-,>"] = cmp.mapping.scroll_docs(-4),
          ["<C-.>"] = cmp.mapping.scroll_docs(4),
          ["<C-j>"] = cmp.mapping.close(),
          ["<CR>"] = function(fallback)
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
          { name = "lazydev" },
          { name = "nvim_lsp" },
          { name = "vsnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- Set configuration for specific filetype.
      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          -- { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it.
        }, {
          { name = "buffer" },
        }),
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      -- Doesn't work, for some reason
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", function() cmp_autopairs.on_confirm_done() end)
    end,
  }, -- end cmp

  -- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  -- ┃                           LSP                           ┃
  -- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
  -- ━━ Mason ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  }, -- end mason

  -- ━━ codesettings.nvim ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  {
    "mrjones2014/codesettings.nvim",
    -- branch = "mrj/41/multi-root-support",
    -- dir = vim.fs.joinpath(os.getenv("HOME"), "github/codesettings.nvim"),
    opts = {
      config_file_paths = { ".vscode/settings.json", "codesettings.json", "lspsettings.json" },
      jsonls_integration = true,
      jsonc_filetype = true,
      ---Provide your own root dir; can be a string or function returning a string.
      ---It should be/return the full absolute path to the root directory.
      ---If not set, defaults to `require('codesettings.util').get_root()`
      root_dir = function()
        local filename = vim.api.nvim_buf_get_name(0)
        local dirs = vim.fs.find({ ".vscode" }, { upward = true, path = vim.fs.dirname(filename), type = "directory" })
        if #dirs == 0 then return vim.fs.root(0, { "Cargo.toml", ".git", ".jj" }) end
        local root_dir = vim.fs.dirname(dirs[1])
        return root_dir
      end,
      default_merge_opts = {
        --- How to merge lists; 'append' (default), 'prepend' or 'replace'
        list_behavior = "append",
      },
    },
    ft = { "json", "jsonc" },
  }, -- end codesettings.nvim

  -- ━━ Mason LSP Config ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = false,
      automatic_enable = false,
      ensure_installed = {
        "yamlls",
        "bashls",
        "lua_ls",
        "vimls",
      },
    },
  }, -- end mason_lspconfig

  -- ━━ LSP Config ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "nvim-lua/lsp-status.nvim",
    },
    config = function()
      -- Starting from v0.11 nvim has builtin borders.
      if vim.fn.has("nvim-0.11") == 1 then vim.o.winborder = "rounded" end

      -- Add border to the diagnostic popup window
      vim.diagnostic.config({
        -- Enabled
        --virtual_text = {
        --    prefix = '■ ', -- Could be '●', '▎', 'x', '■', , 
        --},
        -- Disabled
        virtual_text = false,
        signs = true,
        float = { border = "rounded" },
        -- Inline diagnostics/errors/warnings. Available from v0.11:
        virtual_lines = false, -- disabled
        -- virtual_lines = { current_line = true }, -- enabled
      })

      require("lspconfig.ui.windows").default_options = {
        border = _border,
      }

      local lsp_defaults = make_lsp_defaults()
      vim.lsp.config("*", {
        capabilities = lsp_defaults.capabilities,
        on_attach = on_attach,
        on_init = on_init,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("my.lsp", {}),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end
          on_init(client)
        end,
      })

      vim.lsp.handlers["client/registerCapability"] = (function(overridden)
        return function(err, res, ctx)
          local result = overridden(err, res, ctx)
          local client = vim.lsp.get_client_by_id(ctx.client_id)
          if not client then return end
          for bufnr, _ in pairs(client.attached_buffers) do
            -- Call your custom on_attach logic...
            on_attach(client, bufnr)
          end
          return result
        end
      end)(vim.lsp.handlers["client/registerCapability"])

      -- ━━ YAML LS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      local prev_yamlls = vim.lsp.config["yamlls"]
      vim.lsp.config(
        "yamlls",
        vim.tbl_deep_extend("force", prev_yamlls, {
          capabilities = lsp_defaults.capabilities,
          on_attach = on_attach,
          on_init = on_init,
          settings = {
            yaml = {
              keyOrdering = false,
            },
          },
        })
      )

      -- ━━ sourcekit-lsp ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- To enable this for Xcode/iOS projects, install `xcode-build-server` (homebrew)
      -- and run it in the root directory to generate the `buildServer.json`:
      -- $ xcode-build-server config -scheme <XXX> -workspace *.xcworkspace
      -- or
      -- $ xcode-build-server config -scheme <XXX> -project *.xcodeproj
      local prev_sourcekit = vim.lsp.config["sourcekit"]
      vim.lsp.config(
        "sourcekit",
        vim.tbl_deep_extend("force", prev_sourcekit, {
          filetypes = { "swift" },
          capabilities = lsp_defaults.capabilities,
          on_attach = on_attach,
          on_init = on_init,
          cmd = { "xcrun", "--toolchain", "swift", "sourcekit-lsp" },
        })
      )
      vim.lsp.enable("sourcekit")

      -- ━━ Basedpyright ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      local prev_pyright = vim.lsp.config["basedpyright"]
      -- print(vim.inspect(prev_pyright))
      vim.lsp.config(
        "basedpyright",
        vim.tbl_deep_extend("force", prev_pyright, {
          capabilities = lsp_defaults.capabilities,
          on_attach = on_attach,
          on_init = on_init,
          settings = {
            -- python = {
            --   pythonPath = ".venv/bin/python",
            -- },
            basedpyright = {
              analysis = {
                diagnosticMode = "openFilesOnly", -- or "workspace"
                typeCheckingMode = "recommended",
                inlayHints = {
                  genericTypes = true,
                },
              },
            },
          },
        })
      )

      -- ━━ Bacon LSP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- find location with: `:lua =require('vim.lsp.log').get_filename()`
      --vim.lsp.set_log_level('debug')
      --if vim.fn.has 'nvim-0.5.1' == 1 then
      --  require('vim.lsp.log').set_format_func(vim.inspect)
      --end
      local prev_bacon_config = vim.lsp.config["bacon_ls"]
      vim.lsp.config(
        "bacon_ls",
        vim.tbl_deep_extend("force", prev_bacon_config, {
          -- cmd = { 'bacon-ls' },
          -- cmd = { "/local/home/gerstarv/github/bacon-ls/target/release/bacon-ls" },
          single_file_support = false,
          on_attach = on_attach,
          on_init = on_init,
          capabilities = lsp_defaults.capabilities,
          init_options = {
            updateOnSave = true,
            updateOnSaveWaitMillis = 200,
            runBaconInBackground = false,
            synchronizeAllOpenFilesWaitMillis = 1000,
            -- BETA:
            useCargoBackend = true,
            cargoEnv = "CARGO_TARGET_DIR=.checkTarget",
            --cargoCommandArguments = "check --tests --all-targets --message-format json-diagnostic-rendered-ansi",
            -- Clippy takes longer.
            -- add `--all-features` if it works for your project:
            cargoCommandArguments = "clippy --workspace --all-targets --message-format json-diagnostic-rendered-ansi",

            -- This copies the entire source tree to a temporary directory, and will
            -- therefore not work for most cases.
            updateOnChange = false,
            updateOnChangeCooldownMillis = 5000,
          },
        })
      )
      if vim.fn.executable("bacon-ls") ~= 0 then
        -- enable bacon_ls if not installed by mason, and skip by mason.
        vim.lsp.enable("bacon_ls")
      end

      -- ━━ Fish LSP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      vim.lsp.config("fish_lsp", {
        on_attach = on_attach,
        on_init = on_init,
        capabilities = lsp_defaults.capabilities,
      })

      -- ━━ Mason LSP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      local mason_servers = require("mason-lspconfig").get_installed_servers()
      for _, server in ipairs(mason_servers) do
        if not (server == "rust_analyzer" or server == "bacon_ls" or server == "rust-analyzer") then
          -- only enable servers which are not otherwise enabled.
          vim.lsp.enable(server)
        end
      end

      -- ━━ clangd ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      vim.lsp.config("clangd", {
        capabilities = lsp_defaults.capabilities,
        on_attach = on_attach,
        on_init = on_init,
        cmd = { "clangd", "--clang-tidy", "--background-index", "--enable-config" },
        settings = {
          -- must exist, otherwise it won't work.
          clangd = {},
        },
        init_options = {
          fallbackFlags = { "-std=c23" },
        },
      })

      -- ━━ Rust Analyzer ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      vim.lsp.config("rust-analyzer", {
        capabilities = lsp_defaults.capabilities,
        on_attach = on_attach,
        on_init = on_init,
        before_init = function(
          _ --[[params--]],
          config
        )
          local c = require("codesettings")
          local env_ext = require("codesettings.extensions.env")
          config.settings = c.loader()
            :loader_extensions({ env_ext })
            :root_dir(config.root_dir)
            :merge_list_behavior("prepend")
            :config_file_paths({ ".vscode/settings.json", ".myprojectsettings.json" })
            :with_local_settings(config.name, config)
        end,
      })

      -- ━━ Custom CargoReload ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      local function cargo_reload()
        for _, client in ipairs(vim.lsp.get_clients()) do
          if client.name == "rust-analyzer" then client.commands["CargoReload"][1]() end
        end
      end

      vim.api.nvim_create_user_command("CargoReload", cargo_reload, {})

      -- ━━ Toggle LSP Diagnostics ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      vim.g.diagnostics_active = true
      vim.g.diagnostics_config = {}
      function _G.toggle_diagnostics()
        if vim.g.diagnostics_active then
          vim.g.diagnostics_active = false
          vim.diagnostic.reset()
          vim.g.diagnostics_config = vim.diagnostic.config(nil)
          vim.diagnostic.config({
            virtual_text = false,
            signs = false,
            underline = false,
            update_in_insert = false,
          })
        else
          vim.diagnostic.config(vim.g.diagnostics_config)
          vim.g.diagnostics_active = true
        end
      end

      vim.keymap.set("n", "<leader>dt", ":call v:lua.toggle_diagnostics()<CR>", {
        noremap = true,
        silent = true,
        desc = "Toggle LSP Diagnostics",
      })

      -- ━━ Refresh LSP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      function _G.refresh_lsp()
        vim.lsp.stop_client(vim.lsp.get_clients())
        vim.defer_fn(function() vim.cmd("edit") end, 500)
      end
      function _G.stop_lsp()
        -- stops all lsp clients
        vim.lsp.stop_client(vim.lsp.get_clients())
      end

      vim.api.nvim_create_user_command("RefreshLSP", _G.refresh_lsp, { bang = true })
      vim.api.nvim_create_user_command("LspStopAll", _G.stop_lsp, { bang = true })
    end,
  }, -- end lspconfig

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        -- Choose a preset style for diagnostic appearance
        -- Available: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
        preset = "simple",

        -- Make diagnostic background transparent
        transparent_bg = false,

        -- Make cursorline background transparent for diagnostics
        transparent_cursorline = true,

        options = {
          -- Display the source of diagnostics (e.g., "lua_ls", "pyright")
          show_source = {
            enabled = true, -- Enable showing source names
            if_many = true, -- Only show source if multiple sources exist for the same diagnostic
          },

          -- Control how diagnostic messages are displayed
          -- NOTE: When using display_count = true, you need to enable multiline diagnostics with multilines.enabled = true
          --       If you want them to always be displayed, you can also set multilines.always_show = true.
          add_messages = {
            messages = true, -- Show full diagnostic messages
            display_count = true, -- Show diagnostic count instead of messages when cursor not on line
            use_max_severity = false, -- When counting, only show the most severe diagnostic
            show_multiple_glyphs = true, -- Show multiple icons for multiple diagnostics of same severity
          },

          -- Settings for multiline diagnostics
          multilines = {
            enabled = true, -- Enable support for multiline diagnostic messages
            always_show = false, -- Always show messages on all lines of multiline diagnostics
            trim_whitespaces = false, -- Remove leading/trailing whitespace from each line
            tabstop = 4, -- Number of spaces per tab when expanding tabs
          },
        },
      })

      -- Already done in lspconfig
      -- vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
      vim.diagnostic.open_float = require("tiny-inline-diagnostic.override").open_float
    end,
  }, -- end tiny-inline-diagnostic

  {
    -- "mrcjkb/rustaceanvim",
    "leandros/rustaceanvim",
    branch = "reuse_client",
    -- For development:
    -- dir = vim.fs.joinpath(os.getenv("HOME"), "/github/rustaceanvim"),
    version = "^6", -- Recommended
    lazy = false, -- This plugin is already lazy
    dependencies = {
      "nvim-lua/lsp-status.nvim",
    },
    init = function()
      vim.g.rustaceanvim = function()
        local extension_path = ""
        local codelldb_path = ""
        local liblldb_path = ""

        -- Installing debugging capabilities:
        -- 1. Download the CodeLLDB vscode extension.
        -- 2. Find out where its installed. On linux, it's usually in $HOME/.vscode/extensions/...
        -- 3. Update your configuration:
        -- 4. Create a .vimspector.json

        if vim.fn.has("win32") == 1 then
          extension_path = vim.env.HOME .. "/bin/codelldb-x86_64-windows/extension/"
          codelldb_path = extension_path .. "adapter/codelldb.exe"
          liblldb_path = extension_path .. "lldb/lib/liblldb.lib"
        ---@diagnostic disable-next-line: undefined-field
        elseif vim.loop.os_uname().sysname == "Darwin" then
          extension_path = vim.env.HOME .. "/.vscode/extensions/vadimcn.vscode-lldb-1.9.0/"
          codelldb_path = extension_path .. "adapter/codelldb"
          liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
        ---@diagnostic disable-next-line: undefined-field
        elseif vim.loop.os_uname().sysname == "Linux" then
          -- CodeLLDB is installed with:
          -- :VimspectorInstall! --no-check-certificate --verbose CodeLLDB
          local vs_codelldb = vim.fn.stdpath("data") .. "/lazy/vimspector/gadgets/linux/CodeLLDB"
          codelldb_path = vs_codelldb .. "adapter/codelldb"
          liblldb_path = vs_codelldb .. "lldb/lib/liblldb.so"
        end

        local function is_valid_file_path(path)
          local normalized_path = vim.fs.normalize(path, { expand_env = false })
          ---@diagnostic disable-next-line: undefined-field
          local sysname = vim.uv.os_uname().sysname
          if sysname == "Windows" or sysname == "Windows_NT" then return normalized_path:match("^%a:") ~= nil end
          return vim.startswith(normalized_path, "/")
        end

        local lsp_defaults = make_lsp_defaults()
        local rust_analyzer_capabilities = vim.tbl_deep_extend(
          "force",
          lsp_defaults.capabilities,
          -- https://github.com/rust-lang/rust-analyzer/issues/12613
          {
            workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
            -- This disables snippets, which also means no expansion of function parameters/arguments
            -- when a completion is triggered.
            textDocument = { completion = { completionItem = { snippetSupport = false } } },
          }
        )

        local cfg = require("rustaceanvim.config")
        return {
          -- Plugin configuration
          ---@type rustaceanvim.tools.Opts
          tools = {
            reload_workspace_from_cargo_toml = false,
            float_win_config = {
              border = "rounded",
            },
          },

          -- DAP configuration
          ---@type rustaceanvim.dap.Opts
          dap = {
            adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
          },

          -- LSP configuration
          ---@type rustaceanvim.lsp.ClientOpts
          server = {
            -- Automatically detect whether ra-multiplex is installed.
            -- Install with: $ cargo install --locked ra-multiplex
            ra_multiplex = {
              enable = true,
              host = "127.0.0.1",
              port = 27631,
            },
            -- If ra-multiplex autodetection doesn't work use below.
            -- cmd = vim.lsp.rpc.connect("127.0.0.1", 27631),

            -- make sure to load it with our settings
            load_vscode_settings = false,

            ---@diagnostic disable-next-line: unused-local
            on_attach = function(client, bufnr)
              vim.keymap.set(
                "n",
                "K",
                "<cmd>lua vim.cmd.RustLsp({ 'hover', 'actions' })<CR>",
                { silent = true, buffer = bufnr, desc = "LSP: Hover" }
              )
              vim.keymap.set(
                "n",
                "ca",
                "<cmd>lua vim.cmd.RustLsp('codeaction')<CR>",
                { silent = true, buffer = bufnr, desc = "LSP: Code Action" }
              )

              -- Make sure to call this!
              on_attach(client, bufnr)
            end,
            on_init = on_init,
            capabilities = rust_analyzer_capabilities,
            flags = { allow_incremental_sync = false },
            auto_attach = function(bufnr)
              if #vim.bo[bufnr].buftype > 0 then return false end
              local path = vim.api.nvim_buf_get_name(bufnr)
              if not is_valid_file_path(path) then return false end
              -- we don't want to attach if we already have an instance of rust-analyzer
              local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" })
              ---@diagnostic disable-next-line: unused-local
              for _k, v in pairs(clients) do
                if v.name == "rust-analyzer" then
                  print("trying to attach rust-analyzer to buffer with RA attached!!!")
                  -- return false
                end
              end
              return true
            end,
            commands = {
              RustOpenDocs = {
                function()
                  vim.lsp.buf_request(
                    vim.api.nvim_get_current_buf(),
                    "experimental/externalDocs",
                    vim.lsp.util.make_position_params(0, "utf-8"),
                    function(err, url)
                      if err then
                        error(tostring(err))
                      elseif url then
                        ---@diagnostic disable-next-line: undefined-field
                        vim.loop.spawn("open", { args = { "-a", "firefox", "--args", url } })
                      else
                        print("no documentation found")
                      end
                    end
                  )
                end,
                description = "Open documentation for the symbol under the cursor in default browser",
              },
              CargoReload = {
                function()
                  local util = require("lspconfig.util")
                  local bufnr = 0 -- current buffer
                  bufnr = util.validate_bufnr(bufnr)
                  local clients = util.get_lsp_clients({ bufnr = bufnr, name = "rust-analyzer" })
                  for _, client in ipairs(clients) do
                    vim.notify("Reloading Cargo Workspace")
                    client:request("rust-analyzer/reloadWorkspace", nil, function(err)
                      if err then
                        print("error:" .. tostring(err))
                        error(tostring(err))
                      end
                      vim.notify("Cargo workspace reloaded")
                    end, 0)
                  end
                end,
                description = "Reload current cargo workspace",
              },
            },
            -- If rust-analyzer isn't working, try the following:
            -- 1. `cargo clean`
            -- 2. `rm -rf target`
            -- 3. `rm Cargo.lock && cargo build`
            default_settings = {
              -- Options documented here: https://rust-analyzer.github.io/book/configuration.html
              ["rust-analyzer"] = {
                -- Enables ra-multiplex
                lspMux = {
                  version = "1",
                  method = "connect",
                  -- rust-analyzer needs to be in PATH, or specify full path
                  server = "rust-analyzer",
                },
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

                  autoreload = true,
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
                    enable = false,
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
      end
    end,
  }, -- end rustaceanvim

  {
    "saecki/crates.nvim",
    tag = "stable",
    opts = {
      lsp = {
        enabled = true,
        ---@diagnostic disable-next-line: unused-local
        on_attach = function(_client, bufnr)
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
          vim.keymap.set("n", "<leader>cv", show_versions_popup, vim.tbl_extend("force", opts, { desc = "view crate versions" }))
          vim.keymap.set("n", "<leader>cf", show_features_popup, vim.tbl_extend("force", opts, { desc = "view crate features" }))
          vim.keymap.set("n", "<leader>cd", show_dependencies_popup, vim.tbl_extend("force", opts, { desc = "view crate dependencies" }))

          local wk = require("which-key")
          wk.add({ { "<Leader>c", group = "crates.io", icon = "" } })
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
    },
  }, -- end crates.nvim

  {
    "SmiteshP/nvim-navbuddy",
    dependencies = {
      "neovim/nvim-lspconfig",
      "SmiteshP/nvim-navic",
      "MunifTanjim/nui.nvim",
      "numToStr/Comment.nvim", -- Optional
      "nvim-telescope/telescope.nvim", -- Optional
    },
    opts = function()
      local actions = require("nvim-navbuddy.actions")
      return {
        window = {
          border = "single", -- "rounded", "double", "solid", "none"
        },
        use_default_mappings = false,
        mappings = {
          ["<esc>"] = actions.close(), -- Close and cursor to original location
          ["q"] = actions.close(),

          ["n"] = actions.next_sibling(), -- down
          ["r"] = actions.previous_sibling(), -- up

          ["b"] = actions.parent(), -- Move to left panel
          ["s"] = actions.children(), -- Move to right panel
          ["0"] = actions.root(), -- Move to first panel

          ["v"] = actions.visual_name(), -- Visual selection of name
          ["V"] = actions.visual_scope(), -- Visual selection of scope

          ["y"] = actions.yank_name(), -- Yank the name to system clipboard "+
          ["Y"] = actions.yank_scope(), -- Yank the scope to system clipboard "+

          ["i"] = actions.insert_name(), -- Insert at start of name
          ["I"] = actions.insert_scope(), -- Insert at start of scope

          ["a"] = actions.append_name(), -- Insert at end of name
          ["A"] = actions.append_scope(), -- Insert at end of scope

          ["x"] = actions.rename(), -- Rename currently focused symbol

          ["d"] = actions.delete(), -- Delete scope

          ["f"] = actions.fold_create(), -- Create fold of current scope
          ["F"] = actions.fold_delete(), -- Delete fold of current scope

          ["c"] = actions.comment(), -- Comment out current scope

          ["<enter>"] = actions.select(), -- Goto selected symbol
          ["o"] = actions.select(),

          ["N"] = actions.move_down(), -- Move focused node down
          ["R"] = actions.move_up(), -- Move focused node up

          ["<C-i>"] = actions.vsplit(), -- Open selected node in a vertical split
          ["<C-t>"] = actions.hsplit(), -- Open selected node in a horizontal split

          ["t"] = actions.telescope({ -- Fuzzy finder at current level.
            layout_config = { -- All options that can be
              height = 0.60, -- passed to telescope.nvim's
              width = 0.60, -- default can be passed here.
              prompt_position = "top",
              preview_width = 0.50,
            },
            layout_strategy = "horizontal",
          }),

          ["g?"] = actions.help(), -- Open mappings help window
        },
        lsp = {
          preference = { "pylsp" }, -- list of lsp server names in order of preference
        },
      }
    end,
    config = function(_, opts)
      require("nvim-navbuddy").setup(opts)

      vim.keymap.set("n", "<leader>t", ":Navbuddy<CR>", { noremap = true, silent = true, desc = "Navbuddy" })
    end,
  }, -- end nvim-navbuddy

  -- Install CodeLLDB with:
  -- :VimspectorInstall! --no-check-certificate --verbose CodeLLDB
  {
    "puremourning/vimspector",
    dependencies = {
      "mfussenegger/nvim-dap", -- debug adapter for debugging
      "theHamsta/nvim-dap-virtual-text", -- virtual text during debugging
      "rcarriga/nvim-dap-ui", -- for nvim-dap
    },
    init = function()
      vim.g.vimspector_enable_mappings = "HUMAN"
      vim.g.vimspector_install_gadgets = { "CodeLLDB" }
      vim.g.vimspector_base_dir = vim.fn.stdpath("data") .. "/lazy/vimspector"
    end,
    config = function()
      local vimspector_bindings = {
        { "n", "<leader>bl", ":call vimspector#Launch()<CR>", "Launch Debugger" },
        { "n", "<leader>bq", ":VimspectorReset<CR>", "Reset Debugger" },
        { "n", "<leader>bz", "<Plug>VimspectorRestart", "Restart Debugger" },
        { "n", "<leader>bc", "<Plug>VimspectorContinue", "Continue" },
        { "n", "<leader>bd", "<Plug>VimspectorStop", "Stop Debugging" },
        { "n", "<leader>bt", "<Plug>VimspectorRunToCursor", "Run To Cursor" },
        { "n", "<leader>bn", "<Plug>VimspectorStepOver", "Step Over" },
        { "n", "<leader>bsi", "<Plug>VimspectorStepInto", "Step Into" },
        { "n", "<leader>bso", "<Plug>VimspectorStepOut", "Step Out" },
        { "n", "<leader>br", "<Plug>VimspectorToggleBreakpoint", "Toggle Breakpoint" },
        { "n", "<leader>be", ":VimspectorEval", "Eval" },
        { "n", "<leader>bw", ":VimspectorWatch", "Watch Value" },
        { "n", "<leader>bo", ":VimspectorShowOutput", "Show Output" },
        { "n", "<leader>bi", "<Plug>VimspectorBalloonEval", "Balloon Eval" },
        { "x", "<leader>bi", "<Plug>VimspectorBalloonEval", "Balloon Eval" },
      }

      for _, kb in ipairs(vimspector_bindings) do
        vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
      end

      -- Create custom telescope picker with all vimspector commands.
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      function _G.dap_actions_picker(opts)
        opts = opts or {}
        pickers
          .new(opts, {
            prompt_title = "debugger",
            finder = finders.new_table({
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
            }),
            sorter = conf.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, _)
              actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                local index = selection.index
                local binds = {
                  [1] = function() vim.cmd("call vimspector#Launch()") end,
                  [2] = function() vim.cmd("call vimspector#ToggleBreakpoint()") end,
                  [3] = function() vim.cmd("call vimspector#Stop( { 'interactive': v:false } )") end,
                  [4] = function() vim.cmd("call vimspector#Continue()") end,
                  [5] = function() vim.cmd("call vimspector#Pause()") end,
                  [6] = function() vim.cmd("call vimspector#StepOver()") end,
                  [7] = function() vim.cmd("call vimspector#StepInto()") end,
                  [8] = function() vim.cmd("call vimspector#StepOut()") end,
                  [9] = function() vim.cmd("call vimspector#Restart()") end,
                  [10] = function() vim.cmd("call vimspector#Reset( { 'interactive': v:false } )") end,
                  [11] = function() vim.cmd("call vimspector#ListBreakpoints()") end,
                  [12] = function() vim.cmd("call vimspector#Reset()") end,
                }
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
          })
          :find()
      end

      vim.keymap.set("n", "<Leader>ab", ":call v:lua.dap_actions_picker()<CR>")
    end,
  }, -- end vimspector

  -- Pretty diagnostics
  {
    "folke/trouble.nvim",
    opts = {
      action_keys = { -- key mappings for actions in the trouble list
        -- map to {} to remove a mapping, for example:
        -- close = {},
        close = "q", -- close the list
        cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
        refresh = "A", -- manually refresh
        jump = { "<cr>", "<tab>" }, -- jump to the diagnostic or open / close folds
        open_split = { "<c-i>" }, -- open buffer in new split
        open_vsplit = { "<c-t>" }, -- open buffer in new vsplit
        open_tab = { "<c-t>" }, -- open buffer in new tab
        jump_close = { "o" }, -- jump to the diagnostic and close the list
        toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
        switch_severity = "s", -- switch "diagnostics" severity filter level to HINT / INFO / WARN / ERROR
        toggle_preview = "P", -- toggle auto_preview
        hover = "K", -- opens a small popup with the full multiline message
        preview = "p", -- preview the diagnostic location
        close_folds = { "zM", "zm" }, -- close all folds
        open_folds = { "zR", "zr" }, -- open all folds
        toggle_fold = { "zA", "za" }, -- toggle fold of current file
        previous = "r", -- previous item
        next = "n", -- next item
      },
    },
    config = function(_, opts)
      require("trouble").setup(opts)

      nnoremap("<Leader>xd", "<cmd>TroubleToggle workspace_diagnostics<CR>")
    end,
  }, -- end trouble

  -- Highlight groups for trouble.nvim
  {
    "folke/lsp-colors.nvim",
    opts = {
      Error = "#db4b4b",
      Warning = "#e0af68",
      Information = "#0db9d7",
      Hint = "#10B981",
    },
  }, -- end lsp-colors

  {
    "nvim-lua/lsp-status.nvim",
    config = function()
      local lsp_status = require("lsp-status")
      lsp_status.config({
        --component_separator = ' │ ',
        status_symbol = "",
        indicator_errors = "E",
        indicator_warnings = "W",
        indicator_info = "i",
        indicator_hint = "?",
        indicator_ok = "",
      })

      lsp_status.register_progress()
    end,
  }, -- end lsp-status

  -- Statusline (bottom)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "kyazdani42/nvim-web-devicons",
      "nvim-lua/lsp-status.nvim",
    },
    config = function()
      local colors = {
        base03 = "#002b36",
        base02 = "#073642",
        base01 = "#586e75",
        base00 = "#657b83",
        base0 = "#839496",
        base1 = "#93a1a1",
        base2 = "#eee8d5",
        base3 = "#fdf6e3",
        yellow = "#b58900",
        orange = "#cb4b16",
        red = "#dc322f",
        magenta = "#d33682",
        violet = "#6c71c4",
        blue = "#268bd2",
        cyan = "#2aa198",
        green = "#859900",
      }
      local custom_solarized_dark = {
        normal = {
          a = { fg = colors.base03, bg = colors.blue, gui = "bold" },
          b = { fg = colors.base0, bg = colors.base03 },
          c = { fg = colors.base0, bg = colors.base02 },
        },
        insert = { a = { fg = colors.base03, bg = colors.green, gui = "bold" } },
        visual = { a = { fg = colors.base03, bg = colors.magenta, gui = "bold" } },
        replace = { a = { fg = colors.base03, bg = colors.red, gui = "bold" } },
        inactive = {
          a = { fg = colors.base0, bg = colors.base02, gui = "bold" },
          b = { fg = colors.base03, bg = colors.base00 },
          c = { fg = colors.base01, bg = colors.base02 },
        },
      }

      function _G.lualine_setup()
        require("lualine").setup({
          options = {
            icons_enabled = false,
            theme = (vim.opt.background:get() == "dark" and custom_solarized_dark or "solarized_light"),
            component_separators = "│",
            section_separators = "",
            disabled_filetypes = {},
            always_divide_middle = true,
          },
          sections = {
            lualine_b = { "branch", { "diagnostics", sources = { "nvim_diagnostic", "coc" } } },
            lualine_c = { { "filename", file_status = true, path = 1 } },
            --lualine_x = {"vim.fn['zoom#statusline']()", "require'lsp-status'.status()"},
            lualine_x = { "require'lsp-status'.status()" },
            lualine_y = {},
          },
        })
      end

      lualine_setup()
    end,
  }, -- end lualine

  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      function _G.bufferline_setup()
        require("bufferline").setup({
          options = {
            mode = "tabs", -- only show tab pages, not buffers
            show_tab_indicators = false, -- don't need them with mode=tabs
            --style_preset = bufferline.style_preset.minimal,
            -- disable mouse
            right_mouse_command = nil,
            left_mouse_command = nil,
            middle_mouse_command = nil,
            diagnostics = "nvim_lsp",
            separator_style = { "|", "|" }, -- or "slant" | "slope" | "thick" | "thin"
            hover = {
              enabled = false,
            },
            --indicator = {
            --    style = 'underline',
            --},
            show_close_icon = false,
            show_buffer_close_icons = false,
            buffer_close_icon = "󰅖",
            close_icon = "",
            offsets = {
              {
                filetype = "NvimTree",
                text = "File Explorer",
                text_align = "center",
                separator = true,
              },
            },
            diagnostics_indicator = function(count, level)
              local icon = level:match("error") and " " or " "
              return " " .. icon .. count
            end,
          },
        })
      end

      bufferline_setup()
    end,
  }, -- end bufferline

  {
    "ray-x/navigator.lua",
    commit = "17ed4fafd213c5dc821dc6a7051b2b7f156410e4",
    enabled = vim.g["has_navigator"] ~= 0,
    dependencies = {
      {
        "ray-x/guihua.lua",
        build = function() vim.fn.system("cd lua/fzy && make") end,
      },
    },
    config = function()
      require("guihua.maps").setup({
        maps = {
          close_view = "<C-x>",
          prev = "<C-r>",
          next = "<C-n>",
        },
      })

      require("navigator").setup({
        -- lsp servers are installed via `mason`.
        mason = true,
        -- disable all lsp server integration, requires manual setup via `on_attach`.
        lsp = {
          disable_lsp = "all",
          format_on_save = false,
          diagnostic = {
            underline = true,
            virtual_text = true, -- show virtual for diagnostic message
            update_in_insert = false, -- don't update diagnostic message in insert mode
            float = {
              focusable = true,
              sytle = "minimal",
              border = "rounded",
              source = "always",
              header = "",
              prefix = "",
            },
          },
        },

        border = "single",
        --border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"},
        transparency = nil,

        default_mapping = false,
        -- Keymaps defined below.
        keymaps = {},

        icons = {
          icons = true, -- set to false to use system default (if you using a terminal does not have nerd/icon)
          -- Code action
          code_action_icon = "⚐ ",
          -- code lens
          code_lens_action_icon = "",

          -- Diagnostics
          diagnostic_head = " ⚠ ",
          diagnostic_err = "E",
          diagnostic_warn = "W",
          diagnostic_info = "I",
          diagnostic_hint = "H",

          diagnostic_head_severity_1 = " ⚠ ",
          diagnostic_head_severity_2 = " ⚠ ",
          diagnostic_head_severity_3 = " ⚠ ",
          diagnostic_head_description = " ⚠ ",
          diagnostic_virtual_text = "▷",
          diagnostic_file = " ⚠ ",

          -- Values
          value_changed = "",
          value_definition = "",

          -- Treesitter
          match_kinds = {
            ["function"] = "f",
            var = "v",
            method = "m",
            parameter = "p",
            associated = "",
            namespace = "n",
            type = "t",
            field = "",
          },
          treesitter_defult = "",
        },
      })
    end,
  }, -- end navigator.lua

  {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    config = function()
      local function gitsigns_keymap_attach(bufnr)
        local function opts(desc) return { desc = "git: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true } end

        --vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
        --vim.api.nvim_buf_set_keymap(bufnr, 'n', 'hs', '<cmd>lua require"gitsigns".stage_hunk()<CR>', {})

        local function blame_file()
          local function cb()
            local buf = vim.api.nvim_get_current_buf()
            vim.keymap.set("n", "r", "<Up>", { noremap = true, silent = true, buffer = buf })
          end
          ---@diagnostic disable-next-line: param-type-mismatch
          require("gitsigns").blame(cb)
        end

        vim.keymap.set("n", "<leader>ss", "<cmd>Gitsigns stage_hunk<CR>", opts("Stage Hunk"))
        vim.keymap.set("n", "<leader>su", "<cmd>Gitsigns undo_stage_hunk<CR>", opts("Undo Staging Hunk"))
        vim.keymap.set("n", "<leader>sr", "<cmd>Gitsigns reset_hunk<CR>", opts("Reset Hunk"))
        vim.keymap.set("n", "<leader>sR", "<cmd>Gitsigns reset_buffer<CR>", opts("Reset Buffer"))
        vim.keymap.set("n", "<leader>sp", "<cmd>Gitsigns preview_hunk<CR>", opts("Preview Hunk"))
        vim.keymap.set(
          "n",
          "<leader>sb",
          '<cmd>lua require"gitsigns".blame_line{full=true, ignore_whitespace=true}<CR>',
          opts("Blame Line")
        )
        vim.keymap.set("n", "<leader>sB", blame_file, opts("Blame File"))
        vim.keymap.set("n", "<leader>sS", "<cmd>Gitsigns stage_buffer<CR>", opts("Stage Buffer"))
        vim.keymap.set("n", "<leader>sU", "<cmd>Gitsigns reset_buffer_index<CR>", opts("Reset Buffer Index"))
        vim.keymap.set("n", "<leader>sg", "<cmd>Gitsigns<CR>", opts("Picker"))

        vim.keymap.set("v", "<leader>sr", ":Gitsigns reset_hunk<CR>", opts("ResetHunk (Visual)"))
        vim.keymap.set("v", "<leader>ss", ":Gitsigns stage_hunk<CR>", opts("StageHunk (Visual)"))
        vim.keymap.set("v", "<leader>sg", ":Gitsigns<CR>", opts("Picker (Visual)"))
      end

      require("gitsigns").setup({
        on_attach = gitsigns_keymap_attach,
        signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
        numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`

        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
          delay = 1000,
          ignore_whitespace = false,
          virt_text_priority = 100,
          use_focus = true,
        },
        current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",

        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged = {
          add = { text = "┃" },
          change = { text = "┃" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signs_staged_enable = true,
      })
    end,
  }, -- end gitsigns.nvim

  -- {
  --   "tpope/vim-fugitive",
  -- }, -- end vim-fugitive

  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration
      "nvim-telescope/telescope.nvim", -- optional
    },
    config = function()
      require("neogit").setup({
        mappings = {
          rebase_editior = {
            ["r"] = "Reword",
            ["gr"] = "MoveUp",
            ["gn"] = "MoveDown",
          },
          popup = {
            ["r"] = false,
            ["R"] = "RebasePopup",
          },
          status = {
            ["n"] = "MoveDown",
            ["r"] = "MoveUp",
          },
        },
      })
    end,
  }, -- end neogit

  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/playground",
    },
    build = function() vim.cmd(":TSUpdate") end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "rust",
          "json",
          "jsonc",
          "javascript",
          "typescript",
          "tsx",
          "vim",
          "lua",
          "go",
          "haskell",
          "bash",
          "markdown",
          "markdown_inline",
          "python",
          "html",
          "regex",
          "yaml",
        },
        auto_install = false,
        highlight = {
          enable = true,
          disable = { "typescript" },
          additional_vim_regex_highlighting = false,
          custom_captures = {
            ["punctuation.bracket"] = "Variable",
            ["punctuation.delimiter"] = "Variable",
            ["include"] = "Keyword",
            ["keyword.function"] = "Keyword",
          },
        },
      })
    end,
  }, -- end treesitter

  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      enable = true,
      separator = "―",
      min_window_height = 20,
      max_lines = 10,
    },
  }, -- end treesitter-context

  {
    "folke/flash.nvim",
    config = function()
      require("flash").setup({
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
      })

      -- Highlights
      vim.api.nvim_set_hl(0, "FlashBackdrop", { link = "Comment" })
      vim.api.nvim_set_hl(0, "FlashMatch", { link = "Search" })
      vim.api.nvim_set_hl(0, "FlashCurrent", { link = "IncSearch" })

      -- Is set in the solarized settings.
      --vim.api.nvim_set_hl(0, 'FlashLabel', { link = 'WildMenu' })

      -- This mimics leap.nvim:
      --vim.api.nvim_set_hl(0, 'FlashLabel', { cterm = { underline = true, nocombine = true }, ctermfg=9, underline = true, nocombine = true, fg='#ccff88' })

      -- Remove default flash.nvim mapping for comma (,)
      vim.keymap.del({ "n", "o", "x" }, ",")

      -- Keymaps
      vim.keymap.set({ "n", "x", "o" }, "t", "<cmd>lua require('flash').jump()<CR>", { silent = true, desc = "Jump" })
      vim.keymap.set(
        { "n", "x", "o" },
        "T",
        "<cmd>lua require('flash').treesitter_search()<CR>",
        { silent = true, desc = "Treesitter Jump" }
      )
    end,
  }, -- end flash.nvim

  {
    "folke/which-key.nvim",
    config = function()
      local wk = require("which-key")
      wk.setup({
        preset = "classic",
        triggers = {
          { "<auto>", mode = "nixsotc" },
          { "m", mode = { "n", "v" } },
        },
      })
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
        { "<leader>c", group = "codeaction", mode = { "n", "v" } },
        { "<leader>d", group = "lsp" },
        { "<leader>f", group = "findfiles" },
        { "<leader>g", group = "diagnostics/+jump" },
        { "<leader>n", group = "neogen" },
        { "<leader>q", group = "quickfix" },
        { "<leader>r", group = "rename" },
        { "<leader>s", group = "git", mode = { "n", "v" } },
        { "<leader>x", group = "trouble" },
        { "m", group = "bookmarks" },
      })
    end,
  }, -- end whichkey

  {
    "rmagatti/goto-preview",
    config = function()
      require("goto-preview").setup({
        width = 120,
        height = 15,
        default_mappings = false,
        stack_floating_preview_windows = false, -- Whether to nest floating windows
        --debug = true,
      })

      local gotopreview_bindings = {
        { "n", "<leader>dd", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", "Goto Definition" },
        { "n", "<leader>dy", "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", "Goto Type Definition" },
        { "n", "<leader>di", "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", "Goto Implementation" },
        { "n", "<leader>dg", "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>", "Goto Declaration" },
        { "n", "<leader>dq", "<cmd>lua require('goto-preview').close_all_win()<CR>", "Close all Floating Windows" },
        { "n", "<leader>dr", "<cmd>lua require('goto-preview').goto_preview_references()<CR>", "Goto References" },
      }

      for _, kb in ipairs(gotopreview_bindings) do
        vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
      end
    end,
  }, -- end goto-preview

  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)

      function _G.ibl_setup()
        require("ibl").setup({
          indent = {
            char = "",
            -- char = "│",
          },
          exclude = {
            filetypes = {
              "lspinfo",
              "packer",
              "checkhealth",
              "help",
              "man",
              "gitcommit",
              "TelescopePrompt",
              "TelescopeResults",
              "",
            },
          },
          whitespace = {
            remove_blankline_trail = true,
          },
        })
      end

      ibl_setup()
    end,
  }, -- end indent-blankline

  {
    "danymat/neogen",
    config = function()
      require("neogen").setup({
        enabled = true,
      })

      nnoremap("<Leader>ng", "<cmd>lua require('neogen').generate()<cr>")
      nnoremap("<Leader>nf", "<cmd>lua require('neogen').generate({ type = 'file' })<cr>")
      nnoremap("<Leader>nc", "<cmd>lua require('neogen').generate({ type = 'class' })<cr>")
    end,
  }, -- end neogen

  {
    "johnfrankmorgan/whitespace.nvim",
    opts = {
      -- configuration options and their defaults

      -- `highlight` configures which highlight is used to display
      -- trailing whitespace
      highlight = "errorMsg",

      -- `ignored_filetypes` configures which filetypes to ignore when
      -- displaying trailing whitespace
      ignored_filetypes = {
        "TelescopePrompt",
        "Trouble",
        "help",
        "mason",
        "floaterm",
        "Terminal",
        "gitcommit",
        "vim-plug",
        "lspinfo",
        "crates.nvim",
      },
    },
  }, -- end whitespace.nvim

  {
    "tzachar/local-highlight.nvim",
    opts = {
      animate = false,
      file_types = { "rust", "typescript", "typescript.tsx", "javascript", "javascript.jsx", "vim", "bash" },
      hlgroup = "TSDefinitionUsage",
    },
  }, -- end local-highlight

  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    version = "2.*",
    opts = {
      hint = "floating-big-letter",
      autoselect_one = true,
      include_current_win = false,
      selection_chars = "ENCTIRSGOB",
      use_winbar = "never", -- "always" | "never" | "smart"

      -- the foreground (text) color of the picker
      fg_color = "#ededed",

      -- if you have include_current_win == true, then current_win_hl_color will
      -- be highlighted using this background color
      current_win_hl_color = "#e35e4f",

      -- all the windows except the current window will be highlighted using this
      -- color
      other_win_hl_color = "#44cc41",
    },
  }, -- end window-picker

  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      local function nvim_tree_attach(bufnr)
        local api = require("nvim-tree.api")

        local function opts(desc) return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true } end

        -- use all default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- remove mappings
        vim.keymap.del("n", "r", { buffer = bufnr })
        vim.keymap.del("n", "e", { buffer = bufnr })
        vim.keymap.del("n", "-", { buffer = bufnr })

        -- add mappings
        vim.keymap.set("n", "C", api.tree.change_root_to_node, opts("CD"))
        vim.keymap.set("n", "<C-a>", api.tree.reload, opts("Refresh"))
        vim.keymap.set("n", "R", api.fs.rename, opts("Rename"))
        vim.keymap.set("n", "u", api.tree.change_root_to_parent, opts("Up"))
        vim.keymap.set("n", "a", api.fs.create, opts("Create"))
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
              picker = require("window-picker").pick_window,
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

      noremap("<Leader>e", ":NvimTreeToggle<CR>")
    end,
  }, -- end nvim-tree

  {
    "mhartington/formatter.nvim",
    config = function()
      ---@diagnostic disable-next-line: redefined-local
      local autocmd = vim.api.nvim_create_autocmd

      local filetypes = {
        sh = {
          require("formatter.filetypes.sh").shfmt,
        },
        python = {
          function()
            if vim.fn.executable("ruff") ~= 0 then
              return require("formatter.filetypes.python").ruff()
            elseif vim.fn.executable("black") == 1 then
              return require("formatter.filetypes.python").black()
            end
          end,
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
        swift = {
          function()
            return {
              exe = "xcrun",
              args = { "--toolchain", "swift", "swift-format", "format", "-" },
              stdin = true,
            }
          end,
        },
        hcl = {
          function()
            return {
              exe = "tofu",
              args = {
                "fmt",
              },
              stdin = false,
            }
          end,
        },
      }

      -- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
      require("formatter").setup({
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
          },
        }),
      })

      for k, _ in pairs(filetypes) do
        -- equivalent: autocmd FileType gn nnoremap <buffer> <C-f> :Autoformat<CR>
        if k == "javascriptreact" then
          k = "javascript.tsx"
        elseif k == "typescriptreact" then
          k = "typescript.tsx"
        end
        autocmd("FileType", {
          pattern = k,
          callback = function(opts)
            vim.keymap.set("n", "<C-f>", ":FormatWriteLock<CR>", { noremap = false, silent = true, buffer = opts.buf })
          end,
        })
      end
    end,
  }, -- end formatter.nvim

  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-ui-select.nvim", -- Use telescope as native vim select popup, required from NVIM v0.7.0
      "nvim-telescope/telescope-fzy-native.nvim",
    },
    config = function()
      local actions = require("telescope.actions")
      local lga_actions = require("telescope-live-grep-args.actions")

      require("telescope").setup({
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
            },
          },
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
          ]]
          --
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
            require("telescope.themes").get_dropdown({
              -- even more opts
            }),
          },
        },
      })

      -- To get fzf loaded and working with telescope, you need to call
      -- load_extension, somewhere after setup function:
      --require('telescope').load_extension('fzf')
      require("telescope").load_extension("fzy_native")
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("live_grep_args")

      local telescope_bindings = {
        { "n", "<leader>fn", "<cmd>lua require('telescope.builtin').resume()<cr>", "Telescope: Resume" },
        { "n", "<leader>gr", "<cmd>lua require('telescope.builtin').lsp_references()<cr>", "LSP: Find References" },
        { "n", "<leader>gd", "<cmd>lua require('telescope.builtin').diagnostics()<cr>", "LSP: Show Diagnostics" },
        { "n", "<leader>gn", "<cmd>lua require('telescope.builtin').diagnostics({ bufnr = 0 })<cr>", "LSP: Show Current File Diagnostics" },
        { "n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", "LSP: Code Actions" },
        {
          "v",
          "<leader>ca",
          "<cmd>lua vim.lsp.buf.code_action({ range = { start = vim.api.nvim_buf_get_mark(vim.api.nvim_get_current_buf(), '<'), ['end'] = vim.api.nvim_buf_get_mark(vim.api.nvim_get_current_buf(), '>') }})<cr>",
          "LSP: Code Actions",
        },
        { "n", "<leader>gi", "<cmd>lua require('telescope.builtin').lsp_implementations()<cr>", "LSP: Show Implementations" },
        { "n", "<leader>gg", "<cmd>lua require('telescope.builtin').lsp_document_symbols()<cr>", "LSP: Show Document Symbols" },
        { "n", "<leader>ge", "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<cr>", "LSP: Show Workspace Symbols" },
        { "n", "<leader>gt", "<cmd>lua require('telescope.builtin').lsp_type_definitions()<cr>", "LSP: Show Type Definitions" },
        { "n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", "Find Files" },
        { "n", "<leader>fg", "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>", "Live GREP" },
        { "n", "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", "Show Open Buffers" },
        { "n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", "Show Help Tags" },
        { "n", "<leader>fm", "<cmd>lua require('telescope.builtin').marks()<cr>", "Show Marks" },
        { "n", "<leader>fs", "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>", "Fuzzy Find (Current Buf)" },
        { "n", "<leader>v", "<cmd>lua require('telescope.builtin').treesitter()<cr>", "Show Treesitter Symbols" },
      }

      for _, kb in ipairs(telescope_bindings) do
        vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
      end
    end,
  }, -- end telescope.nvim

  {
    "Yggdroot/LeaderF",
    lazy = false,
    build = function() vim.cmd(":LeaderfInstallCExtension") end,
    config = function()
      -- Unmap <leader>b to have it trigger which-key
      autocmd(nil, { "BufReadPost", "BufWinEnter" }, "*", function() vim.cmd("silent! unmap <leader>b") end)
      vim.g.Lf_ShortcutF = "<Leader>o"
      vim.g.Lf_UseVersionControlTool = 0
      vim.g.Lf_ShowRelativePath = 1
      vim.g.Lf_PreviewCode = 0
      vim.g.Lf_WindowHeight = 0.2
      vim.g.Lf_ShowDevIcons = 1
      vim.g.Lf_ShowHidden = 1
      vim.g.Lf_UseCache = 0

      vim.g.Lf_StlSeparator = { left = "", right = "" }
      vim.g.Lf_JumpToExistingWindow = 0

      vim.g.Lf_WildIgnore = {
        dir = {
          ".svn",
          ".git",
          ".p4",
          ".perforce",
          ".plastic",
          "node_modules",
          "temp",
          "Temp",
          "out",
          "_out",
          "_build",
          "extern",
          "build",
          "env",
        },
        file = {
          "*.sw?",
          "~$*",
          "*.bak",
          "*.exe",
          "*.o",
          "*.so",
          "*.pyco",
          "*.dll",
          "*.meta",
          "AssemblyU2DCSharp*",
          "*.a",
          "*.lib",
        },
      }
      vim.g.Lf_CommandMap = {
        ["<C-R>"] = { "<C-E>" },
        ["<C-J>"] = { "<C-N>" },
        ["<C-K>"] = { "<C-R>" },
        ["<C-C>"] = { "<ESC>" },
        ["<C-X>"] = { "<C-T>" },
        ["<C-]>"] = { "<C-I>" },
        ["<C-T>"] = { "<C-X>" },
        ["<C-L>"] = { "<C-D>" },
        ["<F5>"] = { "<C-Z>" },
      }
      vim.g.Lf_PreviewResult = {
        File = 0,
        Buffer = 0,
        Mru = 0,
        Tag = 0,
        BufTag = 0,
        Function = 0,
        Line = 0,
        Colorscheme = 0,
        Rg = 0,
        Gtags = 0,
      }

      local lf_bindings = {
        { "n", "<Leader>o", ":LeaderfFile<CR>", "Open File" },
        { "n", "<Leader>bb", ":LeaderfBuffer<CR>", "Find Buffer" },
        { "n", "<Leader>z", ":LeaderfMruCwd<CR>", "Open Recently Used" },
      }

      for _, kb in ipairs(lf_bindings) do
        vim.keymap.set(kb[1], kb[2], kb[3], { noremap = false, silent = true, desc = kb[4] })
      end
    end,
  }, -- end leaderf

  {
    "voldikss/vim-floaterm",
    init = function()
      vim.g.floaterm_keymap_new = ",a"
      vim.g.floaterm_keymap_toggle = ",n"
      vim.g.floaterm_keymap_prev = ",b"
      vim.g.floaterm_keymap_next = ",s"
      vim.g.floaterm_keymap_kill = ",Q"
      vim.g.floaterm_keymap_hide = ",q"
      vim.g.floaterm_width = 0.8
      vim.g.floaterm_height = 0.8
    end,
    config = function()
      -- This will insert a `,` into the terminal.
      vim.keymap.set("t", ",,", "<C-\\><C-n>i,", { silent = true })
      -- Go back to **VIM** normal-mode.
      -- Described here: <https://github.com/voldikss/vim-floaterm/issues/140>
      vim.keymap.set("t", ",d", "<C-\\><C-n>", { silent = true })
      -- Go back to prev buffer
      vim.keymap.set("t", ",e", "<C-\\><C-n><C-w>w", { silent = true })
      vim.keymap.set("n", ",e", "<C-\\><C-n><C-w>w", { silent = true })
      -- V-Split/H-Split terminals.
      vim.keymap.set("n", ",t", ":FloatermNew --wintype=split --height=20<CR>", { silent = true })
      vim.keymap.set("n", ",i", ":FloatermNew --wintype=vsplit --width=90<CR>", { silent = true })

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
        { ",i", desc = "Split Vertical", mode = { "n", "t" } },
        { ",t", desc = "Split Horizontal", mode = { "n", "t" } },
        { ",e", desc = "Go to last terminal", mode = { "n" } },

        { ",d", desc = "Normal Mode", mode = { "t" } },
        { ",e", desc = "Back to last buffer", mode = { "t" } },
      })
    end,
  }, -- end floaterm

  {
    "amrbashir/nvim-docs-view",
    name = "docs-view",
    build = function() vim.cmd(":DocsViewToggle") end,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      position = "bottom",
      height = 10,
      --width = 60,
      update_mode = "auto",
    },
    keys = {
      { "f", ":DocsViewToggle<CR>", mode = "n", desc = "toggle docs-view" },
    },
  }, -- end docs-view

  {
    "sindrets/diffview.nvim",
    config = function()
      -- Keybinds:
      -- [c -> jump to next
      -- ]c -> jump to prev
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
            { "n", "g?", actions.help({ "view", "diff4" }), { desc = "Open the help panel" } },
          },
        },
        hooks = {
          view_opened = function()
            vim.g.diagnostics_active = false
            vim.diagnostic.reset()
            vim.cmd("LspStop")
          end,
          view_enter = function()
            vim.g.diagnostics_active = false
            vim.diagnostic.reset()
            vim.cmd("LspStop")
          end,
        },
      })
    end,
  }, -- end diffview.nvim

  {
    "LudoPinelli/comment-box.nvim",
    config = function()
      require("comment-box").setup({
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
    end,
  }, -- end comment-box

  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("rustaceanvim.neotest"),
        },
      })

      local wk = require("which-key")
      wk.add({
        { "<Leader>x", group = "Test", icon = "" },
        {
          "<leader>xx",
          function() require("neotest").run.run() end,
          desc = "Test Nearest",
        },
        {
          "<leader>xa",
          function() require("neotest").run.run(vim.fn.expand("%")) end,
          desc = "Test File",
        },
        {
          "<leader>xo",
          function() require("neotest").output.open({ enter = true }) end,
          desc = "Open Output",
        },
        {
          "<leader>xp",
          function() require("neotest").output_panel.toggle() end,
          desc = "Open Output Panel",
        },
        {
          "<leader>xq",
          function() require("neotest").output_panel.clear() end,
          desc = "Clear Output Panel",
        },
        {
          "<leader>xw",
          function() require("neotest").run.attach() end,
          desc = "Test Watch",
        },
      })
    end,
  }, -- end neotest

  {
    "chrisgrieser/nvim-lsp-endhints",
    opts = {
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
    },
  }, -- end lsp-endhints

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        vim.fs.joinpath(tostring(vim.fn.stdpath("data")), "lazy"),
        -- resolved relative to plugin dir
        "lazy.nvim",
      },
      enabled = function() return true end,
    },
  }, -- end lazydev
} -- end spec

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                     Install plugins                     ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- By folke at: https://github.com/folke/lazy.nvim/issues/120#issuecomment-1364482723
local LazyViewConfig = require("lazy.view.config")
-- see ~/.local/share/nvim/lazy/lazy.nvim/lua/lazy/view/config.lua
LazyViewConfig.commands.restore.key_plugin = "gr"

require("lazy").setup({
  spec = spec,
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = {
    missing = true,
    colorscheme = { "solarized" },
  },
  -- do not automatically check for plugin updates
  checker = { enabled = false },
})

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                       Keybindings                       ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
-- Warn about doing the wrong undo (U instead of u).
nnoremap("U", ":echo ' < < ===== C H E C K C A P S L O C K ===== > > '<CR>")

-- Map redo to r instead of C-r
nnoremap("j", "<C-r>")

-- Map Vim Expression valuation
inoremap("<c-a>", "<c-r>")

-- Removed due to blocking super awesome multiline edit mode.
-- Convenient copy to clipboard.
-- vnoremap <C-c> :w !pbcopy<CR><CR>
-- noremap <C-v> :r !pbpaste<CR><CR>

-- Unhighlight searches
-- using <esc> for this, behaves weird
nnoremap("<C-d>", ":noh<return>")

-- Reselect visual blocks after movement
vnoremap("<", "<gv")
vnoremap(">", ">gv")

-- Keep search matches in the middle of the window.
nnoremap("?", "nzzzv")
nnoremap("-", "Nzzzv")

-- Move by words
-- nnoremap("B", "B")
-- nnoremap("S", "W")
nnoremap("<S-b>", "b")
nnoremap("<S-s>", "w")
vnoremap("<S-b>", "b")
vnoremap("<S-s>", "w")
-- Go to end of word
nnoremap("w", "e")
vnoremap("w", "e")

-- Key map optimizations for Bone 2 Layout
-- Normal Mode remaps.
nnoremap("b", "<Left>")
nnoremap("r", "<Up>")
nnoremap("n", "<Down>")
nnoremap("s", "<Right>")
nnoremap("gn", "gj")
nnoremap("gr", "gk")

-- Visual and Select Mode remaps.
vnoremap("b", "<Left>")
vnoremap("r", "<Up>")
vnoremap("n", "<Down>")
vnoremap("s", "<Right>")
vnoremap("gn", "gj")
vnoremap("gr", "gk")

-- Move half page up / down
nnoremap("(", "<C-D>")
nnoremap(")", "<C-U>")
vnoremap("(", "<C-D>")
vnoremap(")", "<C-U>")

-- Move line up down
nnoremap("<S-n>", "<C-e>")
nnoremap("<S-r>", "<C-y>")
vnoremap("<S-n>", "<C-e>")
vnoremap("<S-r>", "<C-y>")

-- Insert newline
-- nnoremap("<CR>", "o<Esc>")
-- inoremap("<C-O>", "<Esc>o")

-- Split switching
nnoremap("<C-p>", "<C-W>w")
nnoremap("<C-n>", "<C-W>j")
nnoremap("<C-r>", "<C-W>k")
nnoremap("<C-b>", "<C-W>h")
nnoremap("<C-s>", "<C-W>l")

-- Split moving
nnoremap("<C-W>B", "<C-W>H")
nnoremap("<C-W>N", "<C-W>J")
nnoremap("<C-W>R", "<C-W>K")
nnoremap("<C-W>S", "<C-W>L")

-- Split resizing
nnoremap("!", ":vertical resize -5<CR>")
nnoremap("=", ":vertical resize +5<CR>")
nnoremap("<", ":resize +5<CR>")
nnoremap(">", ":resize -5<CR>")

-- Even out splits
nnoremap("<C-y>w", "<C-W>=")
nnoremap("<C-y>m", "<C-W>_")
nnoremap("<C-y>t", "<C-W>T")
nnoremap("<C-y>l", ":ZoomWin<CR>")

-- Split Creating
nnoremap("<C-i>", ":vsplit<CR>")
nnoremap("<C-t>", ":split<CR>")

-- Split killing
-- command! Bd bp\|bd \#
vim.api.nvim_create_user_command("Bd", "bp|bd #", { bang = true })
nnoremap("<C-q>", ":BD<CR>")
-- nnoremap("<C-w>", ":bd<CR>")

-- Close / Open quickfix
nnoremap("<Leader>qq", ":cclose<CR>")
nnoremap("<Leader>qc", ":cclose<CR>")
nnoremap("<Leader>qo", ":copen<CR>")

-- Map Y to y$, to behave like D and C
nnoremap("Y", "y$")

-- Jump back in time
nnoremap("<Leader>.", "<C-t>")

-- =============================================================================
-- Tab navigation
-- =============================================================================
nnoremap("<C-u>", ":echo 'nothing happened ...'<CR>")
nnoremap("<C-u>b", ":tabprevious<CR>")
nnoremap("<C-u>s", ":tabnext<CR>")
nnoremap("<C-u>n", ":tabedit<CR>")
nnoremap("<C-u>c", ":tabclose<CR>")
nnoremap("<C-u>1", "1gt")
nnoremap("<C-u>2", "2gt")
nnoremap("<C-u>3", "3gt")
nnoremap("<C-u>4", "4gt")
nnoremap("<C-u>5", "5gt")
nnoremap("<C-u>6", "6gt")

-- Tab switching.
nnoremap("<Leader>1", "1gt")
nnoremap("<Leader>2", "2gt")
nnoremap("<Leader>3", "3gt")
nnoremap("<Leader>4", "4gt")
nnoremap("<Leader>5", "5gt")
nnoremap("<Leader>6", "6gt")
nnoremap("<Leader>7", "7gt")
nnoremap("<Leader>8", "8gt")
nnoremap("<Leader>9", "9gt")

vim.cmd("cabbrev tabv tab sview +setlocal nomodifiable")

-- Profiling
nnoremap("<leader>sP", ":TSHighlightCapturesUnderCursor<CR>")

-- Folding
nnoremap("z(", "zj")
nnoremap("z)", "zk")
