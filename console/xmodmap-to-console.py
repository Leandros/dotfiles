#!/usr/bin/env python3
"""Generate a Linux console keymap from the bone2 ~/.Xmodmap.

Usage: xmodmap-to-console.py ~/.Xmodmap > bone2.map

The console has no level 4/5/6 modifiers, so the layers are placed on the
spare modifier bits the kernel offers:

    level 3 (Mod3)        -> AltGr
    level 4 (Mod4)        -> CtrlL
    level 5 (Shift+Mod3)  -> Shift AltGr
    level 6 (Mod3+Mod4)   -> AltGr CtrlL

Keypad keys and media keys are left to the distribution defaults; the
console cannot force NumLock, so the keypad layers would misfire.
"""

import re
import sys
from pathlib import Path

KEYSYMDEF = Path("/usr/include/X11/keysymdef.h")

# evdev X keycodes are kernel keycodes plus this offset.
X_KEYCODE_OFFSET = 8

# Column order of a `keycode N = ...` line in the xmodmap, as console
# modifier prefixes. Level 7 (last column) is unused by the layout.
XMODMAP_LEVELS = ("", "shift", "altgr", "shift altgr", "ctrll", "shift ctrll", "altgr ctrll")

# `keysym X = ...` lines are relative to the de layout the xmodmap is applied on.
KEYSYM_LINE_KEYCODES = {"less": 94, "ISO_Level3_Shift": 108}

# Modifier keys: only the first keysym matters; the console takes one keysym.
MODIFIERS = {
    "Shift_L": "Shift",
    "Shift_R": "Shift",
    "Control_L": "Control",
    "Control_R": "Control",
    "Alt_L": "Alt",
    "ISO_Group_Shift": "AltGr",
    "ISO_Level3_Shift": "CtrlL",
}

# X keycodes of the keypad block and media keys; see module docstring.
SKIPPED_X_KEYCODES = {63, 77, 82, 86, 106, 121, 122, 123, 172, 232, 233} | set(range(79, 92))

# X keysyms with a console equivalent that is not a plain character.
# Keypad digits become digits: without NumLock the kernel turns KP_n into
# cursor movement.
FUNCTION_KEYSYMS = {
    "Tab": "Tab",
    "ISO_Left_Tab": "Tab",
    "Return": "Return",
    "KP_Enter": "Return",
    "BackSpace": "Delete",
    "Delete": "Remove",
    "Escape": "Escape",
    "Insert": "Insert",
    "Home": "Home",
    "End": "End",
    "Prior": "PageUp",
    "Next": "PageDown",
    "Up": "Up",
    "Down": "Down",
    "Left": "Left",
    "Right": "Right",
    "Multi_key": "Compose",
    "KP_Add": "plus",
    "KP_Subtract": "minus",
    "KP_Multiply": "asterisk",
    "KP_Divide": "slash",
    "KP_Separator": "comma",
    "KP_Decimal": "period",
    "NoSymbol": "VoidSymbol",
    "Undo": "VoidSymbol",
    "Redo": "VoidSymbol",
    "Pointer_EnableKeys": "VoidSymbol",
    "ISO_Level3_Lock": "VoidSymbol",
}
DIGIT_WORDS = ("zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine")
FUNCTION_KEYSYMS.update({f"KP_{digit}": word for digit, word in enumerate(DIGIT_WORDS)})

# Dead keys the console knows; others degrade to nothing rather than a wrong key.
DEAD_KEYSYMS = {
    "dead_grave", "dead_acute", "dead_circumflex", "dead_tilde", "dead_diaeresis",
    "dead_cedilla", "dead_macron", "dead_breve", "dead_abovedot", "dead_abovering",
    "dead_doubleacute", "dead_caron", "dead_belowdot", "dead_stroke",
}
DEAD_ALIASES = {"dead_psili": "dead_abovecomma", "dead_dasia": "dead_abovereversedcomma"}
# keysymdef.h moved these from U+2329/U+232A to the mathematical brackets in
# xorgproto 2023; pin them so the output does not depend on the host headers.
PINNED_UNICODE = {"leftanglebracket": 0x27E8, "rightanglebracket": 0x27E9}
# Console keysym names for ASCII digits; X uses the digit itself.
DIGIT_NAMES = {str(digit): word for digit, word in enumerate(DIGIT_WORDS)}
LATIN1_MAX = 0xFF
ASCII_MAX = 0x7F
UNICODE_KEYSYM_FLAG = 0x1000000

# Keys the layout does not touch, inlined because `include` only resolves
# inside the distribution keymap directories, not for a file given by path.
FUNCTION_KEYCODES = (59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 87, 88)
KEYPAD_KEYS = {
    69: "Num_Lock", 98: "KP_Divide", 55: "KP_Multiply", 74: "KP_Subtract", 78: "KP_Add",
    96: "KP_Enter", 71: "KP_7", 72: "KP_8", 73: "KP_9", 75: "KP_4", 76: "KP_5", 77: "KP_6",
    79: "KP_1", 80: "KP_2", 81: "KP_3", 82: "KP_0", 83: "KP_Period",
}
FIXED_KEYS = {
    1: "Escape", 14: "Delete", 97: "Control", 103: "Up", 105: "Left", 106: "Right", 108: "Down",
    110: "Insert", 102: "Home", 104: "PageUp", 111: "Remove", 107: "End", 109: "PageDown",
    84: "Last_Console", 99: "VoidSymbol", 70: "Scroll_Lock", 101: "Break", 119: "Pause",
}
FIXED_ALT_KEYS = {
    14: "Meta_Delete", 103: "KeyboardSignal", 105: "Decr_Console", 106: "Incr_Console",
    99: "Control_backslash", 70: "Show_Registers",
}


def prelude():
    lines = ["keymaps 0-127", "compose as usual", ""]
    for number, keycode in enumerate(FUNCTION_KEYCODES, start=1):
        lines.append(f"keycode {keycode:3d} = F{number}")
        lines.append(f"        alt keycode {keycode:3d} = Console_{number}")
        lines.append(f"control alt keycode {keycode:3d} = Console_{number}")
    lines.append("")
    lines += [f"keycode {keycode:3d} = {sym}" for keycode, sym in KEYPAD_KEYS.items()]
    lines.append("")
    lines += [f"keycode {keycode:3d} = {sym}" for keycode, sym in FIXED_KEYS.items()]
    lines += [f"alt keycode {keycode:3d} = {sym}" for keycode, sym in FIXED_ALT_KEYS.items()]
    lines.append("")
    return "\n".join(lines)


def load_keysym_unicode(path):
    """Map X keysym name to Unicode code point from keysymdef.h."""
    pattern = re.compile(r"^#define XK_(\w+)\s+0x([0-9a-fA-F]+)\s*(?:/\*\(?\s*U\+([0-9A-Fa-f]{4,6}))?")
    table = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        name, value, unicode_hint = match.groups()
        value = int(value, 16)
        if unicode_hint:
            table[name] = int(unicode_hint, 16)
        elif value & UNICODE_KEYSYM_FLAG:
            table[name] = value & ~UNICODE_KEYSYM_FLAG
        elif value <= LATIN1_MAX:
            table[name] = value
    return table


def console_keysym(name, keysyms):
    """Translate one X keysym name to a console keysym name."""
    if name in FUNCTION_KEYSYMS:
        return FUNCTION_KEYSYMS[name]
    name = DEAD_ALIASES.get(name, name)
    if name.startswith("dead_"):
        return name if name in DEAD_KEYSYMS else "VoidSymbol"
    if name in DIGIT_NAMES:
        return DIGIT_NAMES[name]
    if len(name) == 1 and name.isascii() and name.isalpha():
        return name

    if re.fullmatch(r"U[0-9A-Fa-f]{4,6}", name):
        return f"U+{int(name[1:], 16):04x}"
    if name in PINNED_UNICODE:
        return f"U+{PINNED_UNICODE[name]:04x}"
    if name not in keysyms:
        print(f"warning: no console keysym for {name}, dropped", file=sys.stderr)
        return "VoidSymbol"
    code = keysyms[name]
    # Latin-1 names are shared between X and the console.
    if code <= LATIN1_MAX and name[0].islower() and name.isalpha():
        return name
    return f"U+{code:04x}"


def describe(sym):
    """Readable glyph for a line comment."""
    if not sym.startswith("U+"):
        return ""
    glyph = chr(int(sym[2:], 16))
    return glyph if glyph.isprintable() and not glyph.isspace() else ""


def parse_xmodmap(path):
    """Yield (x_keycode, [keysyms]) for every key definition line."""
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("!"):
            continue
        match = re.match(r"^(keycode|keysym)\s+(\S+)\s*=\s*(.*)$", line)
        if not match:
            continue
        kind, key, rest = match.groups()
        keysyms = rest.split()
        if not keysyms:
            continue
        if kind == "keysym":
            if key not in KEYSYM_LINE_KEYCODES:
                continue
            yield KEYSYM_LINE_KEYCODES[key], keysyms
        else:
            yield int(key), keysyms


def emit_key(x_keycode, x_keysyms, keysyms, out):
    keycode = x_keycode - X_KEYCODE_OFFSET
    if x_keysyms[0] in MODIFIERS:
        out.append(f"keycode {keycode:3d} = {MODIFIERS[x_keysyms[0]]}")
        return

    # Fewer columns than levels: the rest is unbound.
    levels = x_keysyms + ["NoSymbol"] * len(XMODMAP_LEVELS)
    for prefix, x_name in zip(XMODMAP_LEVELS, levels):
        sym = console_keysym(x_name, keysyms)
        if not prefix and sym == "VoidSymbol":
            raise SystemExit(f"keycode {x_keycode}: level 1 has no console keysym")
        glyph = describe(sym)
        comment = f"  # {glyph}" if glyph else ""
        out.append(f"{prefix:>12} keycode {keycode:3d} = {sym}{comment}")

    # loadkeys derives Meta_x for letters only; give the other ASCII keys the
    # same Alt behaviour the stock keymaps have.
    base = x_keysyms[0]
    code = keysyms.get(base, ASCII_MAX + 1)
    if code <= ASCII_MAX and not chr(code).isalpha():
        out.append(f"{'alt':>12} keycode {keycode:3d} = Meta_{console_keysym(base, keysyms)}")


def main(argv):
    if len(argv) != 2:
        raise SystemExit(__doc__)
    xmodmap = Path(argv[1])
    keysyms = load_keysym_unicode(KEYSYMDEF)

    out = [
        f"# Generated by {Path(__file__).name} from {xmodmap.name}; do not edit.",
        "# bone2 for the Linux console. Load with: loadkeys <this file>",
        "",
        prelude(),
    ]
    seen = set()
    for x_keycode, x_keysyms in parse_xmodmap(xmodmap):
        if x_keycode in SKIPPED_X_KEYCODES or x_keycode in seen:
            continue
        seen.add(x_keycode)
        emit_key(x_keycode, x_keysyms, keysyms, out)
        out.append("")
    sys.stdout.write("\n".join(out).rstrip("\n") + "\n")


if __name__ == "__main__":
    main(sys.argv)
