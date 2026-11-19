#!/usr/bin/env bash
#
# Alacritty's config: .config/alacritty/alacritty.toml (shared with macOS),
# alacritty/linux.toml (the Linux keys) and the themes.
#   1. Static (python3 tomllib): valid TOML, actions Alacritty 0.17
#      accepts (alacritty(5)), no binding twice, wezterm's keys and copy
#      mode keys present, themes with .wezterm.lua's colors.
#   2. bin/alacritty-theme with a stub gsettings: the link follows the
#      desktop and is replaced, never removed.
#   3. Alacritty 0.17 (Fedora 45's package) under Xvfb with the files
#      linked as bootstrap links them: no config warnings or errors, the
#      runtime config (alacritty msg get-config) has the imports, and a
#      theme change reloads it. Skip with ALACRITTY_TEST_NO_DOCKER=1.
#
# Usage: test/alacritty/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly HERE ROOT

failed=0
ok()   { printf 'ok:   %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*"; failed=1; }

# 1. Static checks.
if ! python3 -I - "$ROOT" <<'PYEND'
import re, sys, tomllib

root = sys.argv[1]
failed = False
def ok(m): print("ok:   " + m)
def fail(m):
    global failed
    failed = True
    print("FAIL: " + m)

def load(path):
    with open(f"{root}/{path}", "rb") as f:
        return tomllib.load(f)

base = load(".config/alacritty/alacritty.toml")
linux = load("alacritty/linux.toml")
themes = {m: load(f".config/alacritty/themes/solarized-{m}.toml") for m in ("dark", "light")}
ok("TOML parses")

want_imports = ["themes/solarized-dark.toml", "~/.local/state/alacritty/theme.toml", "linux.toml"]
if base["general"]["import"] == want_imports:
    ok("imports: dark theme, theme link, linux.toml")
else:
    fail(f"imports: {base['general']['import']}")
if "colors" in base and any(k in base["colors"] for k in ("primary", "normal", "bright", "cursor")):
    fail("alacritty.toml sets theme colors: they would win over the imported theme")
else:
    ok("no theme colors in alacritty.toml (the imports decide)")

# alacritty(5), Alacritty 0.17: the actions for Linux.
ACTIONS = set("""ReceiveChar None Paste Copy IncreaseFontSize DecreaseFontSize ResetFontSize
ScrollPageUp ScrollPageDown ScrollHalfPageUp ScrollHalfPageDown ScrollLineUp ScrollLineDown
ScrollToTop ScrollToBottom ClearHistory Hide Minimize Quit ClearLogNotice SpawnNewInstance
CreateNewWindow ToggleFullscreen ToggleMaximized ClearSelection ToggleViMode SearchForward
SearchBackward Up Down Left Right First Last FirstOccupied High Middle Low SemanticLeft
SemanticRight SemanticLeftEnd SemanticRightEnd WordLeft WordRight WordLeftEnd WordRightEnd
Bracket ParagraphUp ParagraphDown ToggleNormalSelection ToggleLineSelection
ToggleBlockSelection ToggleSemanticSelection SearchNext SearchPrevious SearchStart SearchEnd
Open CenterAroundViCursor InlineSearchForward InlineSearchBackward InlineSearchForwardShort
InlineSearchBackwardShort InlineSearchNext InlineSearchPrevious SemanticSearchForward
SemanticSearchBackward SearchFocusNext SearchFocusPrevious SearchConfirm SearchCancel
SearchClear SearchDeleteWord SearchHistoryPrevious SearchHistoryNext CopySelection
PasteSelection""".split())
MODS = {"Command", "Control", "Option", "Super", "Shift", "Alt"}
MODES = {"AppCursor", "AppKeypad", "Search", "Alt", "Vi"}

bindings = base["keyboard"]["bindings"] + linux["keyboard"]["bindings"]
seen, bad = set(), []
def norm_mods(m): return frozenset(x.strip() for x in m.split("|")) if m else frozenset()
def norm_mode(m): return frozenset(x.strip() for x in m.split("|")) if m else frozenset()
for b in bindings:
    if "action" in b and b["action"] not in ACTIONS: bad.append(f"action {b['action']}")
    if not norm_mods(b.get("mods")) <= MODS: bad.append(f"mods {b.get('mods')}")
    if not {x.lstrip("~") for x in norm_mode(b.get("mode"))} <= MODES: bad.append(f"mode {b.get('mode')}")
    if not ({"action", "chars", "command"} & b.keys()): bad.append(f"no action: {b}")
    t = (b["key"].lower(), norm_mods(b.get("mods")), norm_mode(b.get("mode")), b.get("action"), b.get("chars"))
    if t in seen: bad.append(f"twice: {b}")
    seen.add(t)
if bad:
    fail("bindings: " + "; ".join(bad))
else:
    ok(f"{len(bindings)} bindings: actions, modifiers and modes known, none twice")

def actions(key, mods=None, mode=None):
    return [b.get("action") for b in bindings
            if b["key"].lower() == key.lower() and norm_mods(b.get("mods")) == norm_mods(mods)
            and norm_mode(b.get("mode")) == norm_mode(mode)]
VI = "Vi|~Search"
expected = [
    ("N", "Alt|Shift", None, ["CreateNewWindow"]),
    ("Q", "Alt|Shift", None, ["Quit"]),
    ("C", "Alt|Shift", None, ["Copy"]),
    ("V", "Alt|Shift", "~Vi", ["Paste"]),
    ("Insert", "Shift", None, ["Paste"]),
    ("Space", "Alt|Shift", "~Search", ["ToggleViMode"]),
    ("B", None, VI, ["Left"]), ("N", None, VI, ["Down"]),
    ("R", None, VI, ["Up"]), ("S", None, VI, ["Right"]),
    ("B", "Shift", VI, ["SemanticLeft"]), ("S", "Shift", VI, ["SemanticRight"]),
    ("N", "Shift", VI, ["ScrollLineDown"]), ("R", "Shift", VI, ["ScrollLineUp"]),
    ("(", None, VI, ["ScrollPageDown"]), (")", None, VI, ["ScrollPageUp"]),
    ("Y", "Shift", VI, ["Copy", "ClearSelection", "ScrollToBottom", "ToggleViMode"]),
    ("Q", None, VI, ["ScrollToBottom", "ToggleViMode"]),
    ("G", "Control", VI, ["ScrollToBottom", "ToggleViMode"]),
    ("/", None, VI, ["SearchBackward"]), ("?", "Shift", VI, ["SearchNext"]),
    ("-", None, VI, ["SearchPrevious"]),
    # Symbols on Bone 2's Mod3 layer (Level3) come without Shift, which
    # Alacritty's defaults require; on us and de they need Shift.
    ("?", None, VI, ["SearchNext"]), ("/", "Shift", VI, ["SearchBackward"]),
    ("(", "Shift", VI, ["ScrollPageDown"]), (")", "Shift", VI, ["ScrollPageUp"]),
    ("$", None, VI, ["Last"]), ("^", None, VI, ["FirstOccupied"]),
    ("%", None, VI, ["Bracket"]),
    ("{", None, VI, ["ParagraphUp"]), ("}", None, VI, ["ParagraphDown"]),
    ("*", None, VI, ["SemanticSearchForward"]), ("#", None, VI, ["SemanticSearchBackward"]),
]
for key, mods, mode, want in expected:
    got = actions(key, mods, mode)
    name = f"{mods + '+' if mods else ''}{key}{' (' + mode + ')' if mode else ''}"
    if got == want:
        ok(f"{name}: {', '.join(want)}")
    else:
        fail(f"{name}: want {want}, got {got}")
for key, mods in (("C", "Control|Shift"), ("V", "Control|Shift"), ("F", "Control|Shift"),
                  ("B", "Control|Shift"), ("Space", "Control|Shift"), ("0", "Control"),
                  ("=", "Control"), ("-", "Control")):
    if actions(key, mods) == ["ReceiveChar"]:
        ok(f"default {mods}+{key} given back to programs")
    else:
        fail(f"default {mods}+{key} still bound: {actions(key, mods)}")

hints = linux["hints"]["enabled"]
if [h.get("binding", {}).get("key") for h in hints] == ["O", "T"] and hints[1].get("action") == "Copy":
    ok("hints: open (Alt+Shift+o), copy (Alt+Shift+t)")
else:
    fail(f"hints: {hints}")
if linux["window"]["decorations"] == "None":
    ok("no window decorations")
else:
    fail("decorations")
if linux.get("scrolling", {}).get("multiplier") == 5:
    ok("scroll multiplier 5 (sway's scroll_factor)")
else:
    fail(f"scrolling: {linux.get('scrolling')}")

# Themes: .wezterm.lua's colors.
lua = open(f"{root}/.wezterm.lua").read()
names = dict(re.findall(r"^local (\w+)\s*=\s*'(#\w+)'", lua, re.M))
def lst(scheme, field):
    m = re.search(scheme + r"\." + field + r" = \{(.*?)\}", lua, re.S)
    return [names[n] for n in re.findall(r"^\s*(\w+),", m.group(1), re.M)]
def one(scheme, field):
    return names[re.search(scheme + r"\." + field + r" = (\w+)", lua).group(1)]
ANSI = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
for mode, scheme in (("dark", "dark_scheme"), ("light", "light_scheme")):
    c, bad = themes[mode]["colors"], []
    for color, want in zip(ANSI, lst(scheme, "ansi")):
        if c["normal"][color] != want: bad.append(f"normal.{color}")
    if scheme == "dark_scheme":
        for color, want in zip(ANSI, lst(scheme, "brights")):
            if c["bright"][color] != want: bad.append(f"bright.{color}")
    for got, field in ((c["primary"]["background"], "background"), (c["primary"]["foreground"], "foreground"),
                       (c["cursor"]["cursor"], "cursor_bg"), (c["cursor"]["text"], "cursor_fg"),
                       (c["selection"]["background"], "selection_bg"), (c["selection"]["text"], "selection_fg")):
        if got != one(scheme, field): bad.append(f"{field} {got} != {one(scheme, field)}")
    if set(c["bright"]) != set(ANSI): bad.append("bright colors incomplete")
    if bad:
        fail(f"solarized-{mode}: " + "; ".join(bad))
    else:
        ok(f"solarized-{mode}: wezterm's colors")

wez_pt = float(re.search(r"^config\.font_size = ([\d.]+)", lua, re.M).group(1))
if base["font"]["size"] == wez_pt:
    ok(f"font size {wez_pt} pt, as wezterm (both in points)")
else:
    fail(f"font size {base['font']['size']} != wezterm {wez_pt}")

sys.exit(1 if failed else 0)
PYEND
then
    failed=1
fi

# 2. bin/alacritty-theme with a stub gsettings.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/stub"
cat >"$TMP/stub/gsettings" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    get) cat "$STUB_SCHEME" ;;
    monitor) while read -r line; do echo "color-scheme: $line"; done <"$STUB_FIFO" ;;
esac
EOF
chmod +x "$TMP/stub/gsettings"
export STUB_SCHEME="$TMP/scheme" STUB_FIFO="$TMP/fifo"
export ALACRITTY_THEMES="$ROOT/.config/alacritty/themes" ALACRITTY_THEME_LINK="$TMP/state/theme.toml"
target() { readlink "$ALACRITTY_THEME_LINK" 2>/dev/null || echo MISSING; }
expect_target() {
    local name="$1" want="$ALACRITTY_THEMES/solarized-$2.toml" got
    for _ in $(seq 1 50); do
        got="$(target)"
        [[ "$got" == "$want" ]] && break
        sleep 0.1
    done
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: link -> $got"; fi
}

echo "'prefer-light'" >"$STUB_SCHEME"
PATH="$TMP/stub:$PATH" "$ROOT/bin/alacritty-theme" apply
expect_target "apply: light desktop" light
echo "'default'" >"$STUB_SCHEME"
PATH="$TMP/stub:$PATH" "$ROOT/bin/alacritty-theme" apply
expect_target "apply: no preference is dark" dark
PATH="/usr/bin:/bin" ALACRITTY_THEME_LINK="$TMP/nogs/theme.toml" "$ROOT/bin/alacritty-theme" apply
if [[ "$(readlink "$TMP/nogs/theme.toml")" == "$ALACRITTY_THEMES/solarized-dark.toml" ]]; then
    ok "apply: without gsettings dark"
else
    fail "apply without gsettings: $(readlink "$TMP/nogs/theme.toml" || echo MISSING)"
fi

mkfifo "$STUB_FIFO"
echo "'prefer-dark'" >"$STUB_SCHEME"
PATH="$TMP/stub:$PATH" "$ROOT/bin/alacritty-theme" watch &
watch_pid=$!
# The link changes only by a rename: a watcher of the directory sees no
# moment without it. Started before fd 3 opens, so it does not hold the
# FIFO's write end (the stub's monitor ends at EOF).
( while kill -0 "$watch_pid" 2>/dev/null; do
      [[ -L "$ALACRITTY_THEME_LINK" ]] || echo gone >>"$TMP/gaps"
  done ) &
gap_pid=$!
exec 3>"$STUB_FIFO"
echo "'prefer-light'" >"$STUB_SCHEME"; echo "'prefer-light'" >&3
expect_target "watch: switches to light" light
echo "'prefer-dark'" >"$STUB_SCHEME"; echo "'prefer-dark'" >&3
expect_target "watch: back to dark" dark
exec 3>&-
wait "$watch_pid" || true
kill "$gap_pid" 2>/dev/null || true
wait "$gap_pid" 2>/dev/null || true
if [[ -s "$TMP/gaps" ]]; then fail "watch: link was missing $(wc -l <"$TMP/gaps") times"; else ok "watch: link never missing"; fi
leftover=("$TMP"/state/*.tmp.*)
if [[ -e "${leftover[0]}" || -L "${leftover[0]}" ]]; then fail "watch: temporary link left: ${leftover[*]}"; else ok "watch: no temporary links left"; fi

# 3. Alacritty under Xvfb.
if [[ "${ALACRITTY_TEST_NO_DOCKER:-0}" == 1 ]]; then
    echo "skip: Alacritty run (ALACRITTY_TEST_NO_DOCKER=1)"
    exit "$failed"
fi
cid="$(docker create fedora:45 sleep infinity)"
trap 'rm -rf "$TMP"; docker rm -f "$cid" >/dev/null 2>&1 || true' EXIT
docker start "$cid" >/dev/null
docker exec "$cid" mkdir -p /src
docker cp "$ROOT/.config" "$cid:/src/.config"
docker cp "$ROOT/alacritty" "$cid:/src/alacritty"
docker cp "$ROOT/bin" "$cid:/src/bin"
docker cp "$HERE/in-container.sh" "$cid:/in-container.sh"
if docker exec "$cid" bash /in-container.sh; then :; else failed=1; fi

exit "$failed"
