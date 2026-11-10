//! Integration tests: one test binary, one module per area.

// Test helpers stop the test on the first failure; clippy allows this only
// inside test functions.
#![allow(
    clippy::unwrap_used,
    clippy::expect_used,
    clippy::panic,
    clippy::indexing_slicing,
    reason = "test helpers fail the test on errors"
)]

mod cli;
mod harness;
mod jump;
