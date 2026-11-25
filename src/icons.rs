//! Line icons (24×24, stroked) and the MailZen logo, as active views: the same markup
//! on the server and in islands.

use paquets::prelude::*;

/// The stroke paths of an icon.
pub fn paths(name: &str) -> &'static [&'static str] {
    const CIRCLE: &str = "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z";
    match name {
        "mail" => &["M3 6h18v12H3z", "m3 7 9 6 9-6"],
        "link" => &[
            "M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1",
            "M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1",
        ],
        "file" => &["M14 3H6v18h12V7z", "M14 3v4h4", "M9 13h6", "M9 17h4"],
        "camera" => &[
            "M4 7h3l2-3h6l2 3h3v12H4z",
            "M15.5 13a3.5 3.5 0 1 1-7 0 3.5 3.5 0 0 1 7 0z",
        ],
        "qr" => &[
            "M4 4h6v6H4z",
            "M14 4h6v6h-6z",
            "M4 14h6v6H4z",
            "M14 14h2v2h-2z",
            "M18 14h2",
            "M14 18v2h2",
            "M18 18h2v2h-2z",
        ],
        "spark" => &[
            "M12 3c.8 4.5 2.5 6.2 7 7-4.5.8-6.2 2.5-7 7-.8-4.5-2.5-6.2-7-7 4.5-.8 6.2-2.5 7-7z",
            "M19 15v5",
            "M16.5 17.5h5",
        ],
        "lifebuoy" => &[
            CIRCLE,
            "M16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0z",
            "m5.6 5.6 3.6 3.6",
            "m14.8 14.8 3.6 3.6",
            "m18.4 5.6-3.6 3.6",
            "m9.2 14.8-3.6 3.6",
        ],
        "upload" => &["M12 16V4", "m7 9 5-5 5 5", "M4 20h16"],
        "download" => &["M12 4v12", "m7 11 5 5 5-5", "M4 20h16"],
        "layers" => &["m12 3 9 5-9 5-9-5z", "m3 13 9 5 9-5"],
        "radar" => &[
            "M21 12a9 9 0 1 1-9-9",
            "M17 12a5 5 0 1 1-5-5",
            "m12 12 7-7",
            "M13 12a1 1 0 1 1-2 0 1 1 0 0 1 2 0z",
        ],
        "brain" => &[
            "M9 4a3 3 0 0 0-3 3 3 3 0 0 0-2 5 3 3 0 0 0 2 5 3 3 0 0 0 6 1V5.5A2.5 2.5 0 0 0 9 4z",
            "M15 4a3 3 0 0 1 3 3 3 3 0 0 1 2 5 3 3 0 0 1-2 5 3 3 0 0 1-6 1",
        ],
        "report" => &["M6 3h12v18H6z", "M9 8h6", "M9 12h6", "M9 16h3"],
        "clock" => &[CIRCLE, "M12 7v5l3 2"],
        "alert" => &["M12 3 2 20h20z", "M12 10v4", "M12 17h.01"],
        "crown" => &["m3 8 4 4 5-7 5 7 4-4-2 11H5z"],
        "bolt" => &["M13 2 4 14h7l-1 8 9-12h-7z"],
        "lock" => &["M5 11h14v10H5z", "M8 11V7a4 4 0 0 1 8 0v4"],
        "gift" => &[
            "M3 9h18v4H3z",
            "M5 13h14v8H5z",
            "M12 9v12",
            "M12 9C10 5 7 4 7 6.5S10 9 12 9zm0 0c2-4 5-5 5-2.5S14 9 12 9z",
        ],
        "eye" => &[
            "M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z",
            "M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z",
        ],
        "ban" => &[CIRCLE, "m5.6 5.6 12.8 12.8"],
        "coin" => &[
            CIRCLE,
            "M14.5 9.5c-.5-1-1.5-1.5-2.5-1.5-1.5 0-2.5.8-2.5 2s1 1.6 2.5 2 2.5.8 2.5 2-1 2-2.5 2c-1 0-2-.5-2.5-1.5",
            "M12 6.5V8",
            "M12 16v1.5",
        ],
        "heart" => {
            &["M12 20s-8-4.5-8-10.5A4.5 4.5 0 0 1 12 7a4.5 4.5 0 0 1 8 2.5C20 15.5 12 20 12 20z"]
        }
        "mask" => &[
            "M3 7c3-1 6-1 9 1 3-2 6-2 9-1 0 6-3 10-6 10-1.5 0-2-2-3-2s-1.5 2-3 2c-3 0-6-4-6-10z",
            "M7 11h2",
            "M15 11h2",
        ],
        "maze" => &[
            "M3 3h18v18H3z",
            "M7 3v10h4",
            "M11 7h6",
            "M17 7v10",
            "M7 17h6",
        ],
        "bank" => &[
            "M3 10 12 4l9 6",
            "M5 10v8",
            "M9.5 10v8",
            "M14.5 10v8",
            "M19 10v8",
            "M3 20h18",
        ],
        "parcel" => &[
            "M12 2.5 3.5 7v10l8.5 4.5 8.5-4.5V7z",
            "m3.5 7 8.5 4.5L20.5 7",
            "M12 11.5v10",
        ],
        "gov" => &["M5 21V4", "M5 4h12l-2.5 4L17 12H5"],
        "briefcase" => &["M3 8h18v12H3z", "M9 8V5h6v3", "M3 13h18"],
        "chart" => &["M4 20V4", "M4 20h16", "m8 15 4-4 3 3 5-6"],
        "cursor" => &["m5 3 14 7-6 2-2 6z"],
        "key" => &[
            "M12 15a4 4 0 1 1-8 0 4 4 0 0 1 8 0z",
            "m11 12 9-9",
            "m17 6 3 3",
            "m14 9 2 2",
        ],
        "card" => &["M3 6h18v12H3z", "M3 10h18", "M7 15h4"],
        "message" => &["M4 5h16v11H9l-5 4z"],
        "app" => &[
            "M5 5h6v6H5z",
            "M13 5h6v6h-6z",
            "M5 13h6v6H5z",
            "M16 13v6",
            "M13 16h6",
        ],
        "reply" => &["M10 8 4 13l6 5", "M4 13h10a6 6 0 0 1 6 6"],
        "help" => &[
            CIRCLE,
            "M9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.7",
            "M12 17h.01",
        ],
        "badge" => &[
            "M12 3l2.5 2 3.2-.3.8 3.1 2.5 2-1.5 2.9.4 3.2-3 1.1-1.7 2.7-3.2-1-3.2 1-1.7-2.7-3-1.1.4-3.2L3 10.2l2.5-2 .8-3.1 3.2.3z",
            "m9 12 2 2 4-4",
        ],
        "family" => &[
            "M11 7a3 3 0 1 1-6 0 3 3 0 0 1 6 0z",
            "M19 8.5a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z",
            "M2 20c0-3.5 2.5-6 6-6s6 2.5 6 6",
            "M14.5 20c0-2 .8-4.5 2.5-4.5s4 1.5 4 4.5",
        ],
        "book" => &[
            "M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z",
            "M4 21a2 2 0 0 1 2-2h13v2",
        ],
        "phone" => &[
            "M8 2h8a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z",
            "M11 18h2",
        ],
        "cloud" => &["M7 18a4 4 0 0 1-.5-8A6 6 0 0 1 18 9a4.5 4.5 0 0 1-.5 9z"],
        "shield" => &[
            "M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z",
            "m9 12 2 2 4-4",
        ],
        "check" => &["m5 12 5 5 9-10"],
        "x" => &["m6 6 12 12", "m18 6-12 12"],
        "minus" => &["M6 12h12"],
        "arrow" => &["M5 12h14", "m13 6 6 6-6 6"],
        "up" => &["M12 19V5", "m6 11 6-6 6 6"],
        "external" => &["M14 4h6v6", "M20 4 10 14", "M18 14v6H4V6h6"],
        "globe" => &[
            CIRCLE,
            "M3 12h18",
            "M12 3c3 3 3 15 0 18",
            "M12 3c-3 3-3 15 0 18",
        ],
        "menu" => &["M4 7h16", "M4 12h16", "M4 17h16"],
        "github" => &[
            "M9 19c-4 1.5-4-2-6-2.5m12 5v-3.5c0-1 .1-1.4-.5-2 2.8-.3 5.5-1.4 5.5-6a4.6 4.6 0 0 0-1.3-3.2 4.2 4.2 0 0 0-.1-3.2s-1.1-.3-3.5 1.3a12 12 0 0 0-6.2 0C6.5 2.8 5.4 3.1 5.4 3.1a4.2 4.2 0 0 0-.1 3.2A4.6 4.6 0 0 0 4 9.5c0 4.6 2.7 5.7 5.5 6-.6.6-.6 1.2-.5 2V21",
        ],
        "apple" => &[
            "M15.5 3c-1 .1-2.1.7-2.7 1.5-.6.7-1 1.7-.9 2.6 1 .1 2-.6 2.6-1.4.6-.8 1-1.7 1-2.7z",
            "M18.5 16.3c-.5 1.1-.7 1.6-1.4 2.6-.9 1.4-2.2 3.1-3.8 3.1-1.4 0-1.8-.9-3.7-.9s-2.4.9-3.8.9c-1.6 0-2.8-1.6-3.7-3C-.4 15.2.3 10.6 2.6 8.9c.9-.7 2-1.1 3.1-1.1 1.4 0 2.4.9 3.6.9 1.1 0 1.8-.9 3.6-.9 1.1 0 2.4.6 3.3 1.7-2.9 1.6-2.4 5.8.3 6.8z",
        ],
        "android" => &[
            "M5 10h14v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1z",
            "M5 9a7 7 0 0 1 14 0",
            "M8 5 6.5 3",
            "m16 5 1.5-2",
            "M9 7h.01",
            "M15 7h.01",
            "M9 19v2",
            "M15 19v2",
        ],
        "star" => &["m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z"],
        "cog" => &[
            "M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z",
            "M12 2v3",
            "M12 19v3",
            "m4.9 4.9 2.1 2.1",
            "m17 17 2.1 2.1",
            "M2 12h3",
            "M19 12h3",
            "m4.9 19.1 2.1-2.1",
            "m17 7 2.1-2.1",
        ],
        "install" => &["M12 3v12", "m7 10 5 5 5-5", "M5 21h14"],
        "home" => &["m3 11 9-8 9 8", "M5 10v10h14V10"],
        "target" => &[
            CIRCLE,
            "M17 12a5 5 0 1 1-10 0 5 5 0 0 1 10 0z",
            "M13 12a1 1 0 1 1-2 0 1 1 0 0 1 2 0z",
        ],
        _ => &[],
    }
}

/// A line icon: `<svg class="icon">`.
pub fn icon(name: &str) -> Element {
    svg()
        .class("icon")
        .attr("viewBox", "0 0 24 24")
        .attr("fill", "none")
        .attr("stroke", "currentColor")
        .attr("stroke-width", "1.7")
        .attr("stroke-linecap", "round")
        .attr("stroke-linejoin", "round")
        .attr("aria-hidden", "true")
        .children(paths(name).iter().map(|d| path().attr("d", *d)))
}

/// The shield of the logo.
pub const SHIELD: &str = "M32 4 9 12.5v17C9 45 19 55 32 60c13-5 23-15 23-30.5v-17z";

/// The MailZen logo: an envelope inside a shield, with a check. `id` keeps the gradient
/// ids of several logos of a page apart.
pub fn logo(id: &str) -> Element {
    let fill = format!("mz-g-{id}");
    let glow = format!("mz-h-{id}");
    svg()
        .class("logo")
        .attr("viewBox", "0 0 64 64")
        .attr("aria-hidden", "true")
        .child(
            defs()
                .child(
                    linear_gradient()
                        .id(fill.clone())
                        .attr("x1", "0")
                        .attr("y1", "0")
                        .attr("x2", "1")
                        .attr("y2", "1")
                        .child(stop().attr("offset", "0").attr("stop-color", "#22d3ee"))
                        .child(stop().attr("offset", "1").attr("stop-color", "#14b8a6")),
                )
                .child(
                    linear_gradient()
                        .id(glow.clone())
                        .attr("x1", "0")
                        .attr("y1", "0")
                        .attr("x2", "0")
                        .attr("y2", "1")
                        .child(
                            stop()
                                .attr("offset", "0")
                                .attr("stop-color", "#ffffff")
                                .attr("stop-opacity", ".55"),
                        )
                        .child(
                            stop()
                                .attr("offset", "1")
                                .attr("stop-color", "#ffffff")
                                .attr("stop-opacity", "0"),
                        ),
                ),
        )
        .child(
            path()
                .class("logo__shield")
                .attr("d", SHIELD)
                .attr("fill", format!("url(#{fill})")),
        )
        .child(
            path()
                .attr("d", "M32 4 9 12.5v17c0 3 .4 5.8 1.2 8.4L32 22l21.8 15.9c.8-2.6 1.2-5.4 1.2-8.4v-17z")
                .attr("fill", format!("url(#{glow})"))
                .attr("opacity", ".35"),
        )
        .child(
            path()
                .class("logo__mail")
                .attr("d", "M19 24h26v18H19z")
                .attr("fill", "#0b1530")
                .attr("stroke", "#e6fbff")
                .attr("stroke-width", "2.4")
                .attr("stroke-linejoin", "round"),
        )
        .child(
            path()
                .class("logo__flap")
                .attr("d", "m19.5 25 12.5 9 12.5-9")
                .attr("fill", "none")
                .attr("stroke", "#e6fbff")
                .attr("stroke-width", "2.4")
                .attr("stroke-linecap", "round")
                .attr("stroke-linejoin", "round"),
        )
        .child(
            circle()
                .class("logo__badge")
                .attr("cx", "44")
                .attr("cy", "45")
                .attr("r", "9.5")
                .attr("fill", "#0b1530")
                .attr("stroke", "#34d399")
                .attr("stroke-width", "2"),
        )
        .child(
            path()
                .class("logo__check")
                .attr("d", "m39.5 45.2 3.2 3.2 6-6.4")
                .attr("fill", "none")
                .attr("stroke", "#34d399")
                .attr("stroke-width", "2.8")
                .attr("stroke-linecap", "round")
                .attr("stroke-linejoin", "round"),
        )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn icons_render() {
        let html = Node::from(icon("arrow")).render();
        assert!(html.starts_with("<svg class=\"icon\" viewBox=\"0 0 24 24\""));
        assert_eq!(html.matches("<path").count(), 2);
        assert!(paths("nope").is_empty());
        let logo = Node::from(logo("a")).render();
        assert!(logo.contains("linearGradient") && logo.contains("url(#mz-g-a)"));
    }

    #[test]
    fn every_icon_used_by_the_content_exists() {
        use crate::data::*;
        let mut names: Vec<&str> = Vec::new();
        names.extend(MODULES.iter().map(|m| m.icon));
        names.extend(STEPS.iter().map(|s| s.icon));
        names.extend(TECHNIQUES.iter().map(|t| t.0));
        names.extend(CATEGORIES.iter().map(|c| c.icon));
        names.extend(SCENARIOS.iter().map(|s| s.icon));
        names.extend(ECOSYSTEM.iter().map(|f| f.icon));
        names.extend(RADAR.iter().map(|r| r.2));
        names.extend(MODES.iter().map(|m| m.1));
        for name in names {
            assert!(!paths(name).is_empty(), "missing icon {name}");
        }
    }
}
