# tmux-flash: context for changes

Read before changes in this directory. The `AGENTS.md` rules of the user
apply; this file does not repeat them. This directory will move to its own
repository: keep it self-contained (no paths outside it, no `git init` here).

## Purpose

Jump labels for a tmux pane with the rules of flash.nvim. It replaces the
tmux-jump plugin (Ruby, one character, word starts only).

## flash.nvim rules (source: `labeler.lua`, `state.lua`, `matcher.lua`)

- Search area: the visible rows of the target pane; in a scrolled copy mode
  the scrolled view. Exact substring match, anywhere in a line, overlapping
  matches, no match across lines.
- Case: smart case (lowercase pattern ignores case), as the user's nvim
  (`ignorecase` + `smartcase`).
- Label pool: `ctieobnrsgjduaxphlmwfvyz` (the user's nvim flash labels, Bone
  2), then the same letters in uppercase; duplicates removed.
- Empty pattern: no labels.
- Skip rule: no label is a grapheme that directly follows a visible match.
  With smart or ignore case both cases are skipped (flash uses `ignorecase`
  there, not `smartcase`).
- Order: distance `|row*width+col - (cursor_row*width+cursor_col)|`, then
  reading order. Labels go in pool order.
- Reuse: a lowercase label stays on its position (row, grapheme index) while
  that position matches. Uppercase labels are not kept.
- Pool exhausted: the remaining matches are highlighted without a label.
- Current match: the first match strictly after the cursor, else the first
  match (wrap). It has a label too.
- Keys: a label jumps; another character extends the pattern; Backspace
  removes the last one; Enter jumps to the current match; Escape and Ctrl+C
  cancel. A character that leaves no match ends without a jump.
- Jump target: the first grapheme of the match.
- Not done: regex and fuzzy modes, max_length, autojump, labels before the
  match, other panes (flash multi_window).

## Design

- Two processes. The tmux binding runs `tmux-flash --pane P --client C` with
  `run-shell -b`. It reads the pane size and opens
  `display-popup -B -E -x '#{popup_pane_left}' -y '#{popup_pane_bottom}'
  -w W -h H`, which runs `tmux-flash --ui ...`. `-w` and `-h` do not take
  formats ("height invalid"). The popup covers the pane exactly (tested:
  split panes, zoomed pane, status and pane-border status at the top).
- Panes do not redraw while a popup is open. The popup gets raw keys: Enter
  `0d`, Backspace `7f`, Escape `1b` alone, Ctrl+C `03`.
- Jump: one tmux call: `copy-mode` (normal mode only), `top-line`,
  `cursor-down N`, `start-of-line`, `cursor-right K`. K is the number of
  grapheme clusters before the target in the captured line. On tmux 3.5a this
  was exact for ASCII, CJK, emoji, combining marks, ZWJ sequences, flags and
  tabs (`capture-pane` turns tabs into spaces). A tmux that does not join ZWJ
  sequences puts labels and the jump off after such an emoji.
- Capture: `capture-pane -p -t P`; in copy mode with scroll position S and
  height H: `-S -S -E H-1-S`. The cursor: `cursor_x/y`, in copy mode
  `copy_cursor_x/y`.
- Prompt `⚡ <pattern>`: `display-message -c C -d 0` (the tmux message line,
  as flash uses the command line). A `-d 0` message stays after the popup
  closes: every exit clears it with `display-message -c C -d 1 ""`.
- Colors: the user's nvim flash highlights (solarized.nvim autumn). Theme from
  the tmux option `@color-mode` (`dark` default, `light`):
  - dark: backdrop fg `#586e75`; match fg `#002b36` bg `#b58900`; current the
    same, bold; label fg `#002731` bg `#ffffff` bold.
  - light: backdrop fg `#93a1a1`; match fg `#fdf6e3` bg `#b58900`; current
    the same, bold; label fg `#fdf6e3` bg `#d33682` bold.
  The backdrop keeps the terminal background.
- Time to popup: about 23 ms (tmux 3.5a, each tmux call about 5 ms).

## Layers

`main` (arguments) → `app` (launcher, UI loop) → the pure modules `flash`
(rules: `screen`, `matcher`, `labeler`, `session`), `paint` (the frame as
styled spans) and `theme` (colors), and the adapters `tmux` (the only module
that starts processes) and `term` (the only module that reads keys or writes
escape sequences). The pure modules do no I/O.

- Smart case only: `Ignore` and `Sensitive` modes were dead code and went.
- `pub(crate)` everywhere (`unreachable_pub`); clippy's `redundant_pub_crate`
  asks for the opposite and is allowed in `Cargo.toml`.
- `display-message` expands formats: `#` in a message is written `##`.
- tmux output: the fields of `display-message -p` are tab separated
  (`pane_mode` and the copy cursor are empty outside copy mode).

## Tests

- Unit tests in `<file>_test.rs`; integration tests are modules of
  `tests/it/main.rs`.
- tmux tests use private servers: `TMUX` unset, own `TMUX_TMPDIR`. Never the
  caller's server. A second tmux server runs `tmux attach` in its pane as the
  client and gets the keys (`send-keys`); `capture-pane` of that pane shows
  what the client shows, popups included. Popups and `command-prompt` need a
  client.
- Wait with polling and a timeout, not fixed sleeps.
- `tests/it/harness.rs`: the inner server has `escape-time 10` (the 500 ms
  default delays Escape), the outer one `status off`. Wait for the `⚡`
  prompt before typing; `prompt_is` compares the whole message line.
- Expected labels follow reuse: they come from the first character typed
  ("a"), and stay when the pattern grows ("al"). Compute them that way.
- `cargo clippy --locked --all-targets -- -D warnings` and
  `cargo fmt --check` must be clean.
