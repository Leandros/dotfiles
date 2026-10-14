#!/usr/bin/env bash
#
# Runs inside the container after bootstrap.sh. Asserts pinned versions,
# symlinks, login shell, and that zsh/nvim start cleanly.
#
set -euo pipefail

readonly SRC="${1:-/src}"
FAILED=0

# Pull the pinned versions from the script itself.
eval "$(grep -E '^readonly [A-Z_0-9]+_(VERSION|VERSION_PIN|REF|VERSION_LINUX|VERSION_MACOS|VERSION_AL2_AARCH64)=' "$SRC/bootstrap.sh")"

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
check_version mise    "$MISE_VERSION" mise --version
check_version direnv  "$DIRENV_VERSION" direnv version
check_version node    "v$node_want" node --version
check_version python  "Python $PYTHON_VERSION" "/usr/local/bin/python$PYTHON_VERSION" --version
check_version nnn     "$NNN_VERSION" nnn -V

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

nvim --headless -c 'checkhealth vim.provider' -c 'w! /tmp/health.txt' +qa >/dev/null 2>&1 || true
python_section="$(awk '/Python 3 provider/{p=1} /Ruby provider/{p=0} p' /tmp/health.txt)"
if [[ "$python_section" == *"OK"* && "$python_section" != *"ERROR"* ]]; then
    ok "nvim :checkhealth python3 provider"
else
    fail "nvim python3 provider: $(printf '%s' "$python_section" | grep -E 'ERROR|WARNING' | head -n 2)"
fi

exit "$FAILED"
