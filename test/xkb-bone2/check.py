#!/usr/bin/env python3
"""Check the compiled bone2 XKB layout against .Xmodmap with libxkbcommon.

Usage: check.py XMODMAP

Runs in the test container (test.sh). libxkbcommon finds the layout in
~/.config/xkb, as for sway. The checks press the real modifier keys, so key
types, modifier keys and level order are all checked. Prints ok/FAIL lines;
exits 1 on a FAIL.
"""

import ctypes
import re
import sys
from pathlib import Path

LIBXKBCOMMON = "libxkbcommon.so.0"
RULES = "evdev"
MODEL = "pc105"
LAYOUT = "bone2"
LAYOUT_NAME = "Bone 2 (dotfiles)"
KEY_UP, KEY_DOWN = 0, 1
NO_SYMBOL = 0
LEVELS = 8

# X keycodes (also the XKB keycodes of the evdev keymap).
LFSH, RTSH, BKSL, CAPS, LSGT, RALT = 50, 62, 51, 66, 94, 108
AC02 = 39
AD01 = 24
TAB = 23
MODIFIER_KEYCODES = {LFSH, RTSH, BKSL, CAPS, LSGT, RALT}
# The base layout gives these XF86 keysyms; bone2 does not define them.
MEDIA_KEYCODES = {121, 122, 123, 172, 232, 233}
# `keysym X = ...` lines apply to the key that has X in the de layout.
KEYSYM_LINE_KEYCODES = {"less": LSGT, "ISO_Level3_Shift": RALT, "KP_Divide": 106}

# The xmodmap column of each XKB level. Main keys: Neo order, one to one.
# Keypad keys: the file's keypad legend puts Ebene 6/7 before Ebene 4.
MAIN_COLUMNS = (0, 1, 2, 3, 4, 5, 6, 7)
KEYPAD_COLUMNS = (0, 1, 2, 3, 6, 7, 4, 5)
KEYPAD_KEYCODES = {63, 77, 106} | set(range(79, 92))
# Neo Mod4 is the XKB level 5 shift (X: level 3); X mouse keys have no
# Wayland equivalent.
TRANSLATED = {"ISO_Level3_Lock": "ISO_Level5_Lock", "Pointer_EnableKeys": "NoSymbol"}
# A line without Mod4 columns: X ignores Mod4 for the key.
SHORT_LINE = 4
# X ignores Shift on the Mod3 levels where the shifted keysym is missing: the
# one-level types of its groups 2 and 3. Level index: shifted, unshifted.
SHIFT_FALLBACK = ((3, 2), (7, 6))

# Spot checks written out by hand from the Neo level legend, independent of
# the column rules above. Update them when .Xmodmap changes these keys.
SAMPLES = {
    "letter t": (39, "t T slash Greek_tau Left Left partialderivative partialderivative"),
    "digit 1": (10, "1 degree onesuperior onesubscript ordfeminine NoSymbol notsign notsign"),
    "dead keys": (49, "dead_circumflex dead_caron U21BB U02DE dead_abovedot NoSymbol dead_belowdot dead_belowdot"),
    "space": (65, "space space space nobreakspace KP_0 KP_0 U202F U202F"),
    "keypad 7": (79, "KP_7 U2714 U2195 U226A KP_Home KP_Home upstile upstile"),
    "Tab": (23, "Tab ISO_Left_Tab Multi_key ISO_Level5_Lock Tab ISO_Left_Tab Multi_key ISO_Level5_Lock"),
}


class RuleNames(ctypes.Structure):
    _fields_ = [(name, ctypes.c_char_p) for name in ("rules", "model", "layout", "variant", "options")]


def load_library():
    lib = ctypes.CDLL(LIBXKBCOMMON)
    pointer = ctypes.c_void_p
    signatures = {
        "xkb_context_new": (pointer, [ctypes.c_int]),
        "xkb_keymap_new_from_names": (pointer, [pointer, ctypes.POINTER(RuleNames), ctypes.c_int]),
        "xkb_keymap_num_layouts": (ctypes.c_uint32, [pointer]),
        "xkb_keymap_layout_get_name": (ctypes.c_char_p, [pointer, ctypes.c_uint32]),
        "xkb_state_new": (pointer, [pointer]),
        "xkb_state_unref": (None, [pointer]),
        "xkb_state_update_key": (ctypes.c_int, [pointer, ctypes.c_uint32, ctypes.c_int]),
        "xkb_state_key_get_one_sym": (ctypes.c_uint32, [pointer, ctypes.c_uint32]),
        "xkb_keysym_from_name": (ctypes.c_uint32, [ctypes.c_char_p, ctypes.c_int]),
        "xkb_keysym_get_name": (ctypes.c_int, [ctypes.c_uint32, ctypes.c_char_p, ctypes.c_size_t]),
    }
    for name, (restype, argtypes) in signatures.items():
        function = getattr(lib, name)
        function.restype = restype
        function.argtypes = argtypes
    return lib


class Keymap:
    def __init__(self, lib, keymap):
        self.lib = lib
        self.keymap = keymap

    def sym(self, keycode, held=(), taps=()):
        """Keysym of keycode while `held` keys are down, after `taps` sequences."""
        state = self.lib.xkb_state_new(self.keymap)
        try:
            for sequence in taps:
                for key in sequence:
                    self.lib.xkb_state_update_key(state, key, KEY_DOWN)
                for key in reversed(sequence):
                    self.lib.xkb_state_update_key(state, key, KEY_UP)
            for key in held:
                self.lib.xkb_state_update_key(state, key, KEY_DOWN)
            return self.lib.xkb_state_key_get_one_sym(state, keycode)
        finally:
            self.lib.xkb_state_unref(state)

    def name(self, sym):
        buffer = ctypes.create_string_buffer(64)
        self.lib.xkb_keysym_get_name(sym, buffer, len(buffer))
        return buffer.value.decode()

    def from_name(self, name):
        return self.lib.xkb_keysym_from_name(name.encode(), 0)


def level_keys(level3_key, level5_key, shift_key):
    """Keys held for levels 1-8."""
    return (
        (),
        (shift_key,),
        (level3_key,),
        (level3_key, shift_key),
        (level5_key,),
        (level5_key, shift_key),
        (level3_key, level5_key),
        (level3_key, level5_key, shift_key),
    )


def parse_xmodmap(path):
    """Map X keycode to its keysym columns, in file order; later lines win."""
    keys = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^\s*(keycode|keysym)\s+(\S+)\s*=\s*(.*)$", line)
        if not match or not match.group(3).split():
            continue
        kind, key, rest = match.groups()
        if kind == "keysym":
            if key not in KEYSYM_LINE_KEYCODES:
                raise SystemExit(f"FAIL: no keycode for `keysym {key}`")
            keys[KEYSYM_LINE_KEYCODES[key]] = rest.split()
        else:
            keys[int(key)] = rest.split()
    return keys


def expected_levels(keycode, columns):
    if len(columns) <= SHORT_LINE:
        columns = (columns + ["NoSymbol"] * (SHORT_LINE - len(columns))) * 2
    columns = columns + ["NoSymbol"] * (LEVELS - len(columns))
    order = KEYPAD_COLUMNS if keycode in KEYPAD_KEYCODES else MAIN_COLUMNS
    levels = [TRANSLATED.get(columns[column], columns[column]) for column in order]
    for shifted, unshifted in SHIFT_FALLBACK:
        if levels[shifted] == "NoSymbol":
            levels[shifted] = levels[unshifted]
    return levels


def check_levels(keymap, keys, modifiers, label):
    """Compare every key and level; one FAIL line per difference."""
    held_per_level = level_keys(*modifiers)
    failures = 0
    checked = 0
    for keycode, columns in keys.items():
        if keycode in MODIFIER_KEYCODES or keycode in MEDIA_KEYCODES:
            continue
        for level, want in enumerate(expected_levels(keycode, columns), start=1):
            want_sym = keymap.from_name(want)
            if want_sym == NO_SYMBOL and want != "NoSymbol":
                print(f"FAIL: keycode {keycode}: unknown keysym {want} in the xmodmap")
                failures += 1
                continue
            got = keymap.sym(keycode, held_per_level[level - 1])
            checked += 1
            if got != want_sym:
                print(f"FAIL: {label}: keycode {keycode} level {level}: want {want}, got {keymap.name(got)}")
                failures += 1
    if not failures:
        print(f"ok:   {label}: {checked} levels of {checked // LEVELS} keys match .Xmodmap")
    return failures


def check(name, want, got):
    if want == got:
        print(f"ok:   {name}")
        return 0
    print(f"FAIL: {name}: want {want}, got {got}")
    return 1


def main(argv):
    if len(argv) != 2:
        raise SystemExit(__doc__)
    keys = parse_xmodmap(Path(argv[1]))
    lib = load_library()
    context = lib.xkb_context_new(0)
    names = RuleNames(RULES.encode(), MODEL.encode(), LAYOUT.encode(), b"", b"")
    pointer = lib.xkb_keymap_new_from_names(context, ctypes.byref(names), 0)
    if not pointer:
        print("FAIL: libxkbcommon cannot compile layout bone2 from ~/.config/xkb")
        return 1
    keymap = Keymap(lib, pointer)

    failures = check("one layout (no XKB groups)", 1, lib.xkb_keymap_num_layouts(pointer))
    failures += check("layout name", LAYOUT_NAME, lib.xkb_keymap_layout_get_name(pointer, 0).decode())

    sym = keymap.sym
    name = keymap.name
    failures += check("Caps is Mod3", "ISO_Level3_Shift", name(sym(CAPS)))
    failures += check("#' is Mod3", "ISO_Level3_Shift", name(sym(BKSL)))
    failures += check("< is Mod4", "ISO_Level5_Shift", name(sym(LSGT)))
    failures += check("right Alt is Mod4", "ISO_Level5_Shift", name(sym(RALT)))

    failures += check_levels(keymap, keys, (CAPS, LSGT, LFSH), "Caps, <, left Shift")
    failures += check_levels(keymap, keys, (BKSL, RALT, RTSH), "#', right Alt, right Shift")

    held_per_level = level_keys(CAPS, LSGT, LFSH)
    for label, (keycode, want) in SAMPLES.items():
        got = " ".join(name(sym(keycode, held)) for held in held_per_level)
        normalized = " ".join(name(keymap.from_name(word)) for word in want.split())
        failures += check(f"levels 1-8 of {label}", normalized, got)

    for keycode in sorted(MEDIA_KEYCODES & keys.keys()):
        failures += check(f"media key {keycode}", keys[keycode][0], name(sym(keycode)))

    lower, upper = keys[AD01][0], keys[AD01][1]
    shift_lock = ((LFSH, RTSH),)
    failures += check("Shift+Shift locks Shift", upper, name(sym(AD01, taps=shift_lock)))
    failures += check("Shift releases the Shift lock", lower, name(sym(AD01, taps=shift_lock + ((LFSH,),))))

    base, mod4 = keys[AC02][0], expected_levels(AC02, keys[AC02])[4]
    mod4_lock = ((LSGT, RALT),)
    failures += check("Mod4+Mod4 locks Mod4", mod4, name(sym(AC02, taps=mod4_lock)))
    failures += check("Mod4 releases the Mod4 lock", base, name(sym(AC02, taps=mod4_lock + ((LSGT,),))))
    tab_lock = ((LFSH, CAPS, TAB),)
    failures += check("Shift+Mod3+Tab locks Mod4", mod4, name(sym(AC02, taps=tab_lock)))
    failures += check("Shift+Mod3+Tab releases the Mod4 lock", base, name(sym(AC02, taps=tab_lock * 2)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
