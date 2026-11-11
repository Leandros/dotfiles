use super::*;

#[test]
fn unset_option_gives_default() {
    assert_eq!(labels_from(""), DEFAULT_LABELS);
    assert_eq!(DEFAULT_LABELS, "asdfghjklqwertyuiopzxcvbnm");
}

#[test]
fn blank_option_gives_default() {
    assert_eq!(labels_from("  \t"), DEFAULT_LABELS);
}

#[test]
fn option_gives_the_labels() {
    assert_eq!(labels_from("ctie"), "ctie");
}

#[test]
fn spaces_are_no_labels() {
    assert_eq!(labels_from(" c t\n"), "ct");
}
