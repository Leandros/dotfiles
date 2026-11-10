//! Command line: version and argument errors.

use std::process::{Command, Output};

const BIN: &str = env!("CARGO_BIN_EXE_tmux-flash");
const EXIT_USAGE: i32 = 2;
const EXIT_FAILURE: i32 = 1;

fn run(args: &[&str]) -> Output {
    Command::new(BIN).args(args).output().unwrap()
}

fn stderr(out: &Output) -> String {
    String::from_utf8(out.stderr.clone()).unwrap()
}

#[test]
fn version_prints_version() {
    let out = run(&["--version"]);

    assert!(out.status.success());
    assert_eq!(
        String::from_utf8(out.stdout).unwrap(),
        format!("tmux-flash {}\n", env!("CARGO_PKG_VERSION"))
    );
}

#[test]
fn unknown_argument_fails() {
    let out = run(&["--bogus"]);

    assert_eq!(out.status.code(), Some(EXIT_USAGE));
    assert!(stderr(&out).contains("--bogus"));
}

#[test]
fn no_argument_is_a_usage_error() {
    let out = run(&[]);

    assert_eq!(out.status.code(), Some(EXIT_USAGE));
    assert!(stderr(&out).contains("usage"));
}

#[test]
fn pane_without_client_fails() {
    let out = run(&["--pane", "%1"]);

    assert_eq!(out.status.code(), Some(EXIT_USAGE));
    assert!(stderr(&out).contains("--client"));
}

#[test]
fn flag_without_value_fails() {
    let out = run(&["--client", "c", "--pane"]);

    assert_eq!(out.status.code(), Some(EXIT_USAGE));
    assert!(stderr(&out).contains("--pane"));
}

#[test]
fn pane_must_be_a_pane_id() {
    let out = run(&["--pane", "1", "--client", "c"]);

    assert_eq!(out.status.code(), Some(EXIT_USAGE));
    assert!(stderr(&out).contains("pane id"));
}

#[test]
fn ui_needs_pane_and_client() {
    let out = run(&["--ui"]);

    assert_eq!(out.status.code(), Some(EXIT_USAGE));
}

#[test]
fn no_tmux_server_is_a_failure() {
    let dir = std::env::temp_dir().join(format!("tmux-flash-cli-{}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();

    let out = Command::new(BIN)
        .args(["--pane", "%1", "--client", "c"])
        .env_remove("TMUX")
        .env("TMUX_TMPDIR", &dir)
        .output()
        .unwrap();
    let _ = std::fs::remove_dir_all(&dir);

    assert_eq!(out.status.code(), Some(EXIT_FAILURE));
    assert!(stderr(&out).contains("tmux"));
}
