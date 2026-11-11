//! The popup terminal. This is the only module that reads keys or writes
//! escape sequences.

use std::io::{self, Stdout, Write};

use crossterm::cursor::{Hide, MoveTo, Show};
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use crossterm::style::{
    Attribute, Color, Print, ResetColor, SetAttribute, SetBackgroundColor, SetForegroundColor,
};
use crossterm::terminal::{self, Clear, ClearType};
use crossterm::{execute, queue};

use crate::flash::session::Key;
use crate::paint::Span;
use crate::theme::{Rgb, Theme, Weight};

/// The terminal in raw mode with a hidden cursor, until it is dropped.
#[derive(Debug)]
pub(crate) struct Term {
    out: Stdout,
    /// The rows on the screen now: a new frame writes only the rows that
    /// changed.
    shown: Vec<Vec<Span>>,
}

impl Term {
    pub(crate) fn open() -> io::Result<Self> {
        terminal::enable_raw_mode()?;

        let mut out = io::stdout();
        execute!(out, Hide)?;

        Ok(Self {
            out,
            shown: Vec::new(),
        })
    }

    /// Writes the rows that changed, in one write. A clear of the whole
    /// screen before each frame showed an empty popup for a moment: with fast
    /// typing the pane flickered.
    pub(crate) fn draw(&mut self, rows: &[Vec<Span>], theme: Theme) -> io::Result<()> {
        let bytes = frame_bytes(&self.shown, rows, theme)?;
        if bytes.is_empty() {
            return Ok(());
        }

        self.out.write_all(&bytes)?;
        self.out.flush()?;
        self.shown = rows.to_vec();

        Ok(())
    }

    /// Keys arrive one by one only in the raw mode that `Term` holds.
    #[expect(clippy::unused_self, reason = "reading needs the raw mode of self")]
    pub(crate) fn read_key(&self) -> io::Result<Key> {
        loop {
            let Event::Key(event) = event::read()? else {
                continue;
            };
            if let Some(key) = map_key(event) {
                return Ok(key);
            }
        }
    }
}

impl Drop for Term {
    fn drop(&mut self) {
        // Nothing is left to report to when the terminal fails here.
        let _ = execute!(self.out, Show);
        let _ = terminal::disable_raw_mode();
    }
}

/// The escape sequences that turn the `previous` frame into the `next` one;
/// empty when they are the same.
fn frame_bytes(previous: &[Vec<Span>], next: &[Vec<Span>], theme: Theme) -> io::Result<Vec<u8>> {
    let mut out = Vec::new();

    for (row, spans) in next.iter().enumerate() {
        if previous.get(row) == Some(spans) {
            continue;
        }

        let row = u16::try_from(row).map_err(io::Error::other)?;
        queue!(out, MoveTo(0, row))?;
        for span in spans {
            paint_span(&mut out, span, theme)?;
        }

        // The old row can be longer than the new one.
        queue!(
            out,
            SetAttribute(Attribute::Reset),
            ResetColor,
            Clear(ClearType::UntilNewLine)
        )?;
    }

    Ok(out)
}

fn paint_span(out: &mut Vec<u8>, span: &Span, theme: Theme) -> io::Result<()> {
    let look = theme.look(span.style);

    queue!(
        out,
        SetAttribute(Attribute::Reset),
        ResetColor,
        SetForegroundColor(color(look.fg))
    )?;
    if let Some(bg) = look.bg {
        queue!(out, SetBackgroundColor(color(bg)))?;
    }
    if look.weight == Weight::Bold {
        queue!(out, SetAttribute(Attribute::Bold))?;
    }

    queue!(out, Print(&span.text))
}

const fn color(rgb: Rgb) -> Color {
    Color::Rgb {
        r: rgb.0,
        g: rgb.1,
        b: rgb.2,
    }
}

/// The session key for a terminal key, if it has one.
fn map_key(event: KeyEvent) -> Option<Key> {
    if event.kind != KeyEventKind::Press {
        return None;
    }

    let control = event.modifiers.contains(KeyModifiers::CONTROL);
    let alt = event.modifiers.contains(KeyModifiers::ALT);

    match event.code {
        KeyCode::Esc => Some(Key::Cancel),
        KeyCode::Enter => Some(Key::Enter),
        KeyCode::Backspace => Some(Key::Backspace),
        KeyCode::Char('c') if control => Some(Key::Cancel),
        KeyCode::Char(c) if !control && !alt => Some(Key::Char(c)),
        _ => None,
    }
}

#[cfg(test)]
#[path = "term_test.rs"]
mod test;
