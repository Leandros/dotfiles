use super::*;

const WIDTH: usize = 40;

fn find(text: &str, pattern: &str) -> Vec<(usize, usize, usize)> {
    let height = text.lines().count().max(1);
    let screen = Screen::parse(text, WIDTH, height);

    find_matches(&screen, pattern)
        .iter()
        .map(|m| (m.row(), m.index(), m.len()))
        .collect()
}

#[test]
fn finds_in_reading_order() {
    assert_eq!(find("alpha beta\nalpine\n", "al"), [(0, 0, 2), (1, 0, 2)]);
}

#[test]
fn finds_overlapping_matches() {
    assert_eq!(find("aaa\n", "aa"), [(0, 0, 2), (0, 1, 2)]);
}

#[test]
fn lowercase_ignores_case() {
    assert_eq!(find("Alpha alpha\n", "al"), [(0, 0, 2), (0, 6, 2)]);
}

#[test]
fn uppercase_pattern_is_exact() {
    assert_eq!(find("Alpha alpha\n", "Al"), [(0, 0, 2)]);
}

#[test]
fn empty_pattern_has_no_match() {
    assert_eq!(find("alpha\n", ""), []);
}

#[test]
fn no_match_across_rows() {
    assert_eq!(find("a\nb\n", "ab"), []);
}

#[test]
fn cell_column_after_wide_text() {
    let screen = Screen::parse("漢字 alpha\n", WIDTH, 1);
    let matches = find_matches(&screen, "al");

    assert_eq!(matches.len(), 1);
    assert_eq!((matches[0].index(), matches[0].col()), (3, 5));
}

#[test]
fn wide_pattern_matches() {
    assert_eq!(find("x漢字y\n", "漢字"), [(0, 1, 2)]);
}

#[test]
fn next_is_the_cluster_after() {
    let screen = Screen::parse("alpha al\n", WIDTH, 1);
    let matches = find_matches(&screen, "al");

    assert_eq!(matches[0].next(), Some("p"));
    assert_eq!(matches[1].next(), None);
}
