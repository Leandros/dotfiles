use super::*;

fn cells(screen: &Screen, row: usize) -> Vec<(&str, usize, usize)> {
    screen.lines()[row]
        .cells()
        .iter()
        .map(|cell| (cell.text(), cell.col(), cell.width()))
        .collect()
}

#[test]
fn ascii_takes_one_column() {
    let screen = Screen::parse("ab\n", 10, 1);

    assert_eq!(cells(&screen, 0), [("a", 0, 1), ("b", 1, 1)]);
}

#[test]
fn wide_takes_two_columns() {
    let screen = Screen::parse("漢a\n", 10, 1);

    assert_eq!(cells(&screen, 0), [("漢", 0, 2), ("a", 2, 1)]);
}

#[test]
fn combining_mark_joins_its_base() {
    let screen = Screen::parse("e\u{301}x\n", 10, 1);

    assert_eq!(cells(&screen, 0), [("e\u{301}", 0, 1), ("x", 1, 1)]);
}

#[test]
fn zwj_sequence_is_one_cell() {
    let screen = Screen::parse("👨\u{200d}👩\u{200d}👧x\n", 10, 1);

    assert_eq!(cells(&screen, 0)[1], ("x", 2, 1));
}

#[test]
fn flag_is_one_cell() {
    let screen = Screen::parse("🇩🇪x\n", 10, 1);

    assert_eq!(cells(&screen, 0)[1], ("x", 2, 1));
}

#[test]
fn missing_rows_are_empty() {
    let screen = Screen::parse("a\nb\n", 10, 3);

    assert_eq!(screen.lines().len(), 3);
    assert_eq!(screen.lines()[2].cells(), []);
}

#[test]
fn rows_past_height_dropped() {
    let screen = Screen::parse("a\nb\nc\n", 10, 2);

    assert_eq!(screen.lines().len(), 2);
    assert_eq!(cells(&screen, 1), [("b", 0, 1)]);
}

#[test]
fn last_row_without_newline() {
    let screen = Screen::parse("a\nb", 10, 2);

    assert_eq!(cells(&screen, 1), [("b", 0, 1)]);
}

#[test]
fn width_is_kept() {
    let screen = Screen::parse("", 7, 3);

    assert_eq!(screen.width(), 7);
}
