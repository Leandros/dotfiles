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
}

impl Term {
    pub(crate) fn open() -> io::Result<Self> {
        terminal::enable_raw_mode()?;

        let mut out = io::stdout();
        execute!(out, Hide)?;

        Ok(Self { out })
    }

    /// Draws all rows in one write, so that the popup does not flicker.
    pub(crate) fn draw(&mut self, rows: &[Vec<Span>], theme: Theme) -> io::Result<()> {
        queue!(self.out, Clear(ClearType::All))?;

        for (row, spans) in rows.iter().enumerate() {
            let row = u16::try_from(row).map_err(io::Error::other)?;
            queue!(self.out, MoveTo(0, row))?;

            for span in spans {
                self.paint_span(span, theme)?;
            }
        }

        queue!(self.out, SetAttribute(Attribute::Reset), ResetColor)?;
        self.out.flush()
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

    fn paint_span(&mut self, span: &Span, theme: Theme) -> io::Result<()> {
        let look = theme.look(span.style);

        queue!(
            self.out,
            SetAttribute(Attribute::Reset),
            ResetColor,
            SetForegroundColor(color(look.fg))
        )?;
        if let Some(bg) = look.bg {
            queue!(self.out, SetBackgroundColor(color(bg)))?;
        }
        if look.weight == Weight::Bold {
            queue!(self.out, SetAttribute(Attribute::Bold))?;
        }

        queue!(self.out, Print(&span.text))
    }
}

impl Drop for Term {
    fn drop(&mut self) {
        // Nothing is left to report to when the terminal fails here.
        let _ = execute!(self.out, Show);
        let _ = terminal::disable_raw_mode();
    }
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
