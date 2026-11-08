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
          { key = "f", mods = "NONE", action = act.CopyMode { JumpForward = { prev_char = false } } },
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

-- "copy": copy mode entries of the keys below, "key[mods]=actions;".
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
    local keys = { y = 1, b = 1, B = 1, S = 1, N = 1, R = 1, ["("] = 1, [")"] = 1,
      Y = 1, ["/"] = 1, ["?"] = 1, ["-"] = 1, Escape = 1, f = 1 }
    if keys[k.key] then
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

# gsettings prints the desktop color-scheme from GS ("'prefer-dark'" ...);
# unset GS: it fails, as without the schema.
mkdir -p "$TMP/stubs"
cat > "$TMP/stubs/gsettings" <<'EOF'
#!/bin/sh
[ -n "${GS:-}" ] || exit 1
echo "$GS"
EOF
chmod +x "$TMP/stubs/gsettings"

run() { PATH="$TMP/stubs:$PATH" nvim -l "$HARNESS" "$CONFIG" "$1" "$2" "${3:-}" 2>&1; }

main() {
    command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }
    local linux="x86_64-unknown-linux-gnu" mac="aarch64-apple-darwin"

    expect "Linux, light desktop" "Solarized Light|Solarized Dark" "$(run "$linux" Light)"
    expect "Linux, high-contrast light desktop" "Solarized Light|Solarized Dark" "$(run "$linux" LightHighContrast)"
    expect "Linux, dark desktop" "Solarized Dark|Solarized Light" "$(run "$linux" Dark)"
    expect "Linux mux server (no GUI) stays dark" "Solarized Dark|Solarized Light" "$(run "$linux" none)"
    expect "macOS ignores the appearance" "Solarized Dark|Solarized Light" "$(run "$mac" Light)"

    # The desktop setting from gsettings wins over wezterm's appearance,
    # which reported Light in half the evaluations of a dark desktop.
    expect "gsettings dark, wezterm says Light: dark" "Solarized Dark|Solarized Light" "$(GS="'prefer-dark'" run "$linux" Light)"
    expect "gsettings light, wezterm says Dark: light" "Solarized Light|Solarized Dark" "$(GS="'prefer-light'" run "$linux" Dark)"
    expect "gsettings no preference: dark" "Solarized Dark|Solarized Light" "$(GS="'default'" run "$linux" Light)"

    # Copy mode, as in tmux: y copies and stays (clears the selection), Y
    # copies and leaves; Shift+b / Shift+s by word; N / R one line, ( / )
    # one page; / searches up, ? / - next / previous match in that
    # direction; Escape leaves the search prompt (only AcceptPattern ends
    # pattern editing) and clears the selection; f keeps wezterm's jump to a
    # character. Each key appears once.
    local want=(
        "(\[NONE\]=CopyMode(PageDown)"
        ")\[NONE\]=CopyMode(PageUp)"
        "-\[NONE\]=CopyMode(NextMatch)"
        "/\[NONE\]=CopyMode(EditPattern)"
        "?\[NONE\]=CopyMode(PriorMatch)"
        "B\[SHIFT\]=CopyMode(MoveBackwardWord)"
        "Escape\[NONE\]=CopyMode(AcceptPattern),CopyMode(ClearSelectionMode)"
        "N\[SHIFT\]=ScrollByLine(1)"
        "R\[SHIFT\]=ScrollByLine(-1)"
        "S\[SHIFT\]=CopyMode(MoveForwardWord)"
        "Y\[SHIFT\]=CopyTo(ClipboardAndPrimarySelection),ScrollToBottom,CopyMode(Close)"
        "b\[NONE\]=CopyMode(MoveLeft)"
        "f\[NONE\]=CopyMode(table)"
        "y\[NONE\]=CopyTo(ClipboardAndPrimarySelection),CopyMode(ClearSelectionMode)"
    )
    local got
    got="$(run "$linux" Dark copy | tr ';' '\n' | sed 's/table: 0x[0-9a-f]*/table/')"
    local line
    for line in "${want[@]}"; do
        if grep -qx -- "$line" <<< "$got"; then ok "copy mode: ${line//\\/}"; else fail "copy mode: missing ${line//\\/}"; fi
    done
    expect "copy mode: each key once" "${#want[@]}" "$(grep -c . <<< "$got")"

    exit "$FAILED"
}

main "$@"
