#!/usr/bin/env bash
#
# Starts nvim headless with the repo's .vim.init.lua and checks every glyph
# in render-markdown's resolved config against the character list of the
# terminal font, PragmataPro Mono Liga 0.903 (the font's own coverage file,
# pinned commit). PragmataPro has no Material Design icons, the plugin's
# defaults: wezterm took them from a fallback font and drew them too low.
# Heading icons are the negative circled sans-serif digits (U+278A-U+278F).
# PragmataPro Mono draws the circle of the circled digits (U+2460-U+2465)
# open on the left, so they looked cut off.
#
# Needs the plugins installed (lazy.nvim data dir) and the network.
#
# Usage: test/nvim-markdown-icons/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INIT="$HERE/../../.vim.init.lua"
readonly COVERAGE_URL="https://raw.githubusercontent.com/fabrizioschiavi/pragmatapro/587cc6b15d294acbf1ba8ada79ab66626a34b7f3/generate_coverage/generated%20files/PragmataPro_Mono_R_liga_0903.txt"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly COVERAGE="$TMP/coverage.txt" OUT="$TMP/out" CHECK="$TMP/check.lua"
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

# Writes two lines: the heading icons joined by "|", then the glyphs the
# font lacks ("U+XXXX in <config path>", joined by ", ") or "none".
write_check() {
    cat > "$CHECK" <<EOF
-- Coverage rows: " U+0020  ! \" # ...", one character per present codepoint.
local covered = {}
for line in io.lines("$COVERAGE") do
  local rest = line:match("^ U%+%x+  (.*)$")
  for _, cp in ipairs(rest and vim.fn.str2list(rest) or {}) do
    covered[cp] = true
  end
end

vim.cmd("enew")
vim.bo.filetype = "markdown"
local config = require("render-markdown.state").config

local missing, seen = {}, {}
local function walk(value, path)
  if type(value) == "string" then
    for _, cp in ipairs(vim.fn.str2list(value)) do
      if cp > 127 and not covered[cp] then
        missing[#missing + 1] = string.format("U+%04X in %s", cp, path)
      end
    end
  elseif type(value) == "table" and not seen[value] then
    seen[value] = true
    for k, v in pairs(value) do
      walk(v, path .. "." .. tostring(k))
    end
  end
end
walk(config, "config")
table.sort(missing)

local f = io.open("$OUT", "w")
f:write(table.concat(config.heading.icons, "|"), "\n")
f:write(#missing > 0 and table.concat(missing, ", ") or "none", "\n")
f:close()
vim.cmd("qa!")
EOF
}

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    curl -fsSL -o "$COVERAGE" "$COVERAGE_URL" || { echo "SKIP: coverage download failed"; exit 0; }
    write_check

    : > "$OUT"
    timeout 60 nvim --headless -u "$INIT" \
        --cmd "autocmd VimEnter * ++once lua vim.defer_fn(function() dofile('$CHECK') end, 100)" \
        > /dev/null 2>&1 || true

    expect "heading icons are negative circled digits" "➊ |➋ |➌ |➍ |➎ |➏ " "$(sed -n 1p "$OUT")"
    expect "every render-markdown glyph is in PragmataPro Mono" "none" "$(sed -n 2p "$OUT")"

    exit "$FAILED"
}

main "$@"
