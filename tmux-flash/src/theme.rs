//! Colors of the frame: the flash highlights of the user's nvim
//! (solarized.nvim, autumn variant).

use crate::paint::Style;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Theme {
    Dark,
    Light,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct Rgb(pub(crate) u8, pub(crate) u8, pub(crate) u8);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Weight {
    Normal,
    Bold,
}

/// Colors of one style. Without a background color the terminal background
/// stays.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct Look {
    pub(crate) fg: Rgb,
    pub(crate) bg: Option<Rgb>,
    pub(crate) weight: Weight,
}

/// The value of `@color-mode` that selects the light colors.
const LIGHT_OPTION: &str = "light";

const YELLOW: Rgb = Rgb(0xb5, 0x89, 0x00);
const MAGENTA: Rgb = Rgb(0xd3, 0x36, 0x82);
const WHITE: Rgb = Rgb(0xff, 0xff, 0xff);
const BASE04: Rgb = Rgb(0x00, 0x27, 0x31);
const BASE03: Rgb = Rgb(0x00, 0x2b, 0x36);
const BASE01: Rgb = Rgb(0x58, 0x6e, 0x75);
const BASE1: Rgb = Rgb(0x93, 0xa1, 0xa1);
const BASE3: Rgb = Rgb(0xfd, 0xf6, 0xe3);

impl Theme {
    /// From the value of the tmux option `@color-mode`; dark when unset, as
    /// the tmux status line.
    pub(crate) fn from_option(value: &str) -> Self {
        if value.trim() == LIGHT_OPTION {
            return Self::Light;
        }

        Self::Dark
    }

    /// nvim: `FlashBackdrop` is `Comment`, `FlashMatch` is `Search`,
    /// `FlashCurrent` is `IncSearch`; `FlashLabel` is set in the user's
    /// solarized settings.
    pub(crate) const fn look(self, style: Style) -> Look {
        let (text, backdrop, label) = match self {
            Self::Dark => (BASE03, BASE01, (BASE04, WHITE)),
            Self::Light => (BASE3, BASE1, (BASE3, MAGENTA)),
        };

        match style {
            Style::Backdrop => Look {
                fg: backdrop,
                bg: None,
                weight: Weight::Normal,
            },
            Style::Match => Look {
                fg: text,
                bg: Some(YELLOW),
                weight: Weight::Normal,
            },
            Style::Current => Look {
                fg: text,
                bg: Some(YELLOW),
                weight: Weight::Bold,
            },
            Style::Label => Look {
                fg: label.0,
                bg: Some(label.1),
                weight: Weight::Bold,
            },
        }
    }
}

#[cfg(test)]
#[path = "theme_test.rs"]
mod test;
