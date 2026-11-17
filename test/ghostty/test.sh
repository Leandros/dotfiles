#!/usr/bin/env bash
#
# Ghostty's config (.config/ghostty, ghostty/linux.conf): installs ghostty
# from bootstrap.sh's copr in a fedora:45 container, links the files as
# bootstrap does and checks
#   - the config is valid on Linux (with linux.conf) and as on macOS
#     (without it);
#   - on Linux the macOS opt+ keys are gone and wezterm's keys are bound
#     (tabs, clipboard, the Alt+e leader, the copy key table);
#   - the themes have wezterm's Solarized colors (.wezterm.lua).
#
# Usage: test/ghostty/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
readonly IMAGE="fedora:45"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }
has()  { if grep -qxF -- "$2" <<< "$3"; then ok "$1"; else fail "$1: no '$2'"; fi; }

COPR="$(sed -n 's/^readonly GHOSTTY_COPR="\(.*\)"$/\1/p' "$ROOT/bootstrap.sh")"
readonly COPR

read -r -d '' INNER <<'EOF' || true
set -euo pipefail
dnf install -y -q dnf-plugins-core >/dev/null 2>&1
dnf copr enable -y "$COPR" >/dev/null 2>&1
dnf install -y -q ghostty >/dev/null 2>&1
dir="$HOME/.config/ghostty"
mkdir -p "$dir"
ln -s /src/.config/ghostty/config "$dir/config"
ln -s /src/.config/ghostty/themes "$dir/themes"
echo "== macos"
ghostty +validate-config 2>&1 && echo "valid"
ghostty +list-keybinds 2>&1
ln -s /src/ghostty/linux.conf "$dir/linux.conf"
echo "== linux"
ghostty +validate-config 2>&1 && echo "valid"
ghostty +list-keybinds 2>&1
EOF

section() { sed -n "/^== $1\$/,/^== /p" <<< "$OUT" | sed '1d;/^== /d'; }

main() {
    local name
    name="dotfiles-ghostty-$$"
    docker create --name "$name" -e COPR="$COPR" "$IMAGE" bash -c "$INNER" > /dev/null
    trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT
    # The files at the repo's paths, copied (SELinux denies bind mounts).
    local stage
    stage="$(mktemp -d)"
    mkdir -p "$stage/src/.config" "$stage/src/ghostty"
    cp -r "$ROOT/.config/ghostty" "$stage/src/.config/"
    cp "$ROOT/ghostty/linux.conf" "$stage/src/ghostty/"
    docker cp "$stage/src" "$name:/src"
    rm -rf "$stage"
    OUT="$(docker start -a "$name" 2>&1 || true)"

    local mac linux
    mac="$(section macos)"
    linux="$(section linux)"
    has "macOS: config valid" "valid" "$mac"
    # ghostty lists opt as alt.
    has "macOS: opt keys kept" "keybind = alt+e=text:€" "$mac"
    has "Linux: config valid" "valid" "$linux"
    if grep -q '=text:' <<< "$linux"; then
        fail "Linux: macOS opt+ keys still bound"
    else
        ok "Linux: no macOS opt+ keys"
    fi
    local want
    for want in \
        "keybind = alt+1=goto_tab:1" \
        "keybind = alt+9=last_tab" \
        "keybind = alt+shift+t=new_tab" \
        "keybind = alt+shift+w=close_tab:this" \
        "keybind = alt+shift+c=copy_to_clipboard:mixed" \
        "keybind = alt+shift+v=paste_from_clipboard" \
        "keybind = ctrl+shift+p=toggle_command_palette" \
        "keybind = alt+e>i=new_split:right" \
        "keybind = alt+e>t=new_split:down" \
        "keybind = alt+e>b=goto_split:left" \
        "keybind = alt+e>shift+r=resize_split:up,100" \
        "keybind = alt+e>z=toggle_split_zoom" \
        "keybind = alt+e>[=activate_key_table:copy" \
        "keybind = alt+e>u=activate_key_table:copy" \
        "keybind = copy/catch_all=ignore" \
        "keybind = copy//=start_search" \
        "keybind = copy/?=navigate_search:previous"; do
        has "Linux: ${want#keybind = }" "$want" "$linux"
    done
    local count
    count="$(grep -c '^keybind = alt+e>' <<< "$linux" || true)"
    if [[ "$count" == 25 ]]; then ok "Linux: 25 leader bindings"; else fail "Linux: $count leader bindings, want 25"; fi

    check_themes
    exit "$FAILED"
}

# wezterm's schemes: dark ansi and brights (the same), light ansi, and the
# foreground, background, cursor and selection colors of both.
check_themes() {
    local got want
    got="$(python3 -I - "$ROOT/.wezterm.lua" "$ROOT/.config/ghostty/themes" <<'PYEND'
import re, sys
lua = open(sys.argv[1]).read()
names = dict(re.findall(r"^local (\w+)\s*=\s*'(#\w+)'", lua, re.M))
def lst(scheme, field):
    m = re.search(scheme + r"\." + field + r" = \{(.*?)\}", lua, re.S)
    return [names[n] for n in re.findall(r"^\s*(\w+),", m.group(1), re.M)]
def one(scheme, field):
    return names[re.search(scheme + r"\." + field + r" = (\w+)", lua).group(1)]
def theme(name):
    t = {}
    for line in open(sys.argv[2] + "/" + name):
        m = re.match(r"palette = (\d+)=(#\w+)", line)
        if m: t[int(m.group(1))] = m.group(2).lower()
        m = re.match(r"([a-z-]+) = (\w+)$", line.strip())
        if m: t[m.group(1)] = "#" + m.group(2).lower()
    return t
bad = []
for scheme, name in (("dark_scheme", "solarized-dark"), ("light_scheme", "solarized-light")):
    t = theme(name)
    for i, c in enumerate(lst(scheme, "ansi")):
        if t.get(i) != c: bad.append(f"{name} {i}: {t.get(i)} != {c}")
    if scheme == "dark_scheme":
        for i, c in enumerate(lst(scheme, "brights")):
            if t.get(i + 8) != c: bad.append(f"{name} {i + 8}: {t.get(i + 8)} != {c}")
    for g, w in (("foreground", "foreground"), ("background", "background"),
                 ("cursor-color", "cursor_bg"), ("cursor-text", "cursor_fg"),
                 ("selection-background", "selection_bg"), ("selection-foreground", "selection_fg")):
        if t.get(g) != one(scheme, w): bad.append(f"{name} {g}: {t.get(g)} != {one(scheme, w)}")
print("\n".join(bad))
PYEND
)"
    want=""
    if [[ "$got" == "$want" ]]; then
        ok "themes: wezterm's Solarized colors"
    else
        fail "themes differ from .wezterm.lua: $got"
    fi
}

main "$@"
