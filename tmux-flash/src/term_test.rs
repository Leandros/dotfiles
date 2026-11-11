use super::*;
use crate::paint::Style;

fn key(code: KeyCode, modifiers: KeyModifiers) -> Option<Key> {
    map_key(KeyEvent::new(code, modifiers))
}

#[test]
fn characters_are_keys() {
    assert_eq!(
        key(KeyCode::Char('a'), KeyModifiers::NONE),
        Some(Key::Char('a'))
    );
    assert_eq!(
        key(KeyCode::Char('P'), KeyModifiers::SHIFT),
        Some(Key::Char('P'))
    );
    assert_eq!(
        key(KeyCode::Char('é'), KeyModifiers::NONE),
        Some(Key::Char('é'))
    );
}

#[test]
fn enter_and_backspace() {
    assert_eq!(key(KeyCode::Enter, KeyModifiers::NONE), Some(Key::Enter));
    assert_eq!(
        key(KeyCode::Backspace, KeyModifiers::NONE),
        Some(Key::Backspace)
    );
}

#[test]
fn escape_and_ctrl_c_cancel() {
    assert_eq!(key(KeyCode::Esc, KeyModifiers::NONE), Some(Key::Cancel));
    assert_eq!(
        key(KeyCode::Char('c'), KeyModifiers::CONTROL),
        Some(Key::Cancel)
    );
}

#[test]
fn other_control_keys_do_nothing() {
    assert_eq!(key(KeyCode::Char('g'), KeyModifiers::CONTROL), None);
    assert_eq!(key(KeyCode::Char('x'), KeyModifiers::ALT), None);
    assert_eq!(key(KeyCode::Up, KeyModifiers::NONE), None);
    assert_eq!(key(KeyCode::Tab, KeyModifiers::NONE), None);
}

#[test]
fn key_release_does_nothing() {
    let mut event = KeyEvent::new(KeyCode::Char('a'), KeyModifiers::NONE);
    event.kind = KeyEventKind::Release;

    assert_eq!(map_key(event), None);
}

/// Clears the whole screen: a frame after it shows a blank popup for a moment.
const CLEAR_ALL: &str = "\x1b[2J";

fn rows(texts: &[&str]) -> Vec<Vec<Span>> {
    texts
        .iter()
        .map(|&text| {
            vec![Span {
                text: text.to_owned(),
                style: Style::Backdrop,
            }]
        })
        .collect()
}

fn bytes(previous: &[Vec<Span>], next: &[Vec<Span>]) -> String {
    String::from_utf8(frame_bytes(previous, next, Theme::Dark).unwrap()).unwrap()
}

#[test]
fn first_frame_draws_every_row() {
    let out = bytes(&[], &rows(&["alpha", "beta"]));

    assert!(out.contains("alpha") && out.contains("beta"));
    assert!(!out.contains(CLEAR_ALL));
}

#[test]
fn same_frame_draws_nothing() {
    let frame = rows(&["alpha", "beta"]);

    assert_eq!(bytes(&frame, &frame), "");
}

#[test]
fn only_changed_rows_are_drawn() {
    let out = bytes(&rows(&["alpha", "beta"]), &rows(&["alpha", "bet"]));

    assert!(out.contains("bet"));
    assert!(!out.contains("alpha"));
    assert!(!out.contains(CLEAR_ALL));
}

#[test]
fn changed_row_clears_old_end() {
    let out = bytes(&rows(&["alpha"]), &rows(&["al"]));

    // Erase to the end of the line: "pha" of the old row goes.
    assert!(out.contains("\x1b[K"));
}
