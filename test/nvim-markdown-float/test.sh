#!/usr/bin/env bash
#
# Opens an LSP-style markdown float (buftype nofile) in nvim headless with
# the repo's .vim.init.lua. render-markdown must render it, but must not
# paint backgrounds other than NormalFloat: code blocks, the language line,
# inline code and headings had ColorColumn and Diff* backgrounds.
#
# Needs the plugins installed (lazy.nvim data dir).
#
# Usage: test/nvim-markdown-float/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INIT="$HERE/../../.vim.init.lua"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" OUT="$TMP/out" CHECK="$TMP/check.lua"
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

# No desktop setting: the mode comes from LC_COLOR_SCHEME.
write_stub() {
    mkdir -p "$STUBS"
    printf '#!/bin/sh\nexit 1\n' > "$STUBS/gsettings"
    chmod +x "$STUBS/gsettings"
}

# Writes "rendered|not-rendered <groups>" to OUT. <groups> lists the
# render-markdown highlights with a background other than NormalFloat
# ("language-bar" for a bar of block characters), else "none".
write_check() {
    cat > "$CHECK" <<EOF
local lines = {
  "\`\`\`rust",
  "pub fn foo(x: u32) -> u32",
  "\`\`\`",
  "",
  "Docs with \`inline\` code.",
  "",
  "# Examples",
}
local buf = vim.lsp.util.open_floating_preview(lines, "markdown", { border = "single" })
local ns = vim.api.nvim_get_namespaces()["render-markdown.nvim"]
local function marks() return ns and vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }) or {} end
vim.wait(3000, function() return #marks() > 0 end, 50)

local float_bg = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false }).bg
local bad = {}
local function check_group(name)
  local bg = vim.api.nvim_get_hl(0, { name = name, link = false }).bg
  if bg and bg ~= float_bg then bad[name] = true end
end

for _, m in ipairs(marks()) do
  local d = m[4]
  if d.hl_group then check_group(d.hl_group) end
  for _, chunk in ipairs(d.virt_text or {}) do
    if chunk[1]:find("█") then bad["language-bar"] = true end
    local groups = type(chunk[2]) == "table" and chunk[2] or { chunk[2] }
    for _, g in ipairs(groups) do
      if type(g) == "string" then check_group(g) end
    end
  end
end

local names = vim.tbl_keys(bad)
table.sort(names)
local f = io.open("$OUT", "w")
f:write(#marks() > 0 and "rendered " or "not-rendered ", #names > 0 and table.concat(names, ",") or "none")
f:close()
vim.cmd("qa!")
EOF
}

run() {
    : > "$OUT"
    LC_COLOR_SCHEME="$1" PATH="$STUBS:$PATH" timeout 30 nvim --headless -u "$INIT" \
        --cmd "autocmd VimEnter * ++once lua vim.defer_fn(function() dofile('$CHECK') end, 100)" \
        > /dev/null 2>&1 || true
    cat "$OUT"
}

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    write_stub
    write_check

    expect "dark: float rendered, no foreign background" "rendered none" "$(run dark)"
    expect "light: float rendered, no foreign background" "rendered none" "$(run light)"

    exit "$FAILED"
}

main "$@"
