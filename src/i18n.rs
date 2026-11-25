//! The languages of the site: French, English and Spanish. Every text is a [`T3`], an
//! array `[fr, en, es]`: forgetting a translation does not compile.

/// A text in the three languages, in the order `[fr, en, es]`.
pub type T3 = [&'static str; 3];

#[derive(Clone, Copy, PartialEq, Eq, Debug, Hash)]
pub enum Lang {
    Fr,
    En,
    Es,
}

impl Lang {
    /// In the order of the selector.
    pub const ALL: [Lang; 3] = [Lang::Fr, Lang::En, Lang::Es];

    fn index(self) -> usize {
        match self {
            Lang::Fr => 0,
            Lang::En => 1,
            Lang::Es => 2,
        }
    }

    /// Picks the value of this language in `[fr, en, es]`.
    pub fn pick<T: Copy>(self, values: [T; 3]) -> T {
        values[self.index()]
    }

    /// The text of this language.
    pub fn t(self, text: &T3) -> &'static str {
        text[self.index()]
    }

    pub fn code(self) -> &'static str {
        self.pick(["fr", "en", "es"])
    }

    pub fn name(self) -> &'static str {
        self.pick(["Français", "English", "Español"])
    }

    /// The Open Graph locale.
    pub fn locale(self) -> &'static str {
        self.pick(["fr_FR", "en_US", "es_ES"])
    }

    /// `fr`, `en` or `es` exactly.
    pub fn parse(code: &str) -> Option<Lang> {
        Lang::ALL.into_iter().find(|l| l.code() == code)
    }

    /// The language of a tag such as `fr-CA` or `ES`.
    pub fn from_tag(tag: &str) -> Option<Lang> {
        Lang::parse(&tag.get(..2)?.to_ascii_lowercase())
    }
}

/// The preferred supported language of an `Accept-Language` header, French by default.
pub fn pick_lang(header: &str) -> Lang {
    let mut ranked: Vec<(Lang, f32)> = header
        .split(',')
        .filter_map(|part| {
            let mut pieces = part.trim().split(";q=");
            let lang = Lang::from_tag(pieces.next()?)?;
            let q = pieces
                .next()
                .and_then(|q| q.trim().parse().ok())
                .unwrap_or(1.0);
            Some((lang, q))
        })
        .filter(|(_, q)| *q > 0.0)
        .collect();
    ranked.sort_by(|a, b| b.1.total_cmp(&a.1));
    ranked.first().map_or(Lang::Fr, |r| r.0)
}

/// Formats an integer for the language: `12 400` / `12,400` / `12.400`.
pub fn number(lang: Lang, value: u64) -> String {
    let group = lang.pick(['\u{202f}', ',', '.']);
    let digits: Vec<char> = value.to_string().chars().collect();
    let grouped = digits.len() > 4 || (digits.len() == 4 && lang != Lang::Es);
    let mut out = String::new();
    for (i, c) in digits.iter().enumerate() {
        if grouped && i > 0 && (digits.len() - i).is_multiple_of(3) {
            out.push(group);
        }
        out.push(*c);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn picks_the_language_of_the_browser() {
        assert_eq!(pick_lang("es-ES,es;q=0.9,en;q=0.8"), Lang::Es);
        assert_eq!(pick_lang("de-DE,en;q=0.5"), Lang::En);
        assert_eq!(pick_lang("de-DE"), Lang::Fr);
        assert_eq!(pick_lang(""), Lang::Fr);
        assert_eq!(pick_lang("fr;q=0.2,en;q=0.9"), Lang::En);
    }

    #[test]
    fn formats_numbers() {
        assert_eq!(number(Lang::Fr, 12400), "12\u{202f}400");
        assert_eq!(number(Lang::En, 1280), "1,280");
        assert_eq!(number(Lang::Es, 1280), "1280");
        assert_eq!(number(Lang::Es, 12400), "12.400");
        assert_eq!(number(Lang::En, 92), "92");
    }

    #[test]
    fn every_language_has_a_code() {
        for lang in Lang::ALL {
            assert_eq!(Lang::parse(lang.code()), Some(lang));
            assert_eq!(lang.t(&["a", "b", "c"]).len(), 1);
        }
    }
}
