#!/usr/bin/env bash
#
# Starts nvim headless with the repo's .vim.init.lua and types keys after
# VimEnter (which-key and yankstack loaded). d/D/c/C delete into the black
# hole; xx deletes lines into the registers, as dd did before.
#
# Needs the plugins installed (lazy.nvim data dir).
#
# Usage: test/nvim-delete-line/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INIT="$HERE/../../.vim.init.lua"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly OUT="$TMP/out" CHECK="$TMP/check.lua"
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

# Writes one line per case: "<name>=<buffer lines>|<register>|<type>".
write_check() {
    cat > "$CHECK" <<EOF
-- The test must not change the desktop clipboard.
vim.o.clipboard = ""

local results = {}
local function run(name, keys, reg)
  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.fn.setreg('"', "old\n", "V")
  -- One feed per step: yankstack's p queues a key that must run before Alt+p.
  for _, step in ipairs(type(keys) == "table" and keys or { keys }) do
    vim.api.nvim_feedkeys(vim.keycode(step), "mx", false)
    vim.wait(200)
  end
  reg = reg or '"'
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ",")
  local value = vim.fn.getreg(reg):gsub("\n", "\\\\n")
  results[#results + 1] = string.format("%s=%s|%s|%s", name, text, value, vim.fn.getregtype(reg))
  vim.bo.modified = false
end

run("xx", "xx")
run("2xx", "2xx")
run("register", '"axx', "a")
run("dd", "dd")
run("x", "x")
-- yankstack: xx must keep the text it replaces, so Alt+p after a paste
-- goes back to it ("one", not "old"). <Down>: j is redo in this config.
run("yankstack", { "yy", "<Down>", "xx", "p", "<M-p>" })

local f = io.open("$OUT", "w")
f:write(table.concat(results, "\n"), "\n")
f:close()
vim.cmd("qa!")
EOF
}

result() { sed -n "s/^$1=//p" "$OUT"; }

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    write_check

    : > "$OUT"
    timeout 60 nvim --headless -u "$INIT" \
        --cmd "autocmd VimEnter * ++once lua vim.defer_fn(function() dofile('$CHECK') end, 2000)" \
        > /dev/null 2>&1 || true

    expect "xx deletes the line into the register" 'two,three|one\n|V' "$(result xx)"
    expect "2xx deletes two lines" 'three|one\ntwo\n|V' "$(result 2xx)"
    expect '"axx deletes into register a' 'two,three|one\n|V' "$(result register)"
    expect "dd keeps the register" 'two,three|old\n|V' "$(result dd)"
    expect "x deletes a character" 'ne,two,three|o|v' "$(result x)"
    # Only the register: headless, the undo inside Alt+p leaves other text.
    expect "Alt+p after xx and p pastes the older copy" 'one\n|V' "$(result yankstack | cut -d'|' -f2-)"

    exit "$FAILED"
}

main "$@"
