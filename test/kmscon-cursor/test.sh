#!/usr/bin/env bash
#
# kmscon (10.1.1, also upstream main in 2026-11) draws a beam cursor
# (DECSCUSR 5/6) in place of the character under it (src/render/text.c:
# cursor.cell.ch = FONT_VBAR). On TERM=kmscon the insert-mode cursor is an
# underline instead, which keeps the character:
#   - .zshrc's vi mode sends 4 instead of 6;
#   - tmux's override for kmscon clients maps 5/6 to 3/4 (zsh and nvim inside
#     tmux see tmux's TERM and send 6);
#   - nvim's guicursor uses hor20 instead of ver25.
#
# Usage: test/kmscon-cursor/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
TMUX_CONF="$ROOT/tmux/tmux_linux_$(sed -n 's/^readonly TMUX_VERSION_LINUX="\(.*\)"/\1/p' "$ROOT/bootstrap.sh")/.tmux.conf"
readonly TMUX_CONF

TMP="$(mktemp -d)"
trap 'tmux -L "kmscon-cursor-$$" kill-server 2>/dev/null || true; rm -rf "$TMP"' EXIT
failed=0
ok()   { printf 'ok:   %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; failed=1; }
expect() {
    if [[ "$3" == "$2" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi
}

# zsh: the cursor code and the vi mode hooks, as .zshrc defines them.
sed -n '/^# Insert mode cursor/,/^zle -N zle-keymap-select/p' "$ROOT/.zshrc" >"$TMP/cursor.zsh"
if command -v zsh >/dev/null; then
    zsh_cursor() {
        TERM="$1" zsh -f -c "zle() { :; }; source $TMP/cursor.zsh; KEYMAP=$2; zle-keymap-select" | od -An -c | tr -s ' '
    }
    expect "zsh on kmscon: insert mode underline" "$(printf '\e[4 q' | od -An -c | tr -s ' ')" "$(zsh_cursor kmscon viins)"
    expect "zsh elsewhere: insert mode beam" "$(printf '\e[6 q' | od -An -c | tr -s ' ')" "$(zsh_cursor xterm-256color viins)"
    expect "zsh on kmscon: normal mode block" "$(printf '\e[2 q' | od -An -c | tr -s ' ')" "$(zsh_cursor kmscon vicmd)"
else
    echo "skip: no zsh"
fi

# tmux: the override parses, and its Ss maps 1..6 to 1 2 3 4 3 4.
line="$(grep -E "^set -as terminal-overrides ',kmscon:Ss=" "$TMUX_CONF" || true)"
if [[ -z "$line" ]]; then
    fail "tmux: no Ss override for kmscon in $TMUX_CONF"
else
    printf '%s\n' "$line" >"$TMP/override.conf"
    # A session keeps the private server alive (an empty one exits).
    if tmux -L "kmscon-cursor-$$" -f /dev/null new-session -d \; source-file "$TMP/override.conf" \
        && tmux -L "kmscon-cursor-$$" show -s terminal-overrides | grep -q 'kmscon:Ss='; then
        ok "tmux: override accepted"
    else
        fail "tmux: override not accepted"
    fi
    cap="$(sed -n "s/.*kmscon:Ss=\(.*\)'$/\1/p" <<<"$line")"
    got="$(python3 -I - "$cap" <<'PY'
import curses, os, sys
curses.setupterm("xterm", os.open(os.devnull, os.O_WRONLY))
cap = sys.argv[1].replace("\\E", "\x1b").encode()
print(" ".join(curses.tparm(cap, n).decode()[2:-2] for n in range(1, 7)))
PY
)"
    expect "tmux: Ss sends DECSCUSR 1 2 3 4 3 4 for 1..6" "1 2 3 4 3 4" "$got"
fi

# nvim: guicursor on kmscon and elsewhere (only the kmscon line of the config).
grep -E '^if vim.env.TERM == "kmscon"' "$ROOT/.vim.init.lua" >"$TMP/cursor.lua" || true
if [[ ! -s "$TMP/cursor.lua" ]]; then
    fail "nvim: no kmscon guicursor line in .vim.init.lua"
elif command -v nvim >/dev/null; then
    nvim_cursor() {
        TERM="$1" nvim --clean --headless --cmd "luafile $TMP/cursor.lua" \
            +'lua io.write(vim.o.guicursor)' +qa 2>&1
    }
    k="$(nvim_cursor kmscon)" x="$(nvim_cursor xterm-256color)"
    if [[ "$k" == *"i-ci-ve:hor20"* && "$k" != *ver25* ]]; then ok "nvim on kmscon: insert hor20"; else fail "nvim on kmscon: $k"; fi
    if [[ "$x" == *"i-ci-ve:ver25"* ]]; then ok "nvim elsewhere: insert ver25"; else fail "nvim elsewhere: $x"; fi
else
    echo "skip: no nvim"
fi

exit "$failed"
