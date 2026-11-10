use super::*;
use crate::flash::screen::{Point, Screen};
use crate::flash::session::Key;

const LABELS: &str = "ctieobnrsgjduaxphlmwfvyz";
const TOP_LEFT: Point = Point { row: 0, col: 0 };

fn session(text: &str, width: usize, typed: &str) -> Session {
    let height = text.lines().count().max(1);
    let screen = Screen::parse(text, width, height);
    let mut session = Session::new(screen, TOP_LEFT, LABELS);

    for key in typed.chars() {
        let _ = session.step(Key::Char(key));
    }
    session
}

fn span(text: &str, style: Style) -> Span {
    Span {
        text: text.to_owned(),
        style,
    }
}

#[test]
fn no_pattern_is_backdrop() {
    let rows = paint(&session("ab cd\nef\n", 10, ""));

    assert_eq!(
        rows,
        [
            vec![span("ab cd", Style::Backdrop)],
            vec![span("ef", Style::Backdrop)]
        ]
    );
}

#[test]
fn label_covers_next_cluster() {
    // Cursor at 0,0: the next match is the second one, the current match.
    let rows = paint(&session("ax ay\n", 10, "a"));

    assert_eq!(
        rows[0],
        [
            span("a", Style::Match),
            span("c", Style::Label),
            span(" ", Style::Backdrop),
            span("a", Style::Current),
            span("t", Style::Label),
        ]
    );
}

#[test]
fn label_after_text_end() {
    let rows = paint(&session("xx ab\n", 10, "ab"));

    assert_eq!(
        rows[0],
        [
            span("xx ", Style::Backdrop),
            span("ab", Style::Current),
            span("c", Style::Label),
        ]
    );
}

#[test]
fn label_at_right_edge() {
    let rows = paint(&session("xx ab\n", 5, "ab"));

    assert_eq!(
        rows[0],
        [
            span("xx ", Style::Backdrop),
            span("a", Style::Current),
            span("c", Style::Label),
        ]
    );
}

#[test]
fn label_on_wide_cluster() {
    let rows = paint(&session("a漢x\n", 10, "a"));

    assert_eq!(
        rows[0],
        [
            span("a", Style::Current),
            span("c ", Style::Label),
            span("x", Style::Backdrop),
        ]
    );
}

#[test]
fn unlabeled_match_highlighted() {
    let screen = Screen::parse("x x x\n", 10, 1);
    let mut s = Session::new(screen, TOP_LEFT, "c");
    let _ = s.step(Key::Char('x'));

    let rows = paint(&s);

    assert_eq!(
        rows[0],
        [
            span("x", Style::Match),
            span("c", Style::Label),
            span("x", Style::Current),
            span("C", Style::Label),
            span("x", Style::Match),
        ]
    );
}
