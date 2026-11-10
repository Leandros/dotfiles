//! The captured pane text as rows of grapheme clusters with cell columns.

use unicode_segmentation::UnicodeSegmentation;
use unicode_width::UnicodeWidthStr;

/// A cell position: row and column of the pane.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct Point {
    pub(crate) row: usize,
    pub(crate) col: usize,
}

/// One grapheme cluster and the columns it takes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Cell {
    text: String,
    col: usize,
    width: usize,
}

impl Cell {
    pub(crate) fn text(&self) -> &str {
        &self.text
    }

    pub(crate) const fn col(&self) -> usize {
        self.col
    }

    pub(crate) const fn width(&self) -> usize {
        self.width
    }
}

/// One row of the pane.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub(crate) struct Line {
    cells: Vec<Cell>,
}

impl Line {
    pub(crate) fn cells(&self) -> &[Cell] {
        &self.cells
    }
}

/// The visible rows of the pane.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Screen {
    lines: Vec<Line>,
    width: usize,
}

impl Screen {
    /// `height` rows: rows past it are dropped, missing rows are empty.
    pub(crate) fn parse(text: &str, width: usize, height: usize) -> Self {
        // capture-pane ends each row with a newline, the last one too.
        let text = text.strip_suffix('\n').unwrap_or(text);

        let mut lines: Vec<Line> = text.split('\n').take(height).map(parse_line).collect();
        lines.resize(height, Line::default());

        Self { lines, width }
    }

    pub(crate) fn lines(&self) -> &[Line] {
        &self.lines
    }

    pub(crate) const fn width(&self) -> usize {
        self.width
    }
}

fn parse_line(text: &str) -> Line {
    let mut col = 0;
    let mut cells = Vec::new();

    for grapheme in text.graphemes(true) {
        // tmux gives every cell at least one column; a zero width cluster
        // that stood alone would otherwise share a column with the next one.
        let width = grapheme.width().max(1);
        cells.push(Cell {
            text: grapheme.to_owned(),
            col,
            width,
        });
        col += width;
    }

    Line { cells }
}

#[cfg(test)]
#[path = "screen_test.rs"]
mod test;
