#!/usr/bin/env bash
#
# The clipboard on Linux: bin/pbcopy and bin/pbpaste (~/bin), and .zshrc's
# _clip_paste (vi mode's p). The Wayland clipboard in a Wayland session,
# even with DISPLAY set (xwayland-satellite's X clipboard does not hold what
# Wayland programs copy), else X, else tmux; an empty clipboard falls back
# to the primary selection. pbcopy also works from `zsh -c` without
# .zshrc, as fzf's CTRL-Y runs it. Stubs for wl-copy, wl-paste, xclip, tmux.
#
# Usage: test/zsh-clipboard/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT

command -v zsh >/dev/null || { echo "skip: no zsh"; exit 0; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failed=0
ok()   { printf 'ok:   %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; failed=1; }
expect() {
    if [[ "$3" == "$2" ]]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi
}

# _clip_paste, as .zshrc defines it; pbcopy and pbpaste must not be
# functions or aliases there (they would hide the scripts).
sed -n "/^    _clip_paste() {/,/^    }/p" "$ROOT/.zshrc" >"$TMP/funcs.zsh"
if ! grep -q '_clip_paste() {' "$TMP/funcs.zsh"; then
    fail ".zshrc has no _clip_paste function"
    exit 1
fi
if grep -nE '^\s*(pbcopy|pbpaste)\(\)|^\s*alias pb(copy|paste)=.(xclip|tmux)' "$ROOT/.zshrc"; then
    fail ".zshrc defines pbcopy/pbpaste on Linux"
fi

# Stubs: each selection is a file; an empty one behaves as the tool does
# (wl-paste fails, xclip prints nothing and succeeds).
S="$TMP/sel"
mkdir -p "$TMP/bin" "$S"
cat >"$TMP/bin/wl-paste" <<EOF
#!/usr/bin/env bash
f=$S/wl-clipboard; [[ " \$* " == *" -p "* || " \$* " == *" --primary "* ]] && f=$S/wl-primary
[[ -s \$f ]] || { echo "Nothing is copied" >&2; exit 1; }
cat "\$f"
EOF
cat >"$TMP/bin/wl-copy" <<EOF
#!/usr/bin/env bash
cat >$S/wl-clipboard
EOF
cat >"$TMP/bin/xclip" <<EOF
#!/usr/bin/env bash
sel=primary; [[ " \$* " == *" clipboard "* ]] && sel=clipboard
if [[ " \$* " == *" -o "* ]]; then cat $S/x-\$sel 2>/dev/null; else cat >$S/x-\$sel; fi
EOF
cat >"$TMP/bin/tmux" <<EOF
#!/usr/bin/env bash
case "\$1" in save-buffer) cat $S/tmux 2>/dev/null ;; load-buffer) cat >$S/tmux ;; esac
EOF
chmod +x "$TMP/bin/"*

reset() { rm -f "$S"/*; }
put() { printf '%s' "$2" >"$S/$1"; }
# run ENV... -- ZSH-CODE
run() {
    local envs=()
    while [[ "$1" != -- ]]; do envs+=("$1"); shift; done
    shift
    env -u WAYLAND_DISPLAY -u DISPLAY PATH="$TMP/bin:$ROOT/bin:/usr/bin:/bin" "${envs[@]+"${envs[@]}"}" \
        zsh -f -c "source $TMP/funcs.zsh; $1"
}

reset; put wl-clipboard W; put x-clipboard X
expect "wayland: paste the Wayland clipboard" W "$(run WAYLAND_DISPLAY=wayland-1 DISPLAY=:1 -- _clip_paste)"
reset; put wl-primary WP
expect "wayland: empty clipboard, primary selection" WP "$(run WAYLAND_DISPLAY=wayland-1 DISPLAY=:1 -- _clip_paste)"
reset; put x-clipboard X
expect "X: paste the X clipboard" X "$(run DISPLAY=:0 -- _clip_paste)"
reset; put x-primary XP
expect "X: empty clipboard (xclip succeeds), primary selection" XP "$(run DISPLAY=:0 -- _clip_paste)"
reset; put tmux T
expect "no display: tmux buffer" T "$(run -- _clip_paste)"
reset
expect "nothing anywhere: empty" "" "$(run WAYLAND_DISPLAY=wayland-1 -- _clip_paste)"

reset; run WAYLAND_DISPLAY=wayland-1 DISPLAY=:1 -- 'print -rn -- copied | pbcopy'
expect "wayland: pbcopy writes the Wayland clipboard" copied "$(cat "$S/wl-clipboard" 2>/dev/null)"
reset; run DISPLAY=:0 -- 'print -rn -- xcopied | pbcopy'
expect "X: pbcopy writes the X clipboard" xcopied "$(cat "$S/x-clipboard" 2>/dev/null)"
reset; put wl-clipboard W
expect "wayland: pbpaste" W "$(run WAYLAND_DISPLAY=wayland-1 DISPLAY=:1 -- pbpaste)"
reset; put wl-primary WP
expect "wayland: pbpaste --primary" WP "$(run WAYLAND_DISPLAY=wayland-1 -- 'pbpaste --primary')"
reset; run -- 'print -rn -- tcopied | pbcopy'
expect "no display: pbcopy writes tmux's buffer" tcopied "$(cat "$S/tmux" 2>/dev/null)"

# fzf's CTRL-Y (.zshrc FZF_CTRL_R_OPTS) runs its command with `$SHELL -c`,
# which reads no .zshrc: pbcopy must be a program on PATH.
binding="$(sed -n "s/.*ctrl-y:execute-silent(\(.*\))+abort.*/\1/p" "$ROOT/.zshrc")"
reset
env -u DISPLAY PATH="$TMP/bin:$ROOT/bin:/usr/bin:/bin" WAYLAND_DISPLAY=wayland-1 \
    zsh -f -c "${binding//\{2..\}/'git status'}"
expect "fzf CTRL-Y from zsh -c: copied" "git status" "$(cat "$S/wl-clipboard" 2>/dev/null)"

exit "$failed"
