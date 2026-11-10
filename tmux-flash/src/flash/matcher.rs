//! Exact search of the pattern in the screen rows, with smart case.

use unicode_segmentation::UnicodeSegmentation;

use super::screen::Screen;

/// A match: its start, its length in grapheme clusters, and the cluster that
/// follows it on the same row.
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Match {
    row: usize,
    index: usize,
    col: usize,
    len: usize,
    next: Option<String>,
}

impl Match {
    pub(crate) const fn row(&self) -> usize {
        self.row
    }

    /// Grapheme clusters before the match on its row.
    pub(crate) const fn index(&self) -> usize {
        self.index
    }

    /// Cell column of the first cluster.
    pub(crate) const fn col(&self) -> usize {
        self.col
    }

    pub(crate) const fn len(&self) -> usize {
        self.len
    }

    pub(crate) fn next(&self) -> Option<&str> {
        self.next.as_deref()
    }
}

/// All matches in reading order, overlapping ones too. A pattern without
/// uppercase letters ignores case, as `ignorecase` and `smartcase` in the
/// user's nvim.
pub(crate) fn find_matches(screen: &Screen, pattern: &str) -> Vec<Match> {
    let needle: Vec<&str> = pattern.graphemes(true).collect();
    if needle.is_empty() {
        return Vec::new();
    }

    let compare = if pattern.chars().any(char::is_uppercase) {
        Compare::Exact
    } else {
        Compare::Folded
    };
    let mut matches = Vec::new();

    for (row, line) in screen.lines().iter().enumerate() {
        let cells = line.cells();

        for (index, window) in cells.windows(needle.len()).enumerate() {
            let found = window
                .iter()
                .zip(&needle)
                .all(|(cell, part)| compare.same(cell.text(), part));
            if !found {
                continue;
            }
            let Some(first) = window.first() else {
                continue;
            };

            matches.push(Match {
                row,
                index,
                col: first.col(),
                len: needle.len(),
                next: cells
                    .get(index + needle.len())
                    .map(|cell| cell.text().to_owned()),
            });
        }
    }

    matches
}

/// How a screen cluster compares to a pattern cluster.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Compare {
    Exact,
    Folded,
}

impl Compare {
    fn same(self, text: &str, part: &str) -> bool {
        match self {
            Self::Exact => text == part,
            Self::Folded => text == part || text.to_lowercase() == part.to_lowercase(),
        }
    }
}

#[cfg(test)]
#[path = "matcher_test.rs"]
mod test;
