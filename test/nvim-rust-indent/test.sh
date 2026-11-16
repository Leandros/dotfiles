#!/usr/bin/env bash
#
# Opens a Rust file in nvim headless with the repo's .vim.init.lua and adds
# a line after a comment block with parentheses. rust.vim's indent finds
# comments through regex syntax items; with only tree-sitter highlighting it
# counted the comment's "(" as code and indented 8 instead of 4.
#
# Needs the plugins installed (lazy.nvim data dir).
#
# Usage: test/nvim-rust-indent/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INIT="$HERE/../../.vim.init.lua"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly SRC="$TMP/main.rs" OUT="$TMP/out" CHECK="$TMP/check.lua"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then
        ok "$name"
    else
        fail "$name: want '$want', got '$got'"
    fi
}

# The previous code line ".await?;" makes rust.vim search back for an open
# "(" (end of a method chain); the comment's "(" has its ")" a line later.
write_src() {
    cat > "$SRC" <<'EOF'
fn run() -> Result<(), ()> {
    run.run_ctx(
        "apt-get",
    )
    .await?;

    // Revert all changes (remove the runtime, remove the
    // package).

    Ok(())
}
EOF
}

# Writes "<indent of the new line> <tree-sitter highlighting on|off>".
write_check() {
    cat > "$CHECK" <<EOF
vim.cmd("edit $SRC")
vim.api.nvim_win_set_cursor(0, { 8, 0 })
vim.cmd("normal ox")
local ts = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] and "on" or "off"
local f = io.open("$OUT", "w")
f:write(vim.fn.indent(9), " ", ts)
f:close()
vim.cmd("qa!")
EOF
}

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    write_src
    write_check

    : > "$OUT"
    timeout 30 nvim --headless -u "$INIT" \
        --cmd "autocmd VimEnter * ++once lua vim.defer_fn(function() dofile('$CHECK') end, 100)" \
        > /dev/null 2>&1 || true
    expect "new line after a comment with '(': indent 4, tree-sitter on" "4 on" "$(cat "$OUT")"

    exit "$FAILED"
}

main "$@"
