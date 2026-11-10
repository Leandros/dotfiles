use super::*;

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
