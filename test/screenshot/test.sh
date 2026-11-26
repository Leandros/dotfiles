#!/usr/bin/env bash
#
# bin/screenshot with stubs: in sway grim (and slurp for an area), in X
# maim (-s for an area); the PNG goes to ~/Pictures/Screenshots and to the
# clipboard (wl-copy or xclip), with a notification. A cancelled area
# selection saves nothing and is no error.
# --video starts a recording (sway: wf-recorder, the focused output or a
# slurp area; X: ffmpeg x11grab, the screen or a slop area) into
# ~/Videos/Screencasts and the same command stops it (SIGTERM, then a
# notification). H.264 on the boot GPU (VAAPI) where a test encode works,
# else libx264, else libopenh264; --audio adds the default output's sound.
# A recorder that dies at once leaves no state and a notification.
#
# Usage: test/screenshot/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT="$HERE/../../bin/screenshot"
TMP="$(mktemp -d)"
readonly TMP
trap 'rm -rf "$TMP"' EXIT
readonly STUBS="$TMP/stubs" CALLS="$TMP/calls" FAKE_HOME="$TMP/home"
FAILED=0

fail() { printf 'FAIL: %s\n' "$*"; FAILED=1; }
ok()   { printf 'ok:   %s\n' "$*"; }

expect() {
    local name="$1" want="$2" got="$3"
    if [[ "$got" == "$want" ]]; then ok "$name"; else fail "$name: want '$want', got '$got'"; fi
}

write_stubs() {
    mkdir -p "$STUBS" "$FAKE_HOME"
    # grim and maim write their last argument; slurp prints a geometry, or
    # fails like a cancelled selection (TMP/cancel); maim -s fails then too.
    cat > "$STUBS/grim" <<EOF
#!/bin/sh
echo "grim \$*" >> "$CALLS"
for f; do :; done; echo png > "\$f"
EOF
    cat > "$STUBS/slurp" <<EOF
#!/bin/sh
echo "slurp \$*" >> "$CALLS"
[ -e "$TMP/cancel" ] && exit 1
echo "10,20 300x200"
EOF
    cat > "$STUBS/maim" <<EOF
#!/bin/sh
echo "maim \$*" >> "$CALLS"
[ -e "$TMP/cancel" ] && [ "\$1" = -s ] && exit 1
for f; do :; done; echo png > "\$f"
EOF
    # The clipboard tools record what they read.
    # shellcheck disable=SC2016 # $* and $(cat) belong to the stubs.
    printf '#!/bin/sh\necho "wl-copy $* $(cat)" >> "%s"\n' "$CALLS" > "$STUBS/wl-copy"
    # shellcheck disable=SC2016 # as above.
    printf '#!/bin/sh\necho "xclip $* $(cat)" >> "%s"\n' "$CALLS" > "$STUBS/xclip"
    printf '#!/bin/sh\necho "notify-send $*" >> "%s"\n' "$CALLS" > "$STUBS/notify-send"
    # Recorders: a test encode (lavfi) works with TMP/vaapi; -encoders lists
    # libx264 with TMP/x264; a recording runs until SIGTERM (fails at once
    # with TMP/die).
    local rec
    for rec in wf-recorder ffmpeg; do
        cat > "$STUBS/$rec" <<EOF
#!/bin/sh
case "\$*" in
    *-encoders*) [ -e "$TMP/x264" ] && echo " V....D libx264  libx264 H.264"; exit 0 ;;
    *lavfi*) [ -e "$TMP/vaapi" ]; exit ;;
esac
echo "$rec \$*" >> "$CALLS"
[ -e "$TMP/die" ] && { echo "$rec: cannot open device" >&2; exit 1; }
trap 'echo "$rec stopped" >> "$CALLS"; exit 0' TERM
while :; do sleep 0.05; done
EOF
    done
    cat > "$STUBS/slop" <<EOF
#!/bin/sh
echo "slop \$*" >> "$CALLS"
[ -e "$TMP/cancel" ] && exit 1
echo "11 21 301 201"
EOF
    printf '#!/bin/sh\necho alsa_output.pci\n' > "$STUBS/pactl"
    cat > "$STUBS/swaymsg" <<'EOF'
#!/bin/sh
echo '[{"name":"DP-2","focused":false},{"name":"eDP-1","focused":true}]'
EOF
    # The boot GPU's render node.
    mkdir -p "$TMP/sys/class/drm/renderD128/device" "$TMP/sys/class/drm/renderD129/device"
    echo 1 > "$TMP/sys/class/drm/renderD128/device/boot_vga"
    echo 0 > "$TMP/sys/class/drm/renderD129/device/boot_vga"
    printf '#!/bin/sh\necho 2026-11-12_10-00-00\n' > "$STUBS/date"
    chmod +x "$STUBS"/*
}

# Runs the script in sway (SWAYSOCK) or X; prints its exit status.
run() {
    local session="$1"; shift
    : > "$CALLS"
    rm -rf "$FAKE_HOME/Pictures"
    mkdir -p "$TMP/run"
    local rc=0 env=(HOME="$FAKE_HOME" PATH="$STUBS:/usr/bin:/bin" XDG_RUNTIME_DIR="$TMP/run" SCREENSHOT_SYSFS="$TMP/sys")
    if [[ "$session" == sway ]]; then env+=(SWAYSOCK=/run/sway.sock WAYLAND_DISPLAY=wayland-1); else env+=(DISPLAY=:0); fi
    env -i "${env[@]}" "$SCRIPT" "$@" >/dev/null 2>&1 || rc=$?
    echo "$rc"
}

# Passes when the line has every fragment.
has() {
    local name="$1" line="$2"
    shift 2
    local f
    for f; do
        if [[ "$line" != *"$f"* ]]; then fail "$name: no '$f' in '$line'"; return; fi
    done
    ok "$name"
}

test_video() {
    local video="$FAKE_HOME/Videos/Screencasts/2026-11-12_10-00-00.mp4" state="$TMP/run/screenshot-video"

    touch "$TMP/vaapi"
    expect "sway video: starts, exits 0" 0 "$(run sway --video)"
    has "sway video: wf-recorder, the focused output, VAAPI on the boot GPU" "$(grep '^wf-recorder' "$CALLS")" \
        "-f $video" "-o eDP-1" "-c h264_vaapi" "-d /dev/dri/renderD128"
    expect "sway video: no audio by default" "" "$(grep -- '--audio' "$CALLS" || true)"
    expect "sway video: state kept" 1 "$(test -s "$state" && echo 1)"
    expect "sway video: notification" 1 "$(grep -c '^notify-send.*Recording' "$CALLS")"
    expect "sway video: the same command stops it" 0 "$(run sway --video)"
    expect "sway video: stopped, saved notification" "wf-recorder stopped;notify-send -a screenshot Recording saved $video" \
        "$(paste -sd ';' "$CALLS")"
    expect "sway video: no state left" "" "$(ls "$state" 2>/dev/null)"

    rm "$TMP/vaapi"
    touch "$TMP/x264"
    run sway --video --area --audio >/dev/null
    has "sway video area with audio, software H.264" "$(grep '^wf-recorder' "$CALLS")" \
        "-g 10,20 300x200" "-c libx264" "--audio=alsa_output.pci.monitor" "-C aac"
    expect "sway video area: slurp" 1 "$(grep -c '^slurp' "$CALLS")"
    run sway --video >/dev/null
    rm "$TMP/x264"

    touch "$TMP/vaapi"
    expect "X video: starts, exits 0" 0 "$(run x --video)"
    has "X video: ffmpeg x11grab, the screen, VAAPI" "$(grep '^ffmpeg' "$CALLS")" \
        "-vaapi_device /dev/dri/renderD128" "-f x11grab" "-i :0 " "hwupload" "-c:v h264_vaapi" "$video"
    run x --video >/dev/null
    expect "X video: stopped" "ffmpeg stopped" "$(grep stopped "$CALLS")"
    rm "$TMP/vaapi"

    run x --video --area --audio >/dev/null
    has "X video area (even size) with audio, libopenh264" "$(grep '^ffmpeg' "$CALLS")" \
        "-video_size 300x200" "-i :0+11,21" "-f pulse -i alsa_output.pci.monitor" "-c:v libopenh264" "-c:a aac"
    run x --video >/dev/null

    touch "$TMP/cancel"
    expect "video area cancelled: exits 0" 0 "$(run x --video --area)"
    expect "video area cancelled: no recorder, no state" "slop -f %x %y %w %h;" \
        "$(paste -sd ';' "$CALLS");$(ls "$state" 2>/dev/null)"
    rm "$TMP/cancel"

    touch "$TMP/die"
    expect "a recorder that dies: exits 1" 1 "$(run sway --video)"
    expect "a recorder that dies: its error in a notification" 1 \
        "$(grep -c '^notify-send.*cannot open device' "$CALLS")"
    expect "a recorder that dies: no state" "" "$(ls "$state" 2>/dev/null)"
    rm "$TMP/die"

    expect "--audio without --video: usage" 2 "$(run sway --audio)"
}

main() {
    write_stubs
    local file="$FAKE_HOME/Pictures/Screenshots/2026-11-12_10-00-00.png"

    expect "sway: exits 0" 0 "$(run sway)"
    expect "sway: grim, clipboard, notification" \
        "grim $file;wl-copy --type image/png png;notify-send -a screenshot Screenshot $file" \
        "$(paste -sd ';' "$CALLS")"
    expect "sway: saved" png "$(cat "$file" 2>/dev/null)"

    run sway --area >/dev/null
    expect "sway area: slurp, then grim -g" "slurp ;grim -g 10,20 300x200 $file" \
        "$(grep -E '^(slurp|grim)' "$CALLS" | paste -sd ';')"

    expect "X: exits 0" 0 "$(run x)"
    expect "X: maim, clipboard, notification" \
        "maim $file;xclip -selection clipboard -t image/png png;notify-send -a screenshot Screenshot $file" \
        "$(paste -sd ';' "$CALLS")"

    run x --area >/dev/null
    expect "X area: maim -s" "maim -s $file" "$(grep '^maim' "$CALLS")"

    touch "$TMP/cancel"
    expect "sway area cancelled: exits 0" 0 "$(run sway --area)"
    expect "sway area cancelled: no grim, no clipboard" "slurp " "$(paste -sd ';' "$CALLS")"
    expect "X area cancelled: exits 0" 0 "$(run x --area)"
    expect "X area cancelled: no clipboard, no file" "maim -s $file;" \
        "$(paste -sd ';' "$CALLS");$(ls "$FAKE_HOME/Pictures/Screenshots" 2>/dev/null)"
    rm "$TMP/cancel"

    test_video
    exit "$FAILED"
}

main "$@"
