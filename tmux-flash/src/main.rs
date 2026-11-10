//! tmux-flash: jump labels for tmux panes, with the rules of flash.nvim.

mod app;
mod flash;
mod paint;
mod term;
mod theme;
mod tmux;

use std::fmt;
use std::io::{self, Write};
use std::process::ExitCode;

use app::{CLIENT_FLAG, Origin, PANE_FLAG, UI_FLAG};

const NAME: &str = env!("CARGO_PKG_NAME");
const VERSION: &str = env!("CARGO_PKG_VERSION");
const VERSION_FLAG: &str = "--version";
const USAGE: &str = "usage: tmux-flash --pane PANE --client CLIENT\n       tmux-flash --version";
/// Exit status for a command line error, as getopt tools use.
const EXIT_USAGE: u8 = 2;
/// tmux pane ids are `%` and a number.
const PANE_PREFIX: char = '%';

/// Which of the two runs: the key binding starts the launcher, the popup
/// starts the UI.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Run {
    Launch,
    Ui,
}

/// What the command line asks for.
#[derive(Debug, PartialEq, Eq)]
enum Command {
    Version,
    Run(Run, Origin),
}

/// A command line that cannot run.
#[derive(Debug, PartialEq, Eq)]
enum ArgsError {
    Missing,
    Unknown(String),
    NoValue(&'static str),
    Required(&'static str),
    BadPane(String),
}

impl fmt::Display for ArgsError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Missing => write!(f, "missing argument"),
            Self::Unknown(arg) => write!(f, "unknown argument: {arg}"),
            Self::NoValue(flag) => write!(f, "{flag} needs a value"),
            Self::Required(flag) => write!(f, "missing {flag}"),
            Self::BadPane(pane) => write!(f, "not a pane id: {pane}"),
        }
    }
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();

    match parse_args(&args) {
        Ok(Command::Version) => print_version(),
        Ok(Command::Run(run, origin)) => run_app(run, &origin),
        Err(error) => usage_error(&error),
    }
}

fn parse_args(args: &[String]) -> Result<Command, ArgsError> {
    if args.is_empty() {
        return Err(ArgsError::Missing);
    }

    if args.len() == 1 && args.first().is_some_and(|arg| arg == VERSION_FLAG) {
        return Ok(Command::Version);
    }

    let mut run = Run::Launch;
    let mut pane = None;
    let mut client = None;
    let mut rest = args.iter();

    while let Some(arg) = rest.next() {
        match arg.as_str() {
            UI_FLAG => run = Run::Ui,
            PANE_FLAG => pane = Some(rest.next().ok_or(ArgsError::NoValue(PANE_FLAG))?),
            CLIENT_FLAG => client = Some(rest.next().ok_or(ArgsError::NoValue(CLIENT_FLAG))?),
            _ => return Err(ArgsError::Unknown(arg.clone())),
        }
    }

    let pane = pane.ok_or(ArgsError::Required(PANE_FLAG))?;
    let client = client.ok_or(ArgsError::Required(CLIENT_FLAG))?;

    if !is_pane_id(pane) {
        return Err(ArgsError::BadPane(pane.clone()));
    }

    Ok(Command::Run(
        run,
        Origin {
            pane: pane.clone(),
            client: client.clone(),
        },
    ))
}

fn is_pane_id(text: &str) -> bool {
    text.strip_prefix(PANE_PREFIX)
        .is_some_and(|number| !number.is_empty() && number.chars().all(|c| c.is_ascii_digit()))
}

fn run_app(run: Run, origin: &Origin) -> ExitCode {
    let result = match run {
        Run::Launch => app::launch(origin),
        Run::Ui => app::run_ui(origin),
    };

    let Err(error) = result else {
        return ExitCode::SUCCESS;
    };

    app::report(origin, &error);
    ExitCode::FAILURE
}

fn print_version() -> ExitCode {
    if writeln!(io::stdout(), "{NAME} {VERSION}").is_err() {
        return ExitCode::FAILURE;
    }

    ExitCode::SUCCESS
}

fn usage_error(error: &ArgsError) -> ExitCode {
    // If stderr is gone, there is no other place to report to.
    let _ = writeln!(io::stderr(), "{NAME}: {error}\n{USAGE}");

    ExitCode::from(EXIT_USAGE)
}
