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
local config_path, triple, appearance, what = arg[1], arg[2], arg[3], arg[4]
local handlers = {}
-- wezterm.action: act.Name is a value naming the action, act.Name(arg) a
-- table { name = Name, arg = arg }, so tests can read the key tables.
local act = setmetatable({}, {
  __index = function(_, name)
    return setmetatable({ name = name }, {
      __call = function(_, a) return { name = name, arg = a } end,
    })
  end,
})
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
    -- The defaults the config changes (wezterm's copy mode).
    default_key_tables = function()
      return {
        copy_mode = {
          { key = "y", mods = "NONE", action = act.Multiple {
            act.CopyTo "ClipboardAndPrimarySelection", act.ScrollToBottom, act.CopyMode "Close" } },
          { key = "b", mods = "NONE", action = act.CopyMode "MoveBackwardWord" },
          { key = "w", mods = "NONE", action = act.CopyMode "MoveForwardWord" },
          { key = "Escape", mods = "NONE", action = act.CopyMode "Close" },
        },
        search_mode = {},
      }
    end,
    get_appearance = function() return appearance end,
  }
end
package.preload.wezterm = function()
  return {
    target_triple = triple,
    action = act,
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

-- "copy": the copy mode entries for y, b, B and S, "key[mods]=actions;".
if what == "copy" then
  local function describe(a)
    if type(a) ~= "table" then return tostring(a) end
    if a.name == "Multiple" then
      local parts = {}
      for _, x in ipairs(a.arg) do parts[#parts + 1] = describe(x) end
      return table.concat(parts, ",")
    end
    if a.arg ~= nil then return a.name .. "(" .. tostring(a.arg) .. ")" end
    return a.name
  end
  local out = {}
  for _, k in ipairs(config.key_tables.copy_mode) do
    if k.key == "y" or k.key == "b" or k.key == "B" or k.key == "S" then
      out[#out + 1] = k.key .. "[" .. (k.mods or "") .. "]=" .. describe(k.action)
    end
  end
  table.sort(out)
  io.write(table.concat(out, ";"), "\n")
  return
end

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

run() { nvim -l "$HARNESS" "$CONFIG" "$1" "$2" "${3:-}" 2>&1; }

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    local linux="x86_64-unknown-linux-gnu" mac="aarch64-apple-darwin"

    expect "Linux, light desktop" "Solarized Light|Solarized Dark" "$(run "$linux" Light)"
    expect "Linux, high-contrast light desktop" "Solarized Light|Solarized Dark" "$(run "$linux" LightHighContrast)"
    expect "Linux, dark desktop" "Solarized Dark|Solarized Light" "$(run "$linux" Dark)"
    expect "Linux mux server (no GUI) stays dark" "Solarized Dark|Solarized Light" "$(run "$linux" none)"
    expect "macOS ignores the appearance" "Solarized Dark|Solarized Light" "$(run "$mac" Light)"

    # Copy mode: y copies and stays (clears the selection, as tmux does);
    # Shift+b / Shift+s move by word; each key appears once.
    expect "copy mode keys" \
        "B[SHIFT]=CopyMode(MoveBackwardWord);S[SHIFT]=CopyMode(MoveForwardWord);b[NONE]=CopyMode(MoveLeft);y[NONE]=CopyTo(ClipboardAndPrimarySelection),CopyMode(ClearSelectionMode)" \
        "$(run "$linux" Dark copy)"

    exit "$FAILED"
}

main "$@"
