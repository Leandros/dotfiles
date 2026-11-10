use super::*;

#[test]
fn light_option_is_light() {
    assert_eq!(Theme::from_option("light\n"), Theme::Light);
}

#[test]
fn other_options_are_dark() {
    assert_eq!(Theme::from_option("dark\n"), Theme::Dark);
    assert_eq!(Theme::from_option(""), Theme::Dark);
}

#[test]
fn dark_colors() {
    assert_eq!(
        Theme::Dark.look(Style::Backdrop),
        Look {
            fg: Rgb(0x58, 0x6e, 0x75),
            bg: None,
            weight: Weight::Normal
        }
    );
    assert_eq!(
        Theme::Dark.look(Style::Match),
        Look {
            fg: Rgb(0x00, 0x2b, 0x36),
            bg: Some(Rgb(0xb5, 0x89, 0x00)),
            weight: Weight::Normal
        }
    );
    assert_eq!(
        Theme::Dark.look(Style::Current),
        Look {
            fg: Rgb(0x00, 0x2b, 0x36),
            bg: Some(Rgb(0xb5, 0x89, 0x00)),
            weight: Weight::Bold
        }
    );
    assert_eq!(
        Theme::Dark.look(Style::Label),
        Look {
            fg: Rgb(0x00, 0x27, 0x31),
            bg: Some(Rgb(0xff, 0xff, 0xff)),
            weight: Weight::Bold
        }
    );
}

#[test]
fn light_colors() {
    assert_eq!(
        Theme::Light.look(Style::Backdrop),
        Look {
            fg: Rgb(0x93, 0xa1, 0xa1),
            bg: None,
            weight: Weight::Normal
        }
    );
    assert_eq!(
        Theme::Light.look(Style::Match),
        Look {
            fg: Rgb(0xfd, 0xf6, 0xe3),
            bg: Some(Rgb(0xb5, 0x89, 0x00)),
            weight: Weight::Normal
        }
    );
    assert_eq!(
        Theme::Light.look(Style::Current),
        Look {
            fg: Rgb(0xfd, 0xf6, 0xe3),
            bg: Some(Rgb(0xb5, 0x89, 0x00)),
            weight: Weight::Bold
        }
    );
    assert_eq!(
        Theme::Light.look(Style::Label),
        Look {
            fg: Rgb(0xfd, 0xf6, 0xe3),
            bg: Some(Rgb(0xd3, 0x36, 0x82)),
            weight: Weight::Bold
        }
    );
}
