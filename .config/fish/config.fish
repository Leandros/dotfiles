# @fish-lsp-disable 2002 4004
if status is-interactive
    # Commands to run in interactive sessions can go here
end

## Initialize with:
# $ curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
# $ fisher install PatrickF1/fzf.fish

# Enable debug with: `set -gx fish_trace on`

## All default fish functions are found on GitHub:
## <https://github.com/fish-shell/fish-shell/tree/4.0.1/share/functions>

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Config                                                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
set -gx DEFAULT_USER gerstarv
set -gx HOME /local/home/gerstarv
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx CC gcc
set -gx CXX g++
set -gx LANG en_us.UTF-8
set -gx LC_ALL en_US.UTF-8
set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx AWS_DEFAULT_REGION "us-east-1"
set -gx AWS_PAGER ""
# if you wish to use IMDS set AWS_EC2_METADATA_DISABLED=false
set -gx AWS_EC2_METADATA_DISABLED true
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

# Disable dotnet telemetry.
set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1

# Less modes
set -gx LESS "-R"
set -gx LESSOPEN "|~/.lessfilter %s"

# Colors for ls(1)
set -gx LS_COLORS 'rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34:st=37;44:ex=01;32'

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
# pnpm end

# Go
set -gx GOPATH "$HOME/gopath"

# ━━ macOS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ "Darwin" = "$(uname)" ]
    # Homebrew
    if [ "$(uname -m)" = "arm64" ]
	    /opt/homebrew/bin/brew shellenv | source
    else
        set -gx HOMEBREW_PREFIX "/usr/local"
    end

    set -gx FLAGS_GETOPT_CMD "$HOMEBREW_PREFIX/opt/gnu-getopt/bin/getopt"
    set -gx GREP_OPTIONS '--color=always'
    set -gx GREP_COLOR '1;35;40'

    # Free C-s
    stty -ixon -ixoff
end

# ━━ Linux ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [ "Linux" = "$(uname)" ]
    # Copy&Paste
    if set -q DISPLAY
        alias pbpaste='xclip -o'
        alias pbcopy='xclip -i'
    else if set -q TMUX
        # We're in tmux.
        # X is not running
        alias pbpaste='tmux save-buffer -'
        alias pbcopy='tmux load-buffer -w -'
    else
        # Neither X nor Tmux are running. Use OSC52.
        function pbpaste
            # Unless we can query with OSC 52, we are out of luck.
        end
        function pbcopy
            set -l cmdline
            # Read from stdin
            while read -lz line
                set -a cmdline $line
            end

            set -l encoded (printf %s $cmdline | base64 | string join '')
            printf '\e]52;c;%s\a' "$encoded"
        end
    end

    # Free C-s (blocks `fisher`)
    #stty -ixon -ixoff

    # Set correct term variable if running rxvt.
    if [ "$TERM" = "rxvt-unicode" ]
        set -gx TERM "xterm-256color"
    end
end

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Prompt                                                   ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
function fish_pyenv_prompt
    if [ -x "$VIRTUAL_ENV" ]
        set -l venv_name (basename "$VIRTUAL_ENV")
        set -l prompt (set_color green)" 🐍($venv_name)"(set_color normal)
        echo -n $prompt
    end
end

function fish_prompt
    # Must be absolute first!
    set -l last_status $status

    echo # newline before the prompt

    # Prompt status only if it's not 0
    set -l statline
    if test $last_status -ne 0
        set statline (set_color red)"[$last_status]"(set_color normal)
    end

    # Current mode (unused).
    set -l mode_prompt
    if [ "$fish_bind_mode" = "insert" ]
        set mode_prompt "[I]" # "❯" # or "[I]"
    else if [ "$fish_bind_mode" = "default" ]
        set mode_prompt "[N]" # "❮" # or "[N]"
    else if [ "$fish_bind_mode" = "visual" ]
        set mode_prompt "[V]" # "❮" # or "[V]"
    end

    # Prompt symbol
    set -l prompt_symbol
    if [ "$EUID" = "0" ]
        set prompt_symbol (set_color red)'#'(set_color normal)
    else if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]
        set prompt_symbol (set_color magenta)'%%'(set_color normal)
    else
        set prompt_symbol (set_color magenta)'%'(set_color normal)
    end

    # Line 1 (cwd, vcs, and mode).
    string join '' -- (set_color blue) (prompt_pwd -D 1024) (set_color normal) (fish_vcs_prompt) (fish_pyenv_prompt)

    # Line 2 (status, and prompt char).
    string join '' -- $statline $prompt_symbol ' '
end


# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Keybindings                                              ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
function fish_user_key_bindings
    # Default bindings here:
    # <https://github.com/fish-shell/fish-shell/blob/4.0.1/share/functions/fish_vi_key_bindings.fish>

    # Execute this once per mode that emacs bindings should be used in
    fish_default_key_bindings -M insert

    # Then execute the vi-bindings so they take precedence when there's a conflict.
    # Without --no-erase fish_vi_key_bindings will default to
    # resetting all bindings.
    # The argument specifies the initial mode (insert, "default" or visual).
    fish_vi_key_bindings --no-erase insert

    # Normal mode bindings.
    bind -M default s forward-char
    bind -M default b backward-char
    bind -M default n down-or-search
    bind -M default r up-or-search
    bind -M default S forward-word
    bind -M default B backward-word
    bind -M default w forward-word
    bind -M default \$ end-of-line
    bind -M default 0 beginning-of-line
    bind -M default u undo
    bind -M default j redo
    bind -M default gg beginning-of-buffer
    bind -M default G end-of-buffer
    bind -M default f edit_command_buffer
    bind -M default dd kill-whole-line

    # Visual mode bindings.
    bind -M visual s forward-char
    bind -M visual b backward-char
    bind -M visual n down-or-search
    bind -M visual r up-or-search
    bind -M visual S forward-word
    bind -M visual B backward-word
    bind -M visual w forward-word
    bind -M visual \$ end-of-line
    bind -M visual 0 beginning-of-line
    bind -M visual u undo
    bind -M visual j redo
    bind -M visual gg beginning-of-buffer
    bind -M visual G end-of-buffer

    # Insert mode bindings.
    bind -M insert ctrl-s forward-char
    bind -M insert ctrl-b backward-char

    # Copy&Paste
    function x-copy
        # The following snippet is from `fish_clipboard_copy`.
        set -l cmdline
        if isatty stdin
            # Copy the current selection, or the entire commandline if that is empty.
            # Don't use `string collect -N` here - `commandline` adds a newline.
            set cmdline (commandline --current-selection | __fish_indent --only-indent | string collect)
            test -n "$cmdline"; or set cmdline (commandline | __fish_indent --only-indent | string collect)
        else
            # Read from stdin
            while read -lz line
                set -a cmdline $line
            end
        end

        printf '%s' $cmdline | pbcopy
    end

    function x-paste
        set -l data (pbpaste 2>/dev/null | string collect -N)

        # Issue 6254: Handle zero-length clipboard content
        if not string length -q -- "$data"
            return 1
        end

        if not isatty stdout
            # If we're redirected, just write the data *as-is*.
            printf %s $data
            return
        end

        __fish_paste $data
    end

    bind -M default p 'set -g fish_cursor_end_mode exclusive' forward-char 'set -g fish_cursor_end_modefish_cursor_end_modeinclusive' x-paste
    bind -M default P x-paste
    # @fish-lsp-disable-next-line 2001
    bind -M default Y 'set -l _restore_selection (commandline -C)' begin-selection end-of-line x-copy end-selection 'commandline -C $_restore_selection'
    bind -M default D begin-selection end-of-line x-copy kill-selection end-selection
    bind -M visual -m default y x-copy end-selection repaint-mode
    bind -M visual -m default d x-copy kill-selection end-selection repaint-mode

    # This will put (n)vim in the background and revive it back.
    # It's triggered with ^Z.
    function __foreground-vim
        # @fish-lsp-disable-next-line 2001
        set -l nvimpid (jobs | grep nvim | awk '{print $1}')
        # @fish-lsp-disable-next-line 2001
        set -l vimpid (jobs | grep nvim | awk '{print $1}')
        fg %$nvimpid 2>/dev/null >/dev/null || fg %$vimpid 2>/dev/null >/dev/null
    end
    bind -M insert ctrl-z __foreground-vim
    bind -M default ctrl-z __foreground-vim
    bind -M visual ctrl-z __foreground-vim
end


# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Path                                                     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
# -a => append
# -p -> prepend (default)

fish_add_path -p "/opt/homebrew/bin"
fish_add_path -p "/opt/homebrew/sbin"
fish_add_path -a "$HOME/bin"
fish_add_path -a "$HOME/.fzf/bin"
fish_add_path -a "$HOME/.cargo/bin"
fish_add_path -a "$HOME/.local/bin"
fish_add_path -a "$HOME/.rvm/bin"
fish_add_path -a "$GOPATH/bin"
fish_add_path -a "/usr/local/go/bin"
fish_add_path -a "/usr/local/share/dotnet"
fish_add_path -a "$PNPM_HOME"

# Amazon
if [ -d "$HOME/.brazil_completion" ]
    fish_add_path -a "$HOME/.toolbox/bin"
end


# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ Aliases                                                  ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
alias g='git'
alias ti='tig status'
alias tigs='tig status'
alias untargz='tar -xzf'
alias untarbz='tar -xjf'
alias targz='tar -czf'
alias tarbz='tar -cjf'
alias ccp='rsync -ah --progress'
alias tf='tofu'
alias p='pnpm'
alias pnx="pnpm nx"
alias cd=' cd'

# Amazon
if [ -d "$HOME/.brazil_completion" ]
    alias bb='brazil-build'
    alias b='brazil'
    alias bws='brazil ws'
    alias bre='brazil-runtime-exec'
    alias brc='brazil-recursive-cmd'
    alias bbr='brc brazil-build'
    alias bball='brc --allPackages'
    alias bbb='brc --allPackages brazil-build'
    alias tb='toolbox'
end

# `ls` command.
if [ -x "$(command -v eza)" ]
    alias ls=' eza'
    alias l=' eza -lah'
else if [ "Linux" = (uname) ]
    alias ls=' ls'
    alias l=' ls -lah'
else
    alias ls=' ls --color=auto'
    alias l=' ls -lah'
end

# Lazygit
function lg
    set -gx LAZYGIT_NEW_DIR_FILE $HOME/.lazygit/newdir
    lazygit $argv

    if [ -f "$LAZYGIT_NEW_DIR_FILE" ]
        cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
        rm -f $LAZYGIT_NEW_DIR_FILE >/dev/null
    end
end

# nnn
function n --wraps nnn --description 'support nnn quit and change directory'
    # Block nesting of nnn in subshells
    if test -n "$NNNLVL" -a "$NNNLVL" -ge 1
        echo "nnn is already running"
        return
    end

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "-x" from both lines below,
    # without changing the paths.
    if test -n "$XDG_CONFIG_HOME"
        set -x NNN_TMPFILE "$XDG_CONFIG_HOME/nnn/.lastd"
    else
        set -x NNN_TMPFILE "$HOME/.config/nnn/.lastd"
    end

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The command function allows one to alias this function to `nnn` without
    # making an infinitely recursive alias
    command nnn $argv

    if test -e $NNN_TMPFILE
        source $NNN_TMPFILE
        rm -- $NNN_TMPFILE
    end
end


# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ External                                                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# ━━ FZF ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -gx FZF_DEFAULT_COMMAND 'fd --strip-cwd-prefix --hidden --follow --exclude .git'

set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

# Preview file content using bat (https://github.com/sharkdp/bat)
set -gx FZF_CTRL_T_OPTS "
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-t:change-preview-window(down|hidden|)'"

set -gx FZF_DEFAULT_OPTS "--bind=ctrl-n:down,ctrl-r:up,ctrl-b:backward-char,ctrl-s:forward-char"

set -gx FZF_CTRL_R_OPTS "
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-p:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --bind=ctrl-n:down,ctrl-r:up,ctrl-b:backward-char,ctrl-s:forward-char
  --bind=ctrl-t:toggle-sort
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# Init fzf
if command -q fzf >/dev/null
    # Only use original fzf if fzf.fish is not installed.
    if not fisher list | grep fzf.fish >/dev/null
        fzf --fish | source
    end
end


# ━━ Accounts ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ━━ Zoxide ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -q zoxide
    zoxide init fish | source
end

# ━━ Direnv ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -q direnv
    direnv hook fish | source
end

# ━━ MISE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if command -q mise >/dev/null
    mise activate fish | source
    if not [ -f "$HOME/.config/fish/completions/mise.fish" ]
        # requires a restart
        mise completion fish > "$HOME/.config/fish/completions/mise.fish"
    end
end
