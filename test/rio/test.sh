#!/usr/bin/env bash
#
# Rio's config (.config/rio): valid TOML, key bindings with actions, keys
# and modifiers Rio 0.5.32 accepts (lists from its source,
# frontends/rioterm/src/bindings/mod.rs), no key bound twice, wezterm's
# keys present, the themes it names exist and have .wezterm.lua's
# Solarized colors. Rio itself is not needed (python3 with tomllib).
#
# Usage: test/rio/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT

python3 -I - "$ROOT/.config/rio" "$ROOT/.wezterm.lua" <<'PYEND'
import re, sys, tomllib

rio, lua_path = sys.argv[1], sys.argv[2]
failed = False
def ok(m): print("ok:   " + m)
def fail(m):
    global failed
    failed = True
    print("FAIL: " + m)

ACTIONS = set("""paste quit copy selectall searchforward searchbackward searchconfirm
searchcancel searchclear searchfocusnext searchfocusprevious searchdeleteword
searchhistorynext searchhistoryprevious clearhistory resetfontsize increasefontsize
decreasefontsize createwindow togglequake scrolltoprevprompt scrolltonextprompt
createtab movecurrenttabtoprev movecurrenttabtonext closetab closesplitortab
closeunfocusedtabs openconfigeditor selectprevtab selectnexttab selectlasttab
receivechar scrollpageup scrollpagedown scrollhalfpageup scrollhalfpagedown
scrolltotop scrolltobottom splitright splitdown selectnextsplit selectprevsplit
selectnextsplitortab selectprevsplitortab movedividerup movedividerdown
movedividerleft movedividerright togglevimode toggleappearancetheme
togglefullscreen opencommandpalette none""".split())
NAMED_KEYS = {"home", "space", "delete", "esc", "insert", "pageup", "pagedown", "end",
              "up", "back", "down", "left", "right", "enter", "tab"}
MODS = {"none", "control", "option", "super", "shift", "alt"}
MODES = {"appcursor", "~appcursor", "appkeypad", "~appkeypad", "alt", "~alt", "vi", "~vi"}

with open(f"{rio}/config.toml", "rb") as f:
    config = tomllib.load(f)
ok("config.toml is valid TOML")

seen = {}
for k in config["bindings"]["keys"]:
    key, action = k["key"], k.get("action", "")
    if len(key) != 1 and key.lower() not in NAMED_KEYS:
        fail(f"unknown key {key!r}")
    mods = frozenset(m.strip() for m in k.get("with", "none").split("|"))
    if not mods <= MODS:
        fail(f"{key}: unknown modifier in {k.get('with')!r}")
    mode = k.get("mode", "")
    if mode and not set(mode.split("|")) <= MODES:
        fail(f"{key}: unknown mode {mode!r}")
    a = action.lower()
    if not (a in ACTIONS or re.fullmatch(r"selecttab\(\d+\)", a)):
        fail(f"{key}: unknown action {action!r}")
    sig = (key.lower(), mods, mode)
    if sig in seen:
        fail(f"{key} {sorted(mods)} bound twice: {seen[sig]} and {action}")
    seen[sig] = action
ok(f"{len(seen)} bindings: known keys, modifiers, modes and actions")

def bound(key, mods):
    return next((a for (k, m, _), a in seen.items() if k == key and m == frozenset(mods)), None)
want = [("1", {"alt"}, "SelectTab(0)"), ("9", {"alt"}, "SelectLastTab"),
        ("t", {"alt", "shift"}, "CreateTab"), ("w", {"alt", "shift"}, "CloseTab"),
        ("n", {"alt", "shift"}, "CreateWindow"), ("q", {"alt", "shift"}, "Quit"),
        ("c", {"alt", "shift"}, "Copy"), ("v", {"alt", "shift"}, "Paste"),
        ("insert", {"shift"}, "Paste"), ("p", {"control", "shift"}, "OpenCommandPalette"),
        ("i", {"alt", "shift"}, "SplitRight"), ("u", {"alt", "shift"}, "SplitDown"),
        ("b", {"alt", "shift"}, "SelectPrevSplit"), ("s", {"alt", "shift"}, "SelectNextSplit"),
        ("d", {"alt", "shift"}, "CloseSplitOrTab"), ("left", {"alt", "shift"}, "MoveDividerLeft")]
for key, mods, action in want:
    got = bound(key, mods)
    if got == action:
        ok(f"{'+'.join(sorted(mods))}+{key}: {action}")
    else:
        fail(f"{'+'.join(sorted(mods))}+{key}: want {action}, got {got}")

# Themes: the ones the config names exist, with wezterm's colors.
lua = open(lua_path).read()
names = dict(re.findall(r"^local (\w+)\s*=\s*'(#\w+)'", lua, re.M))

# Font size: wezterm's is in points at 96 dpi, Rio's in logical pixels.
wez_pt = float(re.search(r"^config\.font_size = ([\d.]+)", lua, re.M).group(1))
want_px = round(wez_pt * 96 / 72, 2)
got_px = config.get("fonts", {}).get("size")
if got_px == want_px:
    ok(f"font size {got_px} px = wezterm's {wez_pt} pt")
else:
    fail(f"font size: want {want_px} px (wezterm {wez_pt} pt), got {got_px}")
def lst(scheme, field):
    m = re.search(scheme + r"\." + field + r" = \{(.*?)\}", lua, re.S)
    return [names[n] for n in re.findall(r"^\s*(\w+),", m.group(1), re.M)]
def one(scheme, field):
    return names[re.search(scheme + r"\." + field + r" = (\w+)", lua).group(1)]
ANSI = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
themes = {config["theme"], config["adaptive-theme"]["dark"], config["adaptive-theme"]["light"]}
if themes == {"solarized-dark", "solarized-light"}:
    ok("theme and adaptive-theme name the two Solarized themes")
else:
    fail(f"themes named: {sorted(themes)}")
for scheme, name in (("dark_scheme", "solarized-dark"), ("light_scheme", "solarized-light")):
    with open(f"{rio}/themes/{name}.toml", "rb") as f:
        colors = {k: v.lower() for k, v in tomllib.load(f)["colors"].items()}
    bad = []
    for color, want_c in zip(ANSI, lst(scheme, "ansi")):
        if colors.get(color) != want_c: bad.append(f"{color} {colors.get(color)} != {want_c}")
    if scheme == "dark_scheme":
        for color, want_c in zip(ANSI, lst(scheme, "brights")):
            if colors.get("light-" + color) != want_c: bad.append(f"light-{color} != {want_c}")
    for rio_key, wez in (("background", "background"), ("foreground", "foreground"),
                         ("cursor", "cursor_bg"), ("selection-background", "selection_bg"),
                         ("selection-foreground", "selection_fg")):
        if colors.get(rio_key) != one(scheme, wez): bad.append(f"{rio_key} {colors.get(rio_key)} != {one(scheme, wez)}")
    if bad:
        fail(f"{name}: " + "; ".join(bad))
    else:
        ok(f"{name}: wezterm's colors")

sys.exit(1 if failed else 0)
PYEND
