//! tmux-flash in a popup over a pane of a private tmux server: keys go
//! through a client, the result is the copy mode cursor of the pane.

use std::fmt::Write;

use crate::harness::{PROMPT, Servers};

const TEXT: &str = "alpha beta alpine zulu\n";

#[test]
fn enter_jumps_to_the_typed_text() {
    let servers = Servers::start(TEXT);
    let mut flash = servers.flash();

    servers.type_text("alpi");
    servers.wait_for("the prompt", |s| s.prompt_is("alpi"));
    servers.press("Enter");

    assert!(servers.wait_exit(&mut flash));
    assert_eq!(servers.copy_cursor(), "copy-mode 11 0");
}

#[test]
fn label_jumps_to_its_match() {
    let servers = Servers::start(TEXT);
    let mut flash = servers.flash();

    // After "a" the labels go by distance from the cursor (row 1, col 0):
    // alpine c, beta t, alpha's last a i, alpha e. They stay after "al";
    // each one covers the cluster after its match.
    servers.type_text("al");
    servers.wait_for("the labels", |s| {
        s.screen().contains("aleha beta alcine zulu")
    });
    servers.type_text("e");

    assert!(servers.wait_exit(&mut flash));
    assert_eq!(servers.copy_cursor(), "copy-mode 0 0");
}

#[test]
fn escape_clears_the_prompt() {
    let servers = Servers::start(TEXT);
    let mut flash = servers.flash();

    servers.type_text("al");
    servers.wait_for("the prompt", |s| s.prompt_is("al"));
    servers.press("Escape");

    assert!(servers.wait_exit(&mut flash));
    assert_eq!(servers.copy_cursor(), "");
    servers.wait_for("no prompt", |s| !s.screen().contains(PROMPT));
}

#[test]
fn no_match_ends() {
    let servers = Servers::start(TEXT);
    let mut flash = servers.flash();

    servers.type_text("zq");

    assert!(servers.wait_exit(&mut flash));
    assert_eq!(servers.copy_cursor(), "");
}

#[test]
fn backspace_removes_last() {
    let servers = Servers::start(TEXT);
    let mut flash = servers.flash();

    servers.type_text("alpi");
    servers.wait_for("the prompt", |s| s.prompt_is("alpi"));
    servers.press("BSpace");
    servers.wait_for("the shorter prompt", |s| s.prompt_is("alp"));

    // h follows a match, so it is no label: it extends to "alph".
    servers.type_text("h");
    servers.wait_for("the prompt", |s| s.prompt_is("alph"));
    servers.press("Enter");

    assert!(servers.wait_exit(&mut flash));
    assert_eq!(servers.copy_cursor(), "copy-mode 0 0");
}

#[test]
fn wide_chars_before_target() {
    let servers = Servers::start("漢字 alpha\n");
    let mut flash = servers.flash();

    servers.type_text("alp");
    servers.wait_for("the prompt", |s| s.prompt_is("alp"));
    servers.press("Enter");

    assert!(servers.wait_exit(&mut flash));
    assert_eq!(servers.copy_cursor(), "copy-mode 5 0");
}

#[test]
fn scrolled_view_is_kept() {
    let mut text = String::new();
    for n in 0..60 {
        writeln!(text, "line{n:02} text").unwrap();
    }
    let servers = Servers::start(&text);
    let pane = servers.pane();
    let _ = servers.inner(&["copy-mode", "-t", &pane]);
    let _ = servers.inner(&["send-keys", "-t", &pane, "-X", "-N", "10", "scroll-up"]);
    let view = servers.inner(&["capture-pane", "-p", "-t", &pane, "-S", "-10", "-E", "0"]);
    let third: String = view.lines().nth(2).unwrap().chars().take(6).collect();

    let mut flash = servers.flash();
    servers.type_text(&third);
    servers.wait_for("the prompt", |s| s.prompt_is(&third));
    servers.press("Enter");

    assert!(servers.wait_exit(&mut flash));
    assert_eq!(servers.copy_cursor(), "copy-mode 0 2");
    let scroll = servers.inner(&["display-message", "-p", "-t", &pane, "#{scroll_position}"]);
    assert_eq!(scroll.trim(), "10");
}
