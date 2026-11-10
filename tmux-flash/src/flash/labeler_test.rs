use super::*;
use crate::flash::matcher::find_matches;
use crate::flash::screen::Screen;

const WIDTH: usize = 40;

fn at(row: usize, col: usize) -> Point {
    Point { row, col }
}

fn matches(text: &str, pattern: &str) -> Vec<Match> {
    let height = text.lines().count().max(1);
    find_matches(&Screen::parse(text, WIDTH, height), pattern)
}

fn label(labels: &str, text: &str, pattern: &str, cursor: Point) -> Vec<Option<char>> {
    Labeler::new(labels).assign(&matches(text, pattern), cursor, WIDTH)
}

#[test]
fn pool_lower_then_upper() {
    assert_eq!(
        label("ab", "x x x x x\n", "x", at(0, 0)),
        [Some('a'), Some('b'), Some('A'), Some('B'), None]
    );
}

#[test]
fn pool_drops_duplicates() {
    assert_eq!(
        label("aab", "x x x\n", "x", at(0, 0)),
        [Some('a'), Some('b'), Some('A')]
    );
}

#[test]
fn skips_both_cases_of_next() {
    // Next after the matches: "b" and "C". Left: a, d, A, D.
    assert_eq!(
        label("abcd", "ab aC\n", "a", at(0, 0)),
        [Some('a'), Some('d')]
    );
}

#[test]
fn nearest_gets_first_label() {
    assert_eq!(
        label("cd", "al xxxxxxxxx al\n", "al", at(0, 14)),
        [Some('d'), Some('c')]
    );
}

#[test]
fn tie_keeps_reading_order() {
    assert_eq!(
        label("cd", "al xx al\n", "al", at(0, 3)),
        [Some('c'), Some('d')]
    );
}

#[test]
fn distance_counts_whole_rows() {
    // Row 0 col 10 is 10 cells away, row 1 col 0 is WIDTH cells away.
    assert_eq!(
        label("cd", "xxxxxxxxxxal\nal\n", "al", at(0, 0)),
        [Some('c'), Some('d')]
    );
}

#[test]
fn lowercase_label_stays() {
    let found = matches("al al\n", "al");
    let mut labeler = Labeler::new("cd");

    let first = labeler.assign(&found, at(0, 4), WIDTH);
    let second = labeler.assign(&found, at(0, 0), WIDTH);

    assert_eq!(first, [Some('d'), Some('c')]);
    assert_eq!(second, first);
}

#[test]
fn uppercase_label_does_not_stay() {
    let found = matches("x x x\n", "x");
    let mut labeler = Labeler::new("a");

    let first = labeler.assign(&found, at(0, 4), WIDTH);
    let second = labeler.assign(&found, at(0, 0), WIDTH);

    assert_eq!(first, [None, Some('A'), Some('a')]);
    assert_eq!(second, [Some('A'), None, Some('a')]);
}

#[test]
fn kept_label_goes_if_continued() {
    let mut labeler = Labeler::new("bc");

    let first = labeler.assign(&matches("ax ay\n", "a"), at(0, 4), WIDTH);

    // Now "b" follows the first match: b and B are skipped.
    let second = labeler.assign(&matches("ab ay\n", "a"), at(0, 4), WIDTH);

    assert_eq!(first, [Some('c'), Some('b')]);
    assert_eq!(second, [Some('c'), Some('C')]);
}

#[test]
fn no_matches_no_labels() {
    assert_eq!(label("ab", "x\n", "z", at(0, 0)), []);
}
