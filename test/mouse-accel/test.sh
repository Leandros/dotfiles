#!/usr/bin/env bash
#
# Checks the mouse acceleration curves: 85 % of libinput's adaptive mouse
# curve (src/filter-mouse.c, libinput 1.32) at the speed each session used
# before, as custom curves. sway: speed -0.27 (.config/sway/config,
# type:pointer); X: speed 0, libinput's default (xorg-conf/45-mouse.conf).
# Also checks that the TrackPoint keeps the adaptive profile in both.
#
# Usage: test/mouse-accel/test.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SWAY_CONFIG="$HERE/../../.config/sway/config"
readonly X_CONF="$HERE/../../xorg-conf/45-mouse.conf"

python3 -I - "$SWAY_CONFIG" "$X_CONF" <<'EOF'
import re
import sys

sway_path, x_path = sys.argv[1], sys.argv[2]
failed = False


def check(name, cond, detail=""):
    global failed
    print(("ok:   " if cond else "FAIL: ") + name + ("" if cond else ": " + detail))
    failed |= not cond


# libinput's adaptive profile for mice, speeds in units/ms (1000 dpi; the
# custom profile gets raw units, the same for mice without a hwdb DPI).
def adaptive(v, speed):
    threshold = max(0.4 - 0.25 * speed, 0.2)
    max_accel = 2.0 + 1.5 * speed
    incline = 1.1 + 0.75 * speed
    if v < 0.07:
        factor = 10 * v + 0.3
    elif v < threshold:
        factor = 1.0
    else:
        factor = incline * (v - threshold) + 1
    return v * min(max_accel, factor)


def check_curve(name, step, points, speed):
    check(f"{name}: 64 points", len(points) == 64, str(len(points)))
    want = [round(0.85 * adaptive(i * step, speed), 4) for i in range(len(points))]
    bad = [(i, p, w) for i, (p, w) in enumerate(zip(points, want)) if abs(p - w) > 0.00005]
    check(f"{name}: 85 % of adaptive at speed {speed}", not bad, f"first mismatch (index, have, want): {bad[:3]}")
    # The last two points are on the capped (linear) part, so libinput's
    # extrapolation beyond them stays 85 %.
    for v in (step * 70, step * 100):
        x0, x1 = step * 62, step * 63
        y = points[62] + (points[63] - points[62]) * (v - x0) / (x1 - x0)
        check(f"{name}: extrapolated at {v:.2f} u/ms", abs(y - 0.85 * adaptive(v, speed)) < 0.001,
              f"{y} != {0.85 * adaptive(v, speed)}")


sway = open(sway_path).read()
m = re.search(r"^input type:pointer \{(.*?)^\}", sway, re.S | re.M)
check("sway: type:pointer block", m is not None)
if m:
    block = m.group(1)
    check("sway: mice use the custom profile", re.search(r"^\s*accel_profile custom$", block, re.M) is not None)
    c = re.search(r"^\s*pointer_accel_custom (\S+) (.*)$", block, re.M)
    check("sway: pointer_accel_custom", c is not None)
    if c:
        check_curve("sway", float(c.group(1)), [float(p) for p in c.group(2).split()], -0.27)
t = re.search(r'^input "2:10:TPPS/2_Elan_TrackPoint" \{(.*?)^\}', sway, re.S | re.M)
check("sway: TrackPoint keeps adaptive",
      t is not None and re.search(r"^\s*accel_profile adaptive$", t.group(1), re.M) is not None)

x = open(x_path).read()
check("X: pointers that are no touchpad", 'MatchIsPointer "on"' in x and 'MatchIsTouchpad "off"' in x)
check("X: not the TrackPoint", 'NoMatchProduct "TrackPoint"' in x)
check("X: custom profile", 'Option "AccelProfile" "custom"' in x)
step = re.search(r'Option "AccelStepMotion" "([^"]+)"', x)
points = re.search(r'Option "AccelPointsMotion" "([^"]+)"', x)
check("X: step and points", step is not None and points is not None)
if step and points:
    check_curve("X", float(step.group(1)), [float(p) for p in points.group(1).split()], 0.0)

sys.exit(1 if failed else 0)
EOF
