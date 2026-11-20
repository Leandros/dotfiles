#!/usr/bin/env bash
#
# Starts nvim headless with the repo's .vim.init.lua, adds a cursor on each
# of four lines with vim-visual-multi (Ctrl+h) and types the number keys.
# Ctrl+a / Ctrl+x number the cursors (first unchanged, then +1, +2, ...);
# g Ctrl+a / g Ctrl+x add the same delta at every cursor. After Ctrl+c
# (exit), Ctrl+a is Vim's own increment again.
#
# Needs the plugins installed (lazy.nvim data dir).
#
# Usage: test/nvim-visual-multi/test.sh
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

# Writes one line per case: "<name>=<buffer lines joined by ,>".
write_check() {
    cat > "$CHECK" <<EOF
local results = {}
local cursors = { "<C-h>", "<C-h>", "<C-h>" }

-- One feed per key: visual-multi starts and updates with timers.
local function run(name, start, keys)
  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { start, start, start, start })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  for _, k in ipairs(keys) do
    vim.api.nvim_feedkeys(vim.keycode(k), "mx", false)
    vim.wait(150)
  end
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ",")
  results[#results + 1] = name .. "=" .. text
  if vim.b.visual_multi then
    vim.api.nvim_feedkeys(vim.keycode("<C-c>"), "mx", false)
    vim.wait(150)
  end
  vim.bo.modified = false
end

run("inc", "0", vim.list_extend(vim.deepcopy(cursors), { "<C-a>" }))
run("inc2", "0", vim.list_extend(vim.deepcopy(cursors), { "2<C-a>" }))
run("dec", "3", vim.list_extend(vim.deepcopy(cursors), { "<C-x>" }))
run("ginc", "0", vim.list_extend(vim.deepcopy(cursors), { "g<C-a>" }))
run("gdec", "3", vim.list_extend(vim.deepcopy(cursors), { "g<C-x>" }))
run("after", "0", vim.list_extend(vim.deepcopy(cursors), { "<C-c>", "<C-a>" }))

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

    expect "Ctrl+a numbers the cursors" "0,1,2,3" "$(result inc)"
    expect "2 Ctrl+a numbers in steps of 2" "0,2,4,6" "$(result inc2)"
    expect "Ctrl+x numbers down" "3,2,1,0" "$(result dec)"
    expect "g Ctrl+a adds 1 at every cursor" "1,1,1,1" "$(result ginc)"
    expect "g Ctrl+x subtracts 1 at every cursor" "2,2,2,2" "$(result gdec)"
    expect "after exit, Ctrl+a is Vim's increment (cursor on the last line)" "0,0,0,1" "$(result after)"

    exit "$FAILED"
}

main "$@"
