#!/usr/bin/env python3
"""Generate the bone2 XKB layout from the bone2 .Xmodmap.

Usage: xkb/xmodmap-to-xkb.py .Xmodmap > xkb/symbols/bone2

Wayland has no xmodmap. The xmodmap reaches its levels with two X groups;
XKB groups are not an option (some keyboards make bone2 in firmware and
need the plain layouts). So the result has one group with eight levels, as
xkeyboard-config's de(neo): Mod3 (Caps, #') is ISO_Level3_Shift, Mod4
(<, right Alt) is ISO_Level5_Shift.

    xmodmap column     1  2  3  4  5  6  7  8
    Neo Ebene          1  2  3  5  4  4+Shift  6  7
    XKB level          1  2  3  4  5  6  7  8
    keypad keys: XKB level 5 6 7 8 = column 7 8 5 6 (the file's keypad legend)

Other rules, so that the layout acts as the xmodmap does in X:
- An empty level 4 or 8 takes level 3 or 7: X ignores Shift there.
- A line without Mod4 columns (Tab) repeats levels 1-4 on 5-8: X ignores Mod4.
- ISO_Level3_Lock (X: locks Mod4) becomes ISO_Level5_Lock.
- Pointer_EnableKeys (X mouse keys) becomes NoSymbol: Wayland has no mouse keys.
- Modifier keys come from the xkeyboard-config includes (the Neo ones);
  media keys from the base layout (inet).
"""

import re
import sys
from pathlib import Path

LEVELS = 8
OUTPUT = "xkb/symbols/bone2"
LAYOUT_NAME = "Bone 2 (dotfiles)"

# X (evdev) keycode to XKB key name, for the keys the xmodmap defines.
# Embedded, so the output does not depend on the host's xkeyboard-config.
KEY_NAMES = {
    49: "TLDE", 10: "AE01", 11: "AE02", 12: "AE03", 13: "AE04", 14: "AE05", 15: "AE06",
    16: "AE07", 17: "AE08", 18: "AE09", 19: "AE10", 20: "AE11", 21: "AE12",
    23: "TAB", 24: "AD01", 25: "AD02", 26: "AD03", 27: "AD04", 28: "AD05", 29: "AD06",
    30: "AD07", 31: "AD08", 32: "AD09", 33: "AD10", 34: "AD11", 35: "AD12", 36: "RTRN",
    38: "AC01", 39: "AC02", 40: "AC03", 41: "AC04", 42: "AC05", 43: "AC06", 44: "AC07",
    45: "AC08", 46: "AC09", 47: "AC10", 48: "AC11",
    52: "AB01", 53: "AB02", 54: "AB03", 55: "AB04", 56: "AB05", 57: "AB06", 58: "AB07",
    59: "AB08", 60: "AB09", 61: "AB10", 65: "SPCE",
    77: "NMLK", 106: "KPDV", 63: "KPMU", 82: "KPSU", 79: "KP7", 80: "KP8", 81: "KP9",
    86: "KPAD", 83: "KP4", 84: "KP5", 85: "KP6", 87: "KP1", 88: "KP2", 89: "KP3",
    90: "KP0", 91: "KPDL",
}

# `keysym X = ...` lines apply to the key that has X in the de layout.
KEYSYM_LINE_KEYCODES = {"less": 94, "ISO_Level3_Shift": 108, "KP_Divide": 106}

# Shift, Mod3 and Mod4 keys: the includes below define them.
MODIFIER_KEYCODES = {50, 62, 66, 51, 94, 108}
# Mute, volume, play, brightness: inet(evdev) has them and comes after this
# file in the rules, so a definition here would have no effect.
MEDIA_KEYCODES = {121, 122, 123, 172, 232, 233}

# The Neo modifiers of de(neo), with two changes for the xmodmap: Shift+Shift
# is Shift_Lock (not Caps_Lock), and one Mod4 releases the Mod4 lock.
INCLUDES = (
    "shift(both_shiftlock)",
    "level3(caps_switch)",
    "level3(bksl_switch)",
    "level5(lsgt_switch_lock_cancel)",
    "level5(ralt_switch_lock_cancel)",
)

MAIN_COLUMNS = (0, 1, 2, 3, 4, 5, 6, 7)
KEYPAD_COLUMNS = (0, 1, 2, 3, 6, 7, 4, 5)
KEYPAD_KEYCODES = {63, 77, 106} | set(range(79, 92))
SHORT_LINE = 4
SHIFT_FALLBACK = ((3, 2), (7, 6))
TRANSLATED = {"ISO_Level3_Lock": "ISO_Level5_Lock", "Pointer_EnableKeys": "NoSymbol"}
# A group keysym would bring back the XKB groups the layout must not have.
GROUP_KEYSYMS = {
    "ISO_Group_Shift", "ISO_Group_Latch", "ISO_Group_Lock", "ISO_First_Group",
    "ISO_Last_Group", "ISO_Next_Group", "ISO_Prev_Group", "Mode_switch",
}

# Level-5 lock types of de(neo); the alphabetic one follows Caps_Lock.
TYPE_ALPHABETIC = "EIGHT_LEVEL_ALPHABETIC_WITH_LEVEL5_LOCK"
TYPE_OTHER = "EIGHT_LEVEL_WITH_LEVEL5_LOCK"
# Case pairs whose keysym names do not differ in the first letter only.
CASE_PAIRS = {("ssharp", "U1E9E")}


def parse_xmodmap(path):
    """Map X keycode to its keysym columns, in file order; later lines win."""
    keys = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^\s*(keycode|keysym)\s+(\S+)\s*=\s*(.*)$", line)
        if not match or not match.group(3).split():
            continue
        kind, key, rest = match.groups()
        if kind == "keycode":
            keys[int(key)] = rest.split()
            continue
        if key not in KEYSYM_LINE_KEYCODES:
            raise SystemExit(f"keysym {key}: unknown keycode, add it to KEYSYM_LINE_KEYCODES")
        keys[KEYSYM_LINE_KEYCODES[key]] = rest.split()
    return keys


def xkb_levels(keycode, columns):
    """The eight XKB level keysyms of one xmodmap line."""
    if len(columns) > LEVELS:
        raise SystemExit(f"keycode {keycode}: more than {LEVELS} columns")
    if len(columns) <= SHORT_LINE:
        columns = (columns + ["NoSymbol"] * (SHORT_LINE - len(columns))) * 2
    columns = columns + ["NoSymbol"] * (LEVELS - len(columns))

    order = KEYPAD_COLUMNS if keycode in KEYPAD_KEYCODES else MAIN_COLUMNS
    levels = [TRANSLATED.get(columns[column], columns[column]) for column in order]
    for shifted, unshifted in SHIFT_FALLBACK:
        if levels[shifted] == "NoSymbol":
            levels[shifted] = levels[unshifted]

    groups = GROUP_KEYSYMS.intersection(levels)
    if groups:
        raise SystemExit(f"keycode {keycode}: group keysym {sorted(groups)[0]}")
    return levels


def key_type(levels):
    lower, upper = levels[0], levels[1]
    if (lower, upper) in CASE_PAIRS:
        return TYPE_ALPHABETIC
    if lower[:1].islower() and upper == lower[0].upper() + lower[1:]:
        return TYPE_ALPHABETIC
    return TYPE_OTHER


def render(keys, source):
    rows = []
    for keycode, columns in keys.items():
        if keycode in MODIFIER_KEYCODES or keycode in MEDIA_KEYCODES:
            continue
        if keycode not in KEY_NAMES:
            raise SystemExit(f"keycode {keycode}: no XKB key name, add it to KEY_NAMES")
        levels = xkb_levels(keycode, columns)
        rows.append((KEY_NAMES[keycode], key_type(levels), levels))

    width = max(len(sym) for _, _, levels in rows for sym in levels) + 1
    out = [
        f"// Generated by {Path(__file__).name} from {source}; do not edit.",
        f"// Regenerate: xkb/{Path(__file__).name} .Xmodmap > {OUTPUT}",
        "//",
        "// Bone 2 in one group with eight levels, as de(neo): Caps and #' (Mod3)",
        "// select level 3, < and right Alt (Mod4) level 5. Pointer_EnableKeys",
        "// (X mouse keys) is NoSymbol: Wayland has no mouse keys.",
        "// sway: input type:keyboard xkb_layout bone2 (found in ~/.config/xkb).",
        "",
        "default partial alphanumeric_keys modifier_keys keypad_keys",
        'xkb_symbols "basic" {',
        f'    name[Group1]= "{LAYOUT_NAME}";',
        "",
    ]
    out += [f'    include "{include}"' for include in INCLUDES]

    current_type = None
    for name, type_name, levels in rows:
        if type_name != current_type:
            out += ["", f'    key.type[Group1] = "{type_name}";']
            current_type = type_name
        syms = "".join(f"{sym + ',':<{width + 1}}" for sym in levels[:-1]) + levels[-1]
        out.append(f"    key {'<' + name + '>':>6} {{ [ {syms} ] }};")
    out.append("};")
    return "\n".join(out) + "\n"


def main(argv):
    if len(argv) != 2:
        raise SystemExit(__doc__)
    xmodmap = Path(argv[1])
    sys.stdout.write(render(parse_xmodmap(xmodmap), xmodmap.name))


if __name__ == "__main__":
    main(sys.argv)
