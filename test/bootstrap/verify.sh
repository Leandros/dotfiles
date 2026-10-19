#!/usr/bin/env bash
#
# Runs inside the container after bootstrap.sh. Asserts pinned versions,
# symlinks, login shell, and that zsh/nvim start cleanly.
#
set -euo pipefail

readonly SRC="${1:-/src}"
FAILED=0

# Pull the pinned versions from the script itself.
eval "$(grep -E '^readonly [A-Z_0-9]+_(VERSION|VERSION_PIN|REF|VERSION_LINUX|VERSION_MACOS|VERSION_AL2_AARCH64|TOOLCHAIN)=' "$SRC/bootstrap.sh")"

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

check_version() {
    local name="$1" want="$2"
    shift 2
    local out
    out="$("$@" 2>&1 | head -n 2 | tr '\n' ' ' || true)"
    if [[ "$out" == *"$want"* ]]; then
        ok "$name $want"
    else
        fail "$name: want '$want', got '$out'"
    fi
}

check_link() {
    local dst="$1" src="$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        ok "link $dst"
    else
        fail "link $dst -> $(readlink "$dst" 2>/dev/null || echo MISSING)"
    fi
}

check_pin() {
    local dir="$1" ref="$2"
    if [[ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" == "$ref" ]]; then
        ok "pin $dir"
    else
        fail "pin $dir not at $ref"
    fi
}

export PATH="/usr/local/bin:$PATH"
arch="$(uname -m)"
is_al2=0
grep -q 'VERSION_ID="2"' /etc/os-release && is_al2=1

node_want="$NODE_VERSION"
if [[ $is_al2 -eq 1 && "$arch" == "aarch64" ]]; then
    node_want="$NODE_VERSION_AL2_AARCH64"
fi

check_version zsh     "zsh $ZSH_VERSION_PIN" /usr/local/bin/zsh --version
check_version tmux    "tmux $TMUX_VERSION_LINUX" tmux -V
check_version nvim    "NVIM v$NVIM_VERSION" nvim --version
check_version fzf     "$FZF_VERSION" fzf --version
check_version zoxide  "zoxide $ZOXIDE_VERSION" zoxide --version
check_version yazi    "Version: $YAZI_VERSION" yazi --version
check_version lazygit "version=$LAZYGIT_VERSION" lazygit --version
check_version uv      "uv $UV_VERSION" uv --version
check_version fd      "fd $FD_VERSION" fd --version
check_version rg      "ripgrep $RIPGREP_VERSION" rg --version
check_version bat     "bat $BAT_VERSION" bat --version
check_version mise    "$MISE_VERSION" mise --version
check_version direnv  "$DIRENV_VERSION" direnv version
check_version rustc   "rustc $RUST_TOOLCHAIN" "$HOME/.cargo/bin/rustc" --version
check_version tree-sitter "tree-sitter $TREE_SITTER_VERSION" tree-sitter --version
check_version node    "v$node_want" node --version
check_version python  "Python $PYTHON_VERSION" "/usr/local/bin/python$PYTHON_VERSION" --version
check_version nnn     "$NNN_VERSION" nnn -V

codelldb_dir="$HOME/.local/share/nvim/lazy/vimspector/gadgets/linux/CodeLLDB"
if [[ -x "$codelldb_dir/adapter/codelldb" && -f "$codelldb_dir/lldb/lib/liblldb.so" ]] \
    && "$codelldb_dir/adapter/codelldb" --help >/dev/null 2>&1; then
    ok "codelldb $CODELLDB_VERSION"
else
    fail "codelldb missing or not runnable in $codelldb_dir"
fi

check_version pynvim  "$PYNVIM_VERSION" \
    "$HOME/.local/share/nvim/python3-venv/bin/python" -c 'import importlib.metadata as m; print(m.version("pynvim"))'
check_version node-neovim "neovim@$NODE_NEOVIM_VERSION" npm ls -g --prefix /usr/local neovim --depth=0 --parseable --long

D="$HOME/.dotfiles"
check_link "$HOME/.zsh" "$D/.zsh"
check_link "$HOME/.gitconfig" "$D/.gitconfig"
check_link "$HOME/.config/nvim/init.lua" "$D/.vim.init.lua"
check_link "$HOME/.config/nvim/lazy-lock.json" "$D/lazy-lock.json"
check_link "$HOME/.tmux.conf" "$D/tmux/tmux_linux_$TMUX_VERSION_LINUX/.tmux.conf"
check_link "$HOME/.tmux/custom" "$D/.tmux/custom"
check_link "$HOME/.config/yazi" "$D/.config/yazi"
check_link "$HOME/.config/lazygit/config.yml" "$D/AppData/Roaming/lazygit/config.yml"

# Xorg checks: distros where bootstrap installs the desktop (RHEL only up to 9).
xorg_expected=0
# shellcheck disable=SC1091
os_id="$(. /etc/os-release && echo "$ID")"
# shellcheck disable=SC1091
os_major="$(. /etc/os-release && echo "${VERSION_ID%%.*}")"
case "$os_id" in
    debian|ubuntu|fedora) xorg_expected=1 ;;
    rocky|almalinux|centos|rhel) [[ "$os_major" -le 9 ]] && xorg_expected=1 ;;
esac
if [[ $xorg_expected -eq 1 ]]; then
    check_link "$HOME/.xinitrc" "$D/.xinitrc"
    check_link "$HOME/.xprofile" "$D/.xprofile"
    check_link "$HOME/bin/kb" "$D/bin/kb"
    if [[ -f "$HOME/.Xresources" && ! -L "$HOME/.Xresources" ]] && grep -qE '^Xft\.dpi:\s+144$' "$HOME/.Xresources" \
        && ! grep -q '##XFT_DPI##' "$HOME/.Xresources"; then
        ok ".Xresources rendered with Xft.dpi 144 (1.5x)"
    else
        fail ".Xresources: $(grep -E '^Xft\.dpi' "$HOME/.Xresources" 2>/dev/null || echo missing)"
    fi
    kb_out="$(env -u DISPLAY "$HOME/bin/kb" 2>&1 || true)"
    if [[ "$kb_out" == *"no X display"* ]]; then
        ok "kb runs and refuses without DISPLAY"
    else
        fail "kb: $kb_out"
    fi
    check_link "$HOME/.Xmodmap" "$D/.Xmodmap"
    check_link "$HOME/.xbindkeysrc" "$D/.xbindkeysrc"
    check_link "$HOME/.config/i3" "$D/.config/i3"
    check_link "$HOME/.config/i3status" "$D/.config/i3status"
    check_link "$HOME/.wezterm.lua" "$D/.wezterm.lua"
    wezterm_stamp="$(cat /usr/local/share/bootstrap/wezterm 2>/dev/null || true)"
    check_version wezterm "wezterm $wezterm_stamp" wezterm --version
    if [[ "$wezterm_stamp" == 2026* || "$wezterm_stamp" == 2027* ]]; then
        ok "wezterm is a recent nightly ($wezterm_stamp)"
    else
        fail "wezterm stamp not a nightly build: '$wezterm_stamp'"
    fi
    for bin in i3 i3status dmenu xsetroot xset setxkbmap xmodmap amixer brightnessctl startx; do
        if command -v "$bin" >/dev/null; then ok "xorg bin $bin"; else fail "xorg bin missing: $bin"; fi
    done
    # Not packaged for EL9.
    if grep -qE '^ID=(debian|ubuntu|fedora)$' /etc/os-release; then
        if command -v xbindkeys >/dev/null; then ok "xorg bin xbindkeys"; else fail "xorg bin missing: xbindkeys"; fi
    fi
    # i3 validates its config without a display.
    if i3 -C -c "$HOME/.config/i3/config" >/tmp/i3.log 2>&1; then
        ok "i3 config valid"
    else
        fail "i3 config: $(head -n 2 /tmp/i3.log)"
    fi
fi

check_pin "$HOME/.oh-my-zsh" "$OHMYZSH_REF"
check_pin "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$ZSH_AUTOSUGGESTIONS_REF"
check_pin "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "$ZSH_SYNTAX_HIGHLIGHTING_REF"
check_pin "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" "$FAST_SYNTAX_HIGHLIGHTING_REF"
check_pin "$HOME/.tmux/plugins/tpm" "$TPM_REF"

if grep -q '##NEW' "$HOME/.zshrc"; then
    fail ".zshrc still has placeholders"
else
    ok ".zshrc placeholders replaced"
fi
if grep -q "^export HOME=$HOME\$" "$HOME/.zshrc"; then
    ok ".zshrc HOME"
else
    fail ".zshrc HOME not set to $HOME"
fi

if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "/usr/local/bin/zsh" ]]; then
    ok "login shell"
else
    fail "login shell is $(getent passwd "$USER" | cut -d: -f7)"
fi

if /usr/local/bin/zsh -i -c 'exit 0' >/tmp/zsh.log 2>&1; then
    ok "zsh -i starts"
else
    fail "zsh -i: $(head -n 3 /tmp/zsh.log)"
fi

if nvim --headless -c 'lua if vim.fn.filereadable(vim.g.python3_host_prog) == 0 then os.exit(1) end' +qa >/tmp/nvim.log 2>&1; then
    ok "nvim python3_host_prog"
else
    fail "nvim python3_host_prog: $(head -n 3 /tmp/nvim.log)"
fi

if [[ -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]]; then
    ok "lazy.nvim installed"
else
    fail "lazy.nvim missing"
fi

# lazy.nvim may leave the checkout detached; compare against the lockfile pin.
ts_want="$(sed -nE 's/.*"nvim-treesitter": \{ "branch": "main", "commit": "([0-9a-f]+)".*/\1/p' "$SRC/lazy-lock.json")"
ts_have="$(git -C "$HOME/.local/share/nvim/lazy/nvim-treesitter" rev-parse HEAD 2>/dev/null || true)"
if [[ -n "$ts_want" && "$ts_have" == "$ts_want" ]]; then
    ok "nvim-treesitter at main pin $ts_want"
else
    fail "nvim-treesitter: want main@$ts_want got $ts_have"
fi

parser_dir="$HOME/.local/share/nvim/site/parser"
missing_parsers=""
for lang in c cpp cmake rust json json5 javascript typescript tsx vim lua go haskell bash markdown markdown_inline python html regex yaml zig; do
    [[ -f "$parser_dir/$lang.so" ]] || missing_parsers="$missing_parsers $lang"
done
if [[ -z "$missing_parsers" ]]; then
    ok "treesitter parsers built"
else
    fail "treesitter parsers missing:$missing_parsers"
fi

# The hover window renders markdown with injections; this is what broke on master.
# shellcheck disable=SC2016
if nvim --headless -c 'set ft=markdown' -c 'call setline(1, ["```rust", "fn main() {}", "```"])' \
    -c 'lua vim.treesitter.get_parser(0):parse(true)' +qa! >/tmp/ts.log 2>&1; then
    ok "markdown injection parse"
else
    fail "markdown injection parse: $(head -n 2 /tmp/ts.log)"
fi

# checkhealth probes providers asynchronously; retry if the report came back empty.
python_section=""
for _ in 1 2 3; do
    rm -f /tmp/health.txt
    nvim --headless -c 'checkhealth vim.provider' -c 'w! /tmp/health.txt' +qa >/dev/null 2>&1 || true
    python_section="$(awk '/Python 3 provider/{p=1} /Ruby provider/{p=0} p' /tmp/health.txt 2>/dev/null)"
    [[ -n "$python_section" ]] && break
    sleep 2
done
if [[ "$python_section" == *"OK"* && "$python_section" != *"ERROR"* ]]; then
    ok "nvim :checkhealth python3 provider"
else
    fail "nvim python3 provider: $(printf '%s' "$python_section" | grep -E 'ERROR|WARNING' | head -n 2)"
fi

exit "$FAILED"
