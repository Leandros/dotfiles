use super::*;

fn strings(args: &[&str]) -> Vec<String> {
    args.iter().map(|&arg| arg.to_owned()).collect()
}

#[test]
fn normal_mode_uses_cursor() {
    let state = parse_state("80\t24\t\t\t3\t5\t\t\n").unwrap();

    assert_eq!(
        state,
        PaneState {
            width: 80,
            height: 24,
            mode: PaneMode::Normal,
            scroll: 0,
            cursor: Point { row: 5, col: 3 },
        }
    );
}

#[test]
fn copy_mode_uses_copy_cursor() {
    let state = parse_state("80\t24\tcopy-mode\t7\t3\t5\t10\t2\n").unwrap();

    assert_eq!(state.mode, PaneMode::Copy);
    assert_eq!(state.scroll, 7);
    assert_eq!(state.cursor, Point { row: 2, col: 10 });
}

#[test]
fn other_modes_count_as_normal() {
    let state = parse_state("80\t24\ttree-mode\t\t3\t5\t\t\n").unwrap();

    assert_eq!(state.mode, PaneMode::Normal);
}

#[test]
fn bad_state_is_an_error() {
    assert!(parse_state("80\n").is_err());
    assert!(parse_state("x\t24\t\t\t3\t5\t\t\n").is_err());
}

#[test]
fn size_is_width_and_height() {
    assert_eq!(parse_size("80\t24\n").unwrap(), (80, 24));
    assert!(parse_size("80\n").is_err());
}

#[test]
fn capture_normal_mode() {
    let state = parse_state("80\t9\t\t\t0\t0\t\t\n").unwrap();

    assert_eq!(
        capture_args("%1", &state),
        strings(&["capture-pane", "-p", "-t", "%1"])
    );
}

#[test]
fn capture_scrolled_view() {
    let near = parse_state("80\t9\tcopy-mode\t7\t0\t0\t0\t0\n").unwrap();
    let far = parse_state("80\t9\tcopy-mode\t20\t0\t0\t0\t0\n").unwrap();

    assert_eq!(
        capture_args("%1", &near),
        strings(&["capture-pane", "-p", "-t", "%1", "-S", "-7", "-E", "1"])
    );
    assert_eq!(
        capture_args("%1", &far),
        strings(&["capture-pane", "-p", "-t", "%1", "-S", "-20", "-E", "-12"])
    );
}

#[test]
fn jump_starts_copy_mode() {
    let target = Target { row: 2, index: 3 };

    assert_eq!(
        jump_args("%1", PaneMode::Normal, target),
        strings(&[
            "copy-mode",
            "-t",
            "%1",
            ";", //
            "send-keys",
            "-t",
            "%1",
            "-X",
            "top-line",
            ";", //
            "send-keys",
            "-t",
            "%1",
            "-X",
            "-N",
            "2",
            "cursor-down",
            ";", //
            "send-keys",
            "-t",
            "%1",
            "-X",
            "start-of-line",
            ";", //
            "send-keys",
            "-t",
            "%1",
            "-X",
            "-N",
            "3",
            "cursor-right",
        ])
    );
}

#[test]
fn jump_in_copy_mode_top_left() {
    let target = Target { row: 0, index: 0 };

    assert_eq!(
        jump_args("%1", PaneMode::Copy, target),
        strings(&[
            "send-keys",
            "-t",
            "%1",
            "-X",
            "top-line",
            ";", //
            "send-keys",
            "-t",
            "%1",
            "-X",
            "start-of-line",
        ])
    );
}

#[test]
fn popup_covers_the_pane() {
    assert_eq!(
        popup_args("/dev/pts/3", "%1", (80, 24), "cmd"),
        strings(&[
            "display-popup",
            "-B",
            "-E",
            "-c",
            "/dev/pts/3",
            "-t",
            "%1",
            "-x",
            "#{popup_pane_left}",
            "-y",
            "#{popup_pane_bottom}",
            "-w",
            "80",
            "-h",
            "24",
            "cmd",
        ])
    );
}

#[test]
fn message_args_per_kind() {
    assert_eq!(
        message_args("c", &Message::Prompt("a#b")),
        strings(&["display-message", "-c", "c", "-d", "0", "a##b"])
    );
    assert_eq!(
        message_args("c", &Message::Clear),
        strings(&["display-message", "-c", "c", "-d", "1", ""])
    );
    assert_eq!(
        message_args("c", &Message::Error("bad #1")),
        strings(&["display-message", "-c", "c", "bad ##1"])
    );
}

#[test]
fn quote_makes_one_shell_word() {
    assert_eq!(quote("/usr/bin/tmux-flash"), "'/usr/bin/tmux-flash'");
    assert_eq!(quote("it's"), r"'it'\''s'");
}
