//! The two runs of tmux-flash. The launcher opens a popup over the pane; the
//! popup runs tmux-flash again for the session.

use std::fmt;
use std::io::{self, Write};

use crate::flash::screen::Screen;
use crate::flash::session::{Session, Step};
use crate::paint::paint;
use crate::term::Term;
use crate::theme::Theme;
use crate::tmux::{self, Message, TmuxError};

pub(crate) const PANE_FLAG: &str = "--pane";
pub(crate) const CLIENT_FLAG: &str = "--client";
/// Runs the session; the launcher gives it to the popup.
pub(crate) const UI_FLAG: &str = "--ui";

const NAME: &str = env!("CARGO_PKG_NAME");
/// The flash.nvim default labels, used when `@flash-labels` is not set.
const DEFAULT_LABELS: &str = "asdfghjklqwertyuiopzxcvbnm";
const PROMPT: &str = "⚡";

/// The pane to jump in and the client that pressed the key.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Origin {
    pub(crate) pane: String,
    pub(crate) client: String,
}

#[derive(Debug)]
pub(crate) enum AppError {
    Tmux(TmuxError),
    Io(io::Error),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Tmux(error) => write!(f, "{error}"),
            Self::Io(error) => write!(f, "{error}"),
        }
    }
}

impl From<TmuxError> for AppError {
    fn from(error: TmuxError) -> Self {
        Self::Tmux(error)
    }
}

impl From<io::Error> for AppError {
    fn from(error: io::Error) -> Self {
        Self::Io(error)
    }
}

/// Opens the popup over the pane and waits until it closes.
pub(crate) fn launch(origin: &Origin) -> Result<(), AppError> {
    let size = tmux::pane_size(&origin.pane)?;
    let exe = std::env::current_exe()?;
    let command = format!(
        "{} {UI_FLAG} {PANE_FLAG} {} {CLIENT_FLAG} {}",
        tmux::quote(&exe.to_string_lossy()),
        tmux::quote(&origin.pane),
        tmux::quote(&origin.client),
    );

    tmux::open_popup(&origin.client, &origin.pane, size, &command)?;
    Ok(())
}

/// The session in the popup: draw, read a key, until a jump or an exit.
pub(crate) fn run_ui(origin: &Origin) -> Result<(), AppError> {
    let view = tmux::pane_view(&origin.pane)?;
    let state = view.state;
    // Without the option the colors are dark, as the tmux status line.
    let theme = Theme::from_option(&view.options.color_mode);
    let labels = labels_from(&view.options.labels);
    let screen = Screen::parse(&view.text, state.width, state.height);
    let mut session = Session::new(screen, state.cursor, &labels);

    let prompt = Prompt {
        client: &origin.client,
    };
    let mut term = Term::open()?;

    loop {
        term.draw(&paint(&session), theme)?;
        prompt.show(session.pattern())?;

        match session.step(term.read_key()?) {
            Step::Continue => {}
            Step::Exit => return Ok(()),
            Step::Jump(target) => {
                tmux::jump(&origin.pane, state.mode, target)?;
                return Ok(());
            }
        }
    }
}

/// In the message line of the client; to stderr when tmux cannot show it.
pub(crate) fn report(origin: &Origin, error: &AppError) {
    let text = format!("{NAME}: {error}");
    if tmux::message(&origin.client, &Message::Error(&text)).is_ok() {
        return;
    }

    // If stderr is gone, there is no other place to report to.
    let _ = writeln!(io::stderr(), "{text}");
}

/// The pattern in the message line. A prompt stays after the popup closes,
/// so it is cleared on every way out.
struct Prompt<'a> {
    client: &'a str,
}

impl Prompt<'_> {
    fn show(&self, pattern: &str) -> Result<(), TmuxError> {
        tmux::message(
            self.client,
            &Message::Prompt(&format!("{PROMPT} {pattern}")),
        )
    }
}

impl Drop for Prompt<'_> {
    fn drop(&mut self) {
        let _ = tmux::message(self.client, &Message::Clear);
    }
}

/// The labels of `@flash-labels`; the default when it is not set. Spaces
/// and control characters cannot be typed as a label.
fn labels_from(option: &str) -> String {
    let labels: String = option
        .chars()
        .filter(|c| !c.is_whitespace() && !c.is_control())
        .collect();
    if labels.is_empty() {
        return DEFAULT_LABELS.to_owned();
    }

    labels
}

#[cfg(test)]
#[path = "app_test.rs"]
mod test;
