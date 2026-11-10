#!/usr/bin/env bash
#
# Starts nvim headless with the repo's .vim.init.lua and a gsettings stub:
# on Linux the background follows the desktop color-scheme (set by
# ~/bin/theme) at start and when it changes.
#
# Needs the plugins installed (lazy.nvim data dir).
#
# Usage: test/nvim-theme/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INIT="$HERE/../../.vim.init.lua"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" OUT="$TMP/out"
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

# get: START ("fail": no desktop setting, as on a server); monitor: after
# 1 s the change to CHANGE, then waits.
write_stub() {
    mkdir -p "$STUBS"
    cat > "$STUBS/gsettings" <<'EOF'
#!/bin/sh
case "$1" in
    get) [ "$START" = fail ] && exit 1; echo "'$START'" ;;
    monitor) sleep 1; echo "color-scheme: '$CHANGE'"; exec sleep 30 ;;
esac
EOF
    chmod +x "$STUBS/gsettings"
}

# Prints "<background at VimEnter> <background 3 s later>"; with
# PRINT_COLORCOLUMN set, the ColorColumn background at VimEnter instead.
run() {
    : > "$OUT"
    START="$1" CHANGE="$2" PATH="$STUBS:$PATH" timeout 30 nvim --headless -u "$INIT" \
        --cmd "autocmd VimEnter * ++once lua vim.defer_fn(function()
            local f = io.open('$OUT', 'w')
            if os.getenv('PRINT_COLORCOLUMN') then
              f:write(string.format('#%06x', vim.api.nvim_get_hl(0, { name = 'ColorColumn' }).bg))
              f:close()
              vim.cmd('qa!')
              return
            end
            f:write(vim.o.background, ' ')
            vim.wait(3000, function() return vim.o.background ~= '$3' end)
            f:write(vim.o.background, '\n')
            f:close()
            vim.cmd('qa!')
        end, 100)" > /dev/null 2>&1 || true
    tr -d '\n' < "$OUT"
}

# Prints for the mode at start, then after the desktop change: "same" when
# FlashBackdrop, FlashMatch and FlashCurrent look like Comment, Search and
# IncSearch, else the first group that differs.
flash_run() {
    : > "$OUT"
    START="$1" CHANGE="$2" PATH="$STUBS:$PATH" timeout 30 nvim --headless -u "$INIT" \
        --cmd "autocmd VimEnter * ++once lua vim.defer_fn(function()
            local function check()
              local groups = { { 'FlashBackdrop', 'Comment' }, { 'FlashMatch', 'Search' }, { 'FlashCurrent', 'IncSearch' } }
              for _, pair in ipairs(groups) do
                local flash = vim.api.nvim_get_hl(0, { name = pair[1], link = false })
                local base = vim.api.nvim_get_hl(0, { name = pair[2], link = false })
                if not vim.deep_equal(flash, base) then return pair[1] end
              end
              return 'same'
            end
            local f = io.open('$OUT', 'w')
            f:write(check(), ' ')
            vim.wait(3000, function() return vim.o.background ~= '$3' end)
            f:write(check(), '\n')
            f:close()
            vim.cmd('qa!')
        end, 100)" > /dev/null 2>&1 || true
    tr -d '\n' < "$OUT"
}

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    write_stub

    expect "light desktop at start, then dark" "light dark" "$(run prefer-light prefer-dark light)"
    expect "dark desktop at start, then light" "dark light" "$(run prefer-dark prefer-light dark)"
    expect "no preference is dark" "dark dark" "$(run default default nothing)"
    expect "server, LC_COLOR_SCHEME=light" "light light" "$(LC_COLOR_SCHEME=light run fail fail x)"
    expect "server, no variable: dark" "dark dark" "$(run fail fail x)"
    expect "the desktop setting wins over LC_COLOR_SCHEME" "dark dark" "$(LC_COLOR_SCHEME=light run prefer-dark prefer-dark x)"
    expect "light start: light ColorColumn" "#eee8d5" "$(PRINT_COLORCOLUMN=1 run prefer-light prefer-light x)"
    expect "dark start: dark ColorColumn" "#004653" "$(PRINT_COLORCOLUMN=1 run prefer-dark prefer-dark x)"
    # The colorscheme reload on a change must keep the flash.nvim groups.
    expect "flash colors: dark, then light" "same same" "$(flash_run prefer-dark prefer-light dark)"
    expect "flash colors: light, then dark" "same same" "$(flash_run prefer-light prefer-dark light)"

    exit "$FAILED"
}

main "$@"
