//! Private tmux servers for the tests. Never the caller's server: `TMUX` is
//! removed and each test has its own `TMUX_TMPDIR`.
//!
//! The inner server has the target pane. The outer server runs `tmux attach`
//! to the inner server in its pane: that is the client that popups need, and
//! `send-keys` to the outer pane types into it. `capture-pane` of the outer
//! pane shows what the client shows, the popup too.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::thread;
use std::time::{Duration, Instant};

const BIN: &str = env!("CARGO_BIN_EXE_tmux-flash");
const WIDTH: u16 = 80;
const HEIGHT: u16 = 24;
const POLL: Duration = Duration::from_millis(20);
const TIMEOUT: Duration = Duration::from_secs(10);
/// The flash prompt in the message line.
pub(crate) const PROMPT: &str = "⚡";
/// The tmux default, 500 ms, makes each Escape key slow.
const INNER_CONF: &str = "set -sg escape-time 10\n";
const OUTER_CONF: &str = "set -g status off\nset -sg escape-time 10\n";

static NEXT: AtomicUsize = AtomicUsize::new(0);

pub(crate) struct Servers {
    dir: PathBuf,
}

impl Servers {
    /// An inner pane that shows `text`; the cursor is after it.
    pub(crate) fn start(text: &str) -> Self {
        let id = NEXT.fetch_add(1, Ordering::SeqCst);
        let dir = std::env::temp_dir().join(format!("tmux-flash-it-{}-{id}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        for sub in ["in", "out"] {
            fs::create_dir_all(dir.join(sub)).unwrap();
        }
        fs::write(dir.join("content"), text).unwrap();
        fs::write(dir.join("inner.conf"), INNER_CONF).unwrap();
        fs::write(dir.join("outer.conf"), OUTER_CONF).unwrap();

        let servers = Self { dir };
        let content = servers.dir.join("content");
        let pane_command = format!("cat '{}'; exec cat", content.display());
        let _ = servers.inner(&[
            "new-session",
            "-d",
            "-s",
            "t",
            "-x",
            &WIDTH.to_string(),
            "-y",
            &HEIGHT.to_string(),
            &pane_command,
        ]);

        let attach = format!(
            "env -u TMUX TERM=screen TMUX_TMPDIR='{}' tmux attach -t t",
            servers.dir.join("in").display()
        );
        let _ = servers.outer(&[
            "new-session",
            "-d",
            "-s",
            "c",
            "-x",
            &WIDTH.to_string(),
            "-y",
            &HEIGHT.to_string(),
            &attach,
        ]);

        servers.wait_for("an attached client", |s| !s.client().is_empty());
        servers.wait_for("the pane text", |s| {
            let last = text.lines().last().unwrap_or_default();
            s.screen().contains(last)
        });
        servers
    }

    pub(crate) fn inner(&self, args: &[&str]) -> String {
        tmux(
            &self.dir.join("in"),
            Some(&self.dir.join("inner.conf")),
            args,
        )
    }

    pub(crate) fn outer(&self, args: &[&str]) -> String {
        tmux(
            &self.dir.join("out"),
            Some(&self.dir.join("outer.conf")),
            args,
        )
    }

    pub(crate) fn pane(&self) -> String {
        self.inner(&["display-message", "-p", "-t", "t", "#{pane_id}"])
            .trim()
            .to_owned()
    }

    pub(crate) fn client(&self) -> String {
        self.inner(&["list-clients", "-F", "#{client_name}"])
            .lines()
            .next()
            .unwrap_or_default()
            .to_owned()
    }

    /// What the client shows.
    pub(crate) fn screen(&self) -> String {
        self.outer(&["capture-pane", "-p", "-t", "c"])
    }

    /// True when the message line shows exactly this pattern.
    pub(crate) fn prompt_is(&self, pattern: &str) -> bool {
        let want = format!("{PROMPT} {pattern}");
        self.screen().lines().any(|line| line.trim_end() == want)
    }

    /// Starts tmux-flash as the key binding does, and waits for its prompt.
    pub(crate) fn flash(&self) -> Child {
        let child = Command::new(BIN)
            .args(["--pane", &self.pane(), "--client", &self.client()])
            .env_remove("TMUX")
            .env_remove("TMUX_PANE")
            .env("TMUX_TMPDIR", self.dir.join("in"))
            .stdout(Stdio::null())
            .spawn()
            .unwrap();

        self.wait_for("the flash prompt", |s| s.screen().contains(PROMPT));
        child
    }

    /// Types text into the client.
    pub(crate) fn type_text(&self, text: &str) {
        let _ = self.outer(&["send-keys", "-t", "c", "-l", text]);
    }

    /// Presses a tmux key name, such as Enter or Escape.
    pub(crate) fn press(&self, key: &str) {
        let _ = self.outer(&["send-keys", "-t", "c", key]);
    }

    /// Mode and copy cursor of the target pane: "copy-mode 11 0".
    pub(crate) fn copy_cursor(&self) -> String {
        self.inner(&[
            "display-message",
            "-p",
            "-t",
            "t",
            "#{pane_mode} #{copy_cursor_x} #{copy_cursor_y}",
        ])
        .trim()
        .to_owned()
    }

    pub(crate) fn wait_for(&self, what: &str, done: impl Fn(&Self) -> bool) {
        let start = Instant::now();
        while !done(self) {
            assert!(
                start.elapsed() < TIMEOUT,
                "timeout: {what}\n{}",
                self.screen()
            );
            thread::sleep(POLL);
        }
    }

    /// Waits until tmux-flash ends; true when it succeeded.
    pub(crate) fn wait_exit(&self, child: &mut Child) -> bool {
        let start = Instant::now();
        loop {
            if let Some(status) = child.try_wait().unwrap() {
                return status.success();
            }
            assert!(
                start.elapsed() < TIMEOUT,
                "timeout: tmux-flash exit\n{}",
                self.screen()
            );
            thread::sleep(POLL);
        }
    }
}

impl Drop for Servers {
    fn drop(&mut self) {
        let _ = self.outer(&["kill-server"]);
        let _ = self.inner(&["kill-server"]);
        let _ = fs::remove_dir_all(&self.dir);
    }
}

fn tmux(sockets: &Path, conf: Option<&Path>, args: &[&str]) -> String {
    let mut command = Command::new("tmux");
    if let Some(conf) = conf {
        let _ = command.arg("-f").arg(conf);
    }

    let output = command
        .args(args)
        .env_remove("TMUX")
        .env_remove("TMUX_PANE")
        .env("TMUX_TMPDIR", sockets)
        .output()
        .unwrap();

    String::from_utf8_lossy(&output.stdout).into_owned()
}
