# tmux-flash

Jump labels for a tmux pane, with the rules of
[flash.nvim](https://github.com/folke/flash.nvim): type any number of
characters, then the label of a match; the cursor goes there in copy mode.

## Use

```
bind-key g run-shell -b 'tmux-flash --pane "#{pane_id}" --client "#{client_name}"'
```

Needs tmux 3.3 or later (`display-popup -B`). A popup covers the pane; the
pattern shows in the message line.

| Key | Action |
|---|---|
| characters | Extend the pattern; matches anywhere in the visible rows |
| a label | Jump to its match |
| `Enter` | Jump to the next match after the cursor |
| `Backspace` | Remove the last character |
| `Escape`, `Ctrl+c` | Cancel |

- Smart case: a pattern without uppercase letters ignores case.
- Labels: the nearest match gets the first label. No label is a character
  that follows a match, so typing on never jumps by mistake. A lowercase
  label stays on its match while the pattern grows. After the labels come the
  same letters in uppercase.
- A character that leaves no match ends tmux-flash.

## Options

| Option | Default | Meaning |
|---|---|---|
| `@flash-labels` | `asdfghjklqwertyuiopzxcvbnm` (flash.nvim) | Label characters, first used first. Spaces are ignored. |
| `@color-mode` | `dark` | `light` selects the light Solarized colors. |

```
set -g @flash-labels 'ctieobnrsgjduaxphlmwfvyz'
```

## Development

```
cargo build --locked
cargo test --locked
cargo clippy --locked --all-targets -- -D warnings
cargo fmt --check
```

Unit tests are in `<file>_test.rs` next to the file they test. Integration
tests are modules of one test binary, `tests/it/main.rs`; they start private
tmux servers and need `tmux` 3.3 or later.

CI (`.github/workflows/ci.yml`): fmt and clippy on Linux; build and test on
Linux x86_64 and aarch64, and macOS aarch64.
