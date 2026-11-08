#!/usr/bin/env bash
#
# Loads .wezterm.lua with a fake `wezterm` module (Lua in `nvim -l`) and
# checks the color scheme: on Linux it follows the desktop appearance
# (xdg-desktop-portal, set by ~/bin/theme); elsewhere it stays dark. Also
# checks that the toggle event flips the scheme that is shown.
#
# Usage: test/wezterm/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG="$HERE/../../.wezterm.lua"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly HARNESS="$TMP/harness.lua"
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

# Prints "<color_scheme>|<scheme after toggle-dark-mode>".
# Arguments: config path, target triple, appearance ("none": no GUI, as in
# the mux server).
cat > "$HARNESS" <<'LUA'
local config_path, triple, appearance = arg[1], arg[2], arg[3]
local handlers = {}
local proxy
proxy = setmetatable({}, {
  __index = function() return proxy end,
  __call = function() return proxy end,
})
local schemes = setmetatable({}, {
  __index = function(t, k) local v = {}; rawset(t, k, v); return v end,
})
local gui = nil
if appearance ~= "none" then
  gui = {
    default_key_tables = function() return { copy_mode = {}, search_mode = {} } end,
    get_appearance = function() return appearance end,
  }
end
package.preload.wezterm = function()
  return {
    target_triple = triple,
    action = proxy,
    action_callback = function(f) return f end,
    color = { get_builtin_schemes = function() return schemes end },
    default_hyperlink_rules = function() return {} end,
    font_with_fallback = function() return {} end,
    glob = function() return {} end,
    gui = gui,
    on = function(name, f) handlers[name] = f end,
  }
end

local config = dofile(config_path)
local overrides = nil
local window = {
  get_config_overrides = function() return overrides end,
  set_config_overrides = function(_, o) overrides = o end,
  effective_config = function()
    return { color_scheme = (overrides and overrides.color_scheme) or config.color_scheme }
  end,
}
handlers["toggle-dark-mode"](window)
io.write(config.color_scheme, "|", overrides.color_scheme, "\n")
LUA

run() { nvim -l "$HARNESS" "$CONFIG" "$1" "$2" 2>&1; }

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    local linux="x86_64-unknown-linux-gnu" mac="aarch64-apple-darwin"

    expect "Linux, light desktop" "Solarized Light|Solarized Dark" "$(run "$linux" Light)"
    expect "Linux, high-contrast light desktop" "Solarized Light|Solarized Dark" "$(run "$linux" LightHighContrast)"
    expect "Linux, dark desktop" "Solarized Dark|Solarized Light" "$(run "$linux" Dark)"
    expect "Linux mux server (no GUI) stays dark" "Solarized Dark|Solarized Light" "$(run "$linux" none)"
    expect "macOS ignores the appearance" "Solarized Dark|Solarized Light" "$(run "$mac" Light)"

    exit "$FAILED"
}

main "$@"
