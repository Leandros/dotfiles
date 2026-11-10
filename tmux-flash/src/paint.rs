//! The frame the popup shows: the pane text with backdrop, matches and
//! labels, as styled spans per row.

use crate::flash::matcher::Match;
use crate::flash::screen::{Line, Screen};
use crate::flash::session::Session;

/// How a span looks; `theme` gives the colors.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Style {
    Backdrop,
    Match,
    Current,
    Label,
}

/// Text of one style.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Span {
    pub(crate) text: String,
    pub(crate) style: Style,
}

/// One cell of the frame before spans of one style are joined.
type Painted = (String, Style);

/// One row of spans per screen row.
pub(crate) fn paint(session: &Session) -> Vec<Vec<Span>> {
    let screen = session.screen();
    let mut rows: Vec<Vec<Painted>> = screen.lines().iter().map(backdrop).collect();

    for (index, found) in session.matches().iter().enumerate() {
        let style = if session.current() == Some(index) {
            Style::Current
        } else {
            Style::Match
        };
        let Some(row) = rows.get_mut(found.row()) else {
            continue;
        };

        for cell in row.iter_mut().skip(found.index()).take(found.len()) {
            cell.1 = style;
        }
    }

    // Labels after the matches: a label covers a match that follows it.
    for (found, label) in session.matches().iter().zip(session.labels()) {
        let Some(label) = label else {
            continue;
        };
        let Some(row) = rows.get_mut(found.row()) else {
            continue;
        };

        put_label(row, screen, found, *label);
    }

    rows.into_iter().map(join).collect()
}

fn backdrop(line: &Line) -> Vec<Painted> {
    line.cells()
        .iter()
        .map(|cell| (cell.text().to_owned(), Style::Backdrop))
        .collect()
}

/// flash.nvim puts the label on the cluster after the match.
fn put_label(row: &mut Vec<Painted>, screen: &Screen, found: &Match, label: char) {
    let Some(line) = screen.lines().get(found.row()) else {
        return;
    };
    let cells = line.cells();
    let after = found.index() + found.len();

    if let Some(cell) = cells.get(after) {
        cover(row, after, label, cell.width());
        return;
    }

    let Some(last) = after.checked_sub(1) else {
        return;
    };
    let Some(last_cell) = cells.get(last) else {
        return;
    };

    // The match ends the text: the free column after it takes the label.
    if last_cell.col() + last_cell.width() < screen.width() {
        row.push((label.to_string(), Style::Label));
        return;
    }

    // At the right edge there is no free column.
    cover(row, last, label, last_cell.width());
}

/// Replace one cluster with the label; spaces fill the rest of its columns.
fn cover(row: &mut [Painted], index: usize, label: char, width: usize) {
    let Some(cell) = row.get_mut(index) else {
        return;
    };

    let fill = " ".repeat(width.saturating_sub(1));
    *cell = (format!("{label}{fill}"), Style::Label);
}

fn join(row: Vec<Painted>) -> Vec<Span> {
    let mut spans: Vec<Span> = Vec::new();

    for (text, style) in row {
        if let Some(span) = spans.last_mut()
            && span.style == style
        {
            span.text.push_str(&text);
            continue;
        }

        spans.push(Span { text, style });
    }

    spans
}

#[cfg(test)]
#[path = "paint_test.rs"]
mod test;
