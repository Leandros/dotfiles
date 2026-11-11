//! The tmux program. This is the only module that starts processes.

use std::ffi::OsStr;
use std::fmt;
use std::io;
use std::process::Command;

use crate::flash::screen::Point;
use crate::flash::session::Target;

const TMUX: &str = "tmux";
/// Without a UTF-8 locale (cron, containers, a bare run-shell), tmux turns
/// tabs and non-ASCII text in its output into `_`; -u keeps them.
const UTF8: &str = "-u";
/// `pane_mode` of a pane in copy mode.
const COPY_MODE: &str = "copy-mode";
/// Separates tmux commands in one call.
const SEPARATOR: &str = ";";
const FIELD: char = '\t';
const SIZE_FORMAT: &str = "#{pane_width}\t#{pane_height}";
/// The user options of tmux-flash come with the state: no extra tmux call.
const STATE_FORMAT: &str = "#{pane_width}\t#{pane_height}\t#{pane_mode}\t#{scroll_position}\t\
                            #{cursor_x}\t#{cursor_y}\t#{copy_cursor_x}\t#{copy_cursor_y}\t\
                            #{@color-mode}\t#{@flash-labels}";
/// `display-message -d`: 0 keeps the message until the next one, 1
/// removes it at once.
const UNTIL_CLEARED: &str = "0";
const AT_ONCE: &str = "1";

/// Whether the pane shows copy mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum PaneMode {
    Normal,
    Copy,
}

/// Size, mode and cursor of the target pane.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct PaneState {
    pub(crate) width: usize,
    pub(crate) height: usize,
    pub(crate) mode: PaneMode,
    /// Rows the copy mode view is scrolled up.
    pub(crate) scroll: usize,
    pub(crate) cursor: Point,
}

/// The user options `@color-mode` and `@flash-labels`, empty when not set.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub(crate) struct Options {
    pub(crate) color_mode: String,
    pub(crate) labels: String,
}

/// The target pane: its state, the options and the text of its visible rows.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct PaneView {
    pub(crate) state: PaneState,
    pub(crate) options: Options,
    pub(crate) text: String,
}

/// A text in the tmux message line.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Message<'a> {
    /// Stays until it is cleared.
    Prompt(&'a str),
    Clear,
    /// Stays for the tmux `display-time`.
    Error(&'a str),
}

#[derive(Debug)]
pub(crate) enum TmuxError {
    Start(io::Error),
    Failed(String),
    Output(String),
}

impl fmt::Display for TmuxError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Start(error) => write!(f, "cannot start tmux: {error}"),
            Self::Failed(stderr) => write!(f, "tmux failed: {}", stderr.trim()),
            Self::Output(text) => write!(f, "unexpected tmux output: {}", text.trim()),
        }
    }
}

/// Width and height of the pane.
pub(crate) fn pane_size(pane: &str) -> Result<(usize, usize), TmuxError> {
    let text = run(&["display-message", "-p", "-t", pane, SIZE_FORMAT])?;

    parse_size(&text)
}

/// Runs `command` in a popup over the pane and waits until it closes.
pub(crate) fn open_popup(
    client: &str,
    pane: &str,
    size: (usize, usize),
    command: &str,
) -> Result<(), TmuxError> {
    let _ = run(&popup_args(client, pane, size, command))?;

    Ok(())
}

/// The state of the pane, the options and the text of its visible rows.
pub(crate) fn pane_view(pane: &str) -> Result<PaneView, TmuxError> {
    let (state, options) =
        parse_state(&run(&["display-message", "-p", "-t", pane, STATE_FORMAT])?)?;
    let text = run(&capture_args(pane, &state))?;

    Ok(PaneView {
        state,
        options,
        text,
    })
}

/// Puts the pane in copy mode with the cursor on the target.
pub(crate) fn jump(pane: &str, mode: PaneMode, target: Target) -> Result<(), TmuxError> {
    let _ = run(&jump_args(pane, mode, target))?;

    Ok(())
}

pub(crate) fn message(client: &str, message: &Message<'_>) -> Result<(), TmuxError> {
    let _ = run(&message_args(client, message))?;

    Ok(())
}

/// One shell word, for the command that the popup runs.
pub(crate) fn quote(text: &str) -> String {
    format!("'{}'", text.replace('\'', r"'\''"))
}

fn run<S: AsRef<OsStr>>(args: &[S]) -> Result<String, TmuxError> {
    let output = Command::new(TMUX)
        .arg(UTF8)
        .args(args)
        .output()
        .map_err(TmuxError::Start)?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).into_owned();
        return Err(TmuxError::Failed(stderr));
    }

    Ok(String::from_utf8_lossy(&output.stdout).into_owned())
}

fn parse_size(text: &str) -> Result<(usize, usize), TmuxError> {
    let fields: Vec<&str> = text.trim_end_matches('\n').split(FIELD).collect();
    let [width, height] = fields.as_slice() else {
        return Err(TmuxError::Output(text.to_owned()));
    };

    Ok((number(width, text)?, number(height, text)?))
}

fn parse_state(text: &str) -> Result<(PaneState, Options), TmuxError> {
    let fields: Vec<&str> = text.trim_end_matches('\n').split(FIELD).collect();
    let [
        width,
        height,
        mode,
        scroll,
        x,
        y,
        copy_x,
        copy_y,
        color_mode,
        labels,
    ] = fields.as_slice()
    else {
        return Err(TmuxError::Output(text.to_owned()));
    };

    let mode = if *mode == COPY_MODE {
        PaneMode::Copy
    } else {
        PaneMode::Normal
    };
    let (x, y) = match mode {
        PaneMode::Normal => (x, y),
        PaneMode::Copy => (copy_x, copy_y),
    };
    let scroll = if scroll.is_empty() {
        0
    } else {
        number(scroll, text)?
    };

    let state = PaneState {
        width: number(width, text)?,
        height: number(height, text)?,
        mode,
        scroll,
        cursor: Point {
            row: number(y, text)?,
            col: number(x, text)?,
        },
    };
    let options = Options {
        color_mode: (*color_mode).to_owned(),
        labels: (*labels).to_owned(),
    };

    Ok((state, options))
}

fn number(field: &str, text: &str) -> Result<usize, TmuxError> {
    field
        .parse()
        .map_err(|_| TmuxError::Output(text.to_owned()))
}

fn capture_args(pane: &str, state: &PaneState) -> Vec<String> {
    let mut args = strings(["capture-pane", "-p", "-t", pane]);
    if state.mode == PaneMode::Normal || state.scroll == 0 {
        return args;
    }

    // Rows count from the bottom of the history: the view starts `scroll`
    // rows up.
    let last = state.height.saturating_sub(1);
    let end = if last >= state.scroll {
        (last - state.scroll).to_string()
    } else {
        format!("-{}", state.scroll - last)
    };

    args.extend([
        "-S".to_owned(),
        format!("-{}", state.scroll),
        "-E".to_owned(),
        end,
    ]);
    args
}

fn jump_args(pane: &str, mode: PaneMode, target: Target) -> Vec<String> {
    let mut commands = Vec::new();

    if mode == PaneMode::Normal {
        commands.push(strings(["copy-mode", "-t", pane]));
    }

    commands.push(copy_command(pane, "top-line", None));
    if target.row > 0 {
        commands.push(copy_command(pane, "cursor-down", Some(target.row)));
    }

    commands.push(copy_command(pane, "start-of-line", None));
    if target.index > 0 {
        commands.push(copy_command(pane, "cursor-right", Some(target.index)));
    }

    commands.join(&SEPARATOR.to_owned())
}

fn copy_command(pane: &str, command: &str, repeat: Option<usize>) -> Vec<String> {
    let mut args = strings(["send-keys", "-t", pane, "-X"]);
    if let Some(count) = repeat {
        args.extend(["-N".to_owned(), count.to_string()]);
    }

    args.push(command.to_owned());
    args
}

fn popup_args(client: &str, pane: &str, size: (usize, usize), command: &str) -> Vec<String> {
    let (width, height) = (size.0.to_string(), size.1.to_string());

    // -x and -y take formats, -w and -h do not ("height invalid").
    strings([
        "display-popup",
        "-B",
        "-E",
        "-c",
        client,
        "-t",
        pane,
        "-x",
        "#{popup_pane_left}",
        "-y",
        "#{popup_pane_bottom}",
        "-w",
        &width,
        "-h",
        &height,
        command,
    ])
}

fn message_args(client: &str, message: &Message<'_>) -> Vec<String> {
    let mut args = strings(["display-message", "-c", client]);

    match message {
        Message::Prompt(text) => {
            args.extend(["-d".to_owned(), UNTIL_CLEARED.to_owned(), escape(text)]);
        }
        Message::Clear => args.extend(["-d".to_owned(), AT_ONCE.to_owned(), String::new()]),
        Message::Error(text) => args.push(escape(text)),
    }

    args
}

/// display-message expands formats; `##` is a literal `#`.
fn escape(text: &str) -> String {
    text.replace('#', "##")
}

fn strings<const N: usize>(args: [&str; N]) -> Vec<String> {
    args.iter().map(|&arg| arg.to_owned()).collect()
}

#[cfg(test)]
#[path = "tmux_test.rs"]
mod test;
