#!/usr/bin/env bash
#
# The sway config (.config/sway) in headless sway: it validates (with the
# machine-local includes), the bindings run their commands (stubs on
# sway's PATH record the calls), $mod+m / $mod+Shift+m swap two windows,
# Ctrl+digit (the physical Alt key after ctrl:swap_lalt_lctl) switches
# workspaces, window rules float by Wayland app_id and X11 class, a
# theme.conf in ~/.config/sway.d changes the colors after a reload, and
# swaybar runs only with the include bootstrap.sh links where eww is
# missing. Also checks the fuzzel and sway-easyfocus configs.
#
# Usage: test/sway/test.sh   (needs docker; skips without it)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
readonly ROOT
readonly IMAGE="fedora:45"

if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
    echo "SKIP: docker not available"
    exit 0
fi

# Runs inside the container. Prints ok/FAIL lines; exits non-zero on a FAIL.
read -r -d '' INNER <<'EOF' || true
set -uo pipefail
dnf install -y -q --setopt=install_weak_deps=False sway wtype foot fuzzel xterm xorg-x11-server-Xwayland \
    libxkbcommon-utils python3 python3-pyyaml util-linux procps-ng >/dev/null 2>&1 ||
    { echo "FAIL: dnf install"; exit 1; }

FAILED=0
ok()   { echo "ok:   $*"; }
fail() { echo "FAIL: $*"; FAILED=1; }
expect() { if [ "$3" = "$2" ]; then ok "$1"; else fail "$1: want '$2', got '$3'"; fi; }

readonly H=/home/t RUN=/tmp/xdg-t CALLS=/tmp/calls
readonly CONFIG="$H/.config/sway/config"
useradd -m t
install -d -m 0700 -o t "$RUN"
mkdir -p "$H/.config/sway.d" "$H/.config/sway-bar.d" "$H/bin" "$H/stubs" "$H/.local/state/theme"
cp -r /src/sway /src/fuzzel /src/sway-easyfocus "$H/.config/"
: > "$CALLS"
chmod 0666 "$CALLS"

# Stubs record "name|arg|arg" in one write: some run at the same time.
# sway runs bindings with its own PATH ($H/stubs first) or from ~/bin.
stub() {
    cat > "$1" <<S
#!/bin/sh
line="$(basename "$1")"
for a in "\$@"; do line="\$line|\$a"; done
printf '%s\n' "\$line" >> $CALLS
S
    chmod +x "$1"
}
for c in fuzzel sway-easyfocus wdisplays amixer brightnessctl pkill swaynag systemctl; do
    stub "$H/stubs/$c"
done
for c in term clip-pick sway-autostart; do stub "$H/bin/$c"; done
printf '#!/bin/sh\nexec sleep 600\n' > "$H/bin/i3status-kb"
chmod +x "$H/bin/i3status-kb"
chown -R t "$H"

as_t() {
    runuser -u t -- env HOME="$H" XDG_RUNTIME_DIR="$RUN" PATH="$H/stubs:/usr/bin" \
        WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
        ${SWAYSOCK:+SWAYSOCK=$SWAYSOCK} ${WAYLAND_DISPLAY:+WAYLAND_DISPLAY=$WAYLAND_DISPLAY} \
        ${DISPLAY:+DISPLAY=$DISPLAY} "$@"
}
msg() { as_t swaymsg "$@"; }
key() { as_t wtype "$@"; sleep 0.4; }
called() { grep -qxF "$1" "$CALLS"; }
call_of() { grep -m 1 "^$1|" "$CALLS"; }
py() { python3 -c "$@"; }

# Light Solarized, as ~/bin/theme writes it.
light_theme() {
    local names="baseA3 baseA2 baseA1 baseA0 baseB0 baseB1 baseB2 baseB3 custom"
    local colors="#fdf6e3 #eee8d5 #93a1a1 #839496 #657b83 #586e75 #073642 #002b36 #bcd1d4"
    set -- $colors
    for n in $names; do echo "set \$$n $1"; shift; done > "$H/.config/sway.d/theme.conf"
}

# --- validation -----------------------------------------------------------
check() { as_t sway -C -c "$1" >/tmp/check.log 2>&1; }
check "$CONFIG" && ok "sway -C: config with empty sway.d" || fail "sway -C: $(grep -i error /tmp/check.log | head -3)"
light_theme
echo 'output * scale 1.5' > "$H/.config/sway.d/output.conf"
chown -R t "$H/.config"
check "$CONFIG" && ok "sway -C: with theme.conf and output.conf" || fail "sway -C with includes: $(grep -i error /tmp/check.log | head -3)"
rm "$H/.config/sway.d/theme.conf" "$H/.config/sway.d/output.conf"
# -C checks the input blocks too: sway 1.12 rejects a custom curve.
sed 's/accel_profile adaptive/accel_profile custom/' "$CONFIG" > /tmp/bad.config
chmod 0644 /tmp/bad.config
check /tmp/bad.config && fail "sway -C accepts accel_profile custom" || ok "sway -C checks the input blocks"
if grep -qE '^\s*xkb_options ctrl:swap_lalt_lctl$' "$CONFIG" && grep -qE '^\s*(tap|drag) disabled$' "$CONFIG"; then
    ok "keyboard and touchpad blocks"
else
    fail "input blocks: $(grep -nE 'xkb_|tap|drag' "$CONFIG")"
fi
# ~/bin/kb writes the session's layout into sway.d/kb.conf, so a reload
# keeps it: the keyboard block must come before the include.
kbd_line="$(grep -n -m 1 '^input type:keyboard' "$CONFIG" | cut -d: -f1)"
inc_line="$(grep -n -m 1 '^include ~/.config/sway.d/' "$CONFIG" | cut -d: -f1)"
if [ -n "$kbd_line" ] && [ -n "$inc_line" ] && [ "$kbd_line" -lt "$inc_line" ]; then
    ok "keyboard block before the sway.d include (kb.conf wins)"
else
    fail "keyboard block at line $kbd_line, sway.d include at line $inc_line"
fi

# The physical left Alt key (<LALT>) gives Control with the config's
# layout and options, so Alt+digit is the Ctrl+digit binding.
layout="$(sed -n 's/^\s*xkb_layout //p' "$CONFIG")"
options="$(sed -n 's/^\s*xkb_options //p' "$CONFIG")"
xkbcli compile-keymap --layout "$layout" --options "$options" > /tmp/keymap
if grep -qE 'key <LALT>.*Control_L' /tmp/keymap && grep -E 'modifier_map Control' /tmp/keymap | grep -q '<LALT>'; then
    ok "physical Alt gives Control ($layout, $options)"
else
    fail "LALT: $(grep -E 'key <LALT>|modifier_map Control' /tmp/keymap)"
fi

# --- running sway ---------------------------------------------------------
as_t sway -c "$CONFIG" >/tmp/sway.log 2>&1 &
for _ in $(seq 1 50); do ls "$RUN"/sway-ipc.*.sock >/dev/null 2>&1 && break; sleep 0.1; done
SWAYSOCK="$(ls "$RUN"/sway-ipc.*.sock)"
WAYLAND_DISPLAY="$(cd "$RUN" && ls wayland-? | head -n 1)"
export SWAYSOCK WAYLAND_DISPLAY
sleep 1
# sway is not readable in /proc (file capabilities): ask a child.
msg -q exec 'echo "$DISPLAY" > /tmp/display'
sleep 0.5
DISPLAY="$(cat /tmp/display)"
export DISPLAY

called "sway-autostart" && ok "exec ~/bin/sway-autostart" || fail "sway-autostart not run"
expect "no swaybar without the include" "[]" "$(msg -t get_bar_config | tr -d ' \n')"
pgrep -u t -a swaybg | grep -q -- '#073642' && ok "background baseA2 (dark)" || fail "swaybg: $(pgrep -u t -a swaybg)"

key -M logo -k Return -m logo
called "term" && ok "Mod+Return: ~/bin/term" || fail "Mod+Return"
key -M logo i -m logo
called "fuzzel" && ok "Mod+i: fuzzel" || fail "Mod+i"
key -M logo c -m logo
called "clip-pick" && ok "Mod+c: ~/bin/clip-pick" || fail "Mod+c"
key -k XF86Display
called "wdisplays" && ok "XF86Display: wdisplays" || fail "XF86Display"
key -k XF86AudioMute
called "amixer|set|Master|toggle" && ok "XF86AudioMute: amixer" || fail "XF86AudioMute"
key -k XF86MonBrightnessUp
if called "brightnessctl|set|+5%" && called "pkill|-USR1|-x|i3status"; then
    ok "XF86MonBrightnessUp: brightnessctl, then i3status redraws"
else
    fail "XF86MonBrightnessUp: $(tr '\n' ';' < "$CALLS")"
fi

# Window hints: the title colors of the config's variables.
key -M logo j -m logo
expect "Mod+j: sway-easyfocus, dark colors" \
    "sway-easyfocus|--label-background-color|#073642|--label-text-color|#93a1a1|--focused-background-color|#859900|--focused-text-color|#fdf6e3|focus" \
    "$(call_of sway-easyfocus)"

# Exit asks first; yes stops the session target, then sway.
key -M logo -M shift u -m shift -m logo
call_of swaynag | grep -qF '|systemctl --user stop sway-session.target; swaymsg exit' &&
    ok "Mod+Shift+u: swaynag, then stop the target and exit" || fail "Mod+Shift+u: $(call_of swaynag)"

# sway has no restart: Mod+Shift+a reloads.
as_t swaymsg -t subscribe -m '["binding"]' > /tmp/bindings 2>&1 &
sleep 0.3
key -M logo -M shift a -m shift -m logo
grep -q '"command": "reload"' /tmp/bindings && ok "Mod+Shift+a: reload" || fail "Mod+Shift+a: $(head -c 300 /tmp/bindings)"

# Two windows, left to right.
order() {
    msg -t get_tree | py '
import json, sys
def leaves(n):
    if n.get("pid") and n.get("name"): yield n["name"]
    for c in n.get("nodes", []): yield from leaves(c)
tree = json.load(sys.stdin)
ws = [w for o in tree["nodes"] for w in o["nodes"] if w.get("type") == "workspace" and w["name"] == "1"]
print(" ".join(t for w in ws for t in leaves(w) if t in ("A", "B")))'
}
marks() { msg -t get_marks | tr -d '[]" \n'; }
as_t foot -T A sleep 600 >/dev/null 2>&1 & sleep 1
as_t foot -T B sleep 600 >/dev/null 2>&1 & sleep 1
expect "start: A B" "A B" "$(order)"
msg -q '[title="^A$"] focus'
key -M logo m -m logo
expect "Mod+m marks the focused window" "swap" "$(marks)"
msg -q '[title="^B$"] focus'
key -M logo -M shift m -m shift -m logo
expect "Mod+Shift+m swaps the windows" "B A" "$(order)"
expect "the mark is gone after the swap" "" "$(marks)"
msg -q '[title="^A$"] focus'
key -M logo m -m logo
key -M logo m -m logo
expect "Mod+m again removes the mark" "" "$(marks)"

# Alt+digit as in X (xremap): Ctrl+digit after the swap of the modifiers.
focused_ws() { msg -t get_workspaces | py 'import json,sys; print(*[w["name"] for w in json.load(sys.stdin) if w["focused"]])'; }
msg -q workspace number 3
key -M ctrl 1 -m ctrl
expect "Ctrl+1: workspace 1" "1" "$(focused_ws)"
msg -q '[title="^A$"] focus'
key -M ctrl -M shift 2 -m shift -m ctrl
ws_of() { msg -t get_tree | py "
import json,sys
def find(n, ws):
    if n.get('type') == 'workspace': ws = n['name']
    if n.get('name') == '$1' and n.get('pid'): print(ws)
    for c in n.get('nodes', []) + n.get('floating_nodes', []): find(c, ws)
find(json.load(sys.stdin), None)"; }
expect "Ctrl+Shift+2: window to workspace 2" "2" "$(ws_of A)"

# Window rules: Wayland app_id, and class or instance on Xwayland.
floats() { msg -t get_tree | py "
import json,sys
def find(n):
    if n.get('name') == '$1' and n.get('pid'): print(n['type'])
    for c in n.get('nodes', []) + n.get('floating_nodes', []): find(c)
find(json.load(sys.stdin))"; }
for id in nmrs blueman-manager blueman-services org.pulseaudio.pavucontrol wdisplays; do
    as_t foot --app-id "$id" -T "W-$id" sleep 600 >/dev/null 2>&1 &
done
as_t xterm -class nmrs -T X-nmrs -e sleep 600 >/dev/null 2>&1 &
as_t xterm -name blueman-manager -T X-blueman -e sleep 600 >/dev/null 2>&1 &
as_t xterm -name pavucontrol -T X-pavucontrol -e sleep 600 >/dev/null 2>&1 &
as_t foot --app-id other -T W-other sleep 600 >/dev/null 2>&1 &
sleep 4
for t in W-nmrs W-blueman-manager W-blueman-services W-org.pulseaudio.pavucontrol W-wdisplays X-nmrs X-blueman X-pavucontrol; do
    expect "$t floats" "floating_con" "$(floats "$t")"
done
expect "other windows tile" "con" "$(floats W-other)"

# Full-screen windows (video) inhibit idle: swayidle neither locks nor
# suspends.
idle() { msg -t get_tree | py "
import json,sys
def find(n):
    if n.get('name') == 'B' and n.get('pid'): print(n['idle_inhibitors']['user'])
    for c in n.get('nodes', []) + n.get('floating_nodes', []): find(c)
find(json.load(sys.stdin))"; }
expect "inhibit idle when full screen" "fullscreen" "$(idle)"

# bin/theme writes theme.conf, which sway reads at login and on reload;
# bootstrap links the swaybar block where eww is missing.
light_theme
ln -s "$H/.config/sway/swaybar.conf" "$H/.config/sway-bar.d/swaybar.conf"
chown -h -R t "$H/.config"
msg -q reload
sleep 1
bar_id="$(msg -t get_bar_config | py 'import json,sys; print(json.load(sys.stdin)[0])')"
bar="$(msg -t get_bar_config "$bar_id")"
field() { py "import json,sys; d=json.loads(sys.argv[1]); print($1)" "$bar"; }
expect "swaybar runs i3status-kb" "~/bin/i3status-kb" "$(field 'd["status_command"]')"
expect "swaybar colors from the variables" "#859900ff" "$(field 'd["colors"]["focused_workspace_bg"]')"
expect "theme.conf reaches the bar" "#fdf6e3ff" "$(field 'd["colors"]["background"]')"
pgrep -u t -a swaybg | grep -q -- '#eee8d5' && ok "theme.conf reaches the background" || fail "swaybg: $(pgrep -u t -a swaybg)"
sed -i '/^sway-easyfocus/d' "$CALLS"
key -M logo j -m logo
expect "theme.conf reaches Mod+j" \
    "sway-easyfocus|--label-background-color|#eee8d5|--label-text-color|#586e75|--focused-background-color|#859900|--focused-text-color|#002b36|focus" \
    "$(call_of sway-easyfocus)"

# fuzzel runs Terminal=true programs in ~/bin/term. Without exit on focus
# loss: wtype's virtual keyboard takes the keyboard focus.
mkdir -p "$H/.local/share/applications"
printf '[Desktop Entry]\nType=Application\nName=Termtest\nExec=termtest-prog --flag "a b"\nTerminal=true\n' \
    > "$H/.local/share/applications/termtest.desktop"
chown -R t "$H/.local"
as_t /usr/bin/fuzzel --no-exit-on-keyboard-focus-loss >/tmp/fuzzel-run.log 2>&1 &
sleep 1
key -s 500 termtest
key -k Return
sleep 1
expect "fuzzel: terminal programs in ~/bin/term" "term|-e|termtest-prog|--flag|a b" "$(grep '^term|' "$CALLS")"

# The X session's Ctrl+Alt+Backspace (terminate:ctrl_alt_bksp).
pid="$(pgrep -u t -x sway)"
key -M ctrl -M alt -k BackSpace -m alt -m ctrl
for _ in $(seq 1 30); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
kill -0 "$pid" 2>/dev/null && fail "Ctrl+Alt+BackSpace: sway still runs" || ok "Ctrl+Alt+BackSpace exits sway"
called "systemctl|--user|stop|sway-session.target" && ok "Ctrl+Alt+BackSpace stops the session target" || fail "no stop of the target"

grep -iE '\[ERROR\]' /tmp/sway.log | grep -viE 'swaybar|xwayland|status|drm|libinput|seat' | head -3 | sed 's/^/sway: /'

# --- fuzzel ---------------------------------------------------------------
# The colors come from a file bin/theme writes (include=).
printf '[colors]\nbackground=fdf6e3ff\ntext=586e75ff\n' > "$H/.local/state/theme/fuzzel.ini"
chown -R t "$H/.local"
as_t fuzzel --check-config >/tmp/fuzzel.log 2>&1 && ok "fuzzel --check-config" || fail "fuzzel: $(cat /tmp/fuzzel.log)"
grep -qx 'include=~/.local/state/theme/fuzzel.ini' "$H/.config/fuzzel/fuzzel.ini" &&
    ok "fuzzel includes the theme colors" || fail "no theme include in fuzzel.ini"

# --- sway-easyfocus -------------------------------------------------------
# sway-easyfocus 1.0.1 reads the file into its CLI arguments; with an
# unknown key or without show_confirmation (a plain bool there) it
# ignores the whole file.
py '
import sys, yaml
known = {"chars", "window_background_color", "window_background_opacity", "label_background_color",
         "label_background_opacity", "label_text_color", "focused_background_color",
         "focused_background_opacity", "focused_text_color", "font_family", "font_weight", "font_size",
         "label_padding_x", "label_padding_y", "label_margin_x", "label_margin_y", "show_confirmation"}
d = yaml.safe_load(open("/home/t/.config/sway-easyfocus/config.yaml"))
bad = set(d) - known
if bad: print("FAIL: sway-easyfocus: unknown keys", sorted(bad)); sys.exit(1)
if not isinstance(d.get("show_confirmation"), bool): print("FAIL: sway-easyfocus: no show_confirmation"); sys.exit(1)
if d.get("chars") != "nrsgbeitco": print("FAIL: sway-easyfocus chars", d.get("chars")); sys.exit(1)
print("ok:   sway-easyfocus config.yaml")' || FAILED=1

exit "$FAILED"
EOF

TMP="$(mktemp -d)"
container="$(docker create --cap-add SYS_NICE "$IMAGE" bash -c "$INNER")"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT
mkdir -p "$TMP/src"
for dir in sway fuzzel sway-easyfocus; do
    if [[ ! -d "$ROOT/.config/$dir" ]]; then
        echo "FAIL: .config/$dir is missing"
        exit 1
    fi
    cp -r "$ROOT/.config/$dir" "$TMP/src/"
done
# docker cp, not a bind mount: SELinux hosts would deny the container.
docker cp "$TMP/src" "$container:/src"
docker start -a "$container"
