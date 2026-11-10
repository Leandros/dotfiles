//! Labels for the matches, by the rules of the flash.nvim labeler.

use std::collections::HashMap;

use super::matcher::Match;
use super::screen::Point;

/// Gives labels to matches and keeps lowercase labels on their positions
/// while the pattern changes.
#[derive(Debug)]
pub(crate) struct Labeler {
    pool: Vec<char>,
    kept: HashMap<(usize, usize), char>,
}

impl Labeler {
    /// The pool is `labels`, then the same letters in uppercase.
    pub(crate) fn new(labels: &str) -> Self {
        let upper = labels.chars().flat_map(char::to_uppercase);
        let mut pool = Vec::new();

        for label in labels.chars().chain(upper) {
            if !pool.contains(&label) {
                pool.push(label);
            }
        }

        Self {
            pool,
            kept: HashMap::new(),
        }
    }

    /// One label or none per match, in the order of `matches`.
    pub(crate) fn assign(
        &mut self,
        matches: &[Match],
        cursor: Point,
        width: usize,
    ) -> Vec<Option<char>> {
        let mut free = self.usable(matches);
        let order = by_distance(matches, cursor, width);
        let mut labels = vec![None; matches.len()];

        // First the labels that stay on their positions, as in flash.nvim.
        for &(index, found) in &order {
            let Some(&label) = self.kept.get(&position(found)) else {
                continue;
            };
            if !free.contains(&label) {
                continue;
            }

            free.retain(|&other| other != label);
            self.give(&mut labels, index, found, label);
        }

        for &(index, found) in &order {
            if labels.get(index).is_some_and(Option::is_some) {
                continue;
            }
            if free.is_empty() {
                break;
            }

            let label = free.remove(0);
            self.give(&mut labels, index, found, label);
        }

        labels
    }

    /// The pool without the labels that continue the pattern.
    fn usable(&self, matches: &[Match]) -> Vec<char> {
        let next: Vec<&str> = matches.iter().filter_map(Match::next).collect();

        self.pool
            .iter()
            .copied()
            .filter(|&label| !next.iter().any(|text| continues(label, text)))
            .collect()
    }

    fn give(&mut self, labels: &mut [Option<char>], index: usize, found: &Match, label: char) {
        if let Some(slot) = labels.get_mut(index) {
            *slot = Some(label);
        }

        // flash.nvim keeps only lowercase labels (reuse = "lowercase").
        if label.is_lowercase() {
            let _ = self.kept.insert(position(found), label);
        }
    }
}

const fn position(found: &Match) -> (usize, usize) {
    (found.row(), found.index())
}

/// Matches with their index, nearest to the cursor first. The sort is
/// stable: equal distances keep reading order.
fn by_distance(matches: &[Match], cursor: Point, width: usize) -> Vec<(usize, &Match)> {
    let origin = cursor.row * width + cursor.col;
    let mut order: Vec<(usize, &Match)> = matches.iter().enumerate().collect();

    order.sort_by_key(|(_, found)| (found.row() * width + found.col()).abs_diff(origin));

    order
}

/// True when typing `label` after a match could extend the pattern. Both
/// cases count: flash.nvim folds here with `ignorecase`, also when smart
/// case makes the search exact.
fn continues(label: char, next: &str) -> bool {
    let mut buffer = [0; 4];
    let label = label.encode_utf8(&mut buffer);

    next.to_lowercase() == label.to_lowercase()
}

#[cfg(test)]
#[path = "labeler_test.rs"]
mod test;
