//! The trained models of MailZen, in the demo of the site: the models of the app pruned
//! to their strongest weights (`ml/web.py`), downloaded by the browser only when a visitor
//! runs an analysis (`public/assets/models/*.mzm`). Their features are those of
//! `ml/features.py` and `ml/url_features.py`, reproduced here; golden tests
//! (`tests/model_golden.rs`) check both agree.
//!
//! One approximation: a word character is a Unicode letter or number for Python (general
//! categories L* and N*), alphabetic or numeric for Rust, which also counts the few
//! combining marks that are alphabetic (some Indic vowel signs). The languages of the site
//! are not concerned.

use crate::i18n::T3;

pub const DIM: u32 = 1 << 18;
const MAX_CHARS: usize = 3000;
const MAX_TOKENS: usize = 400;
const MAX_URL_CHARS: usize = 300;

pub fn fnv1a(s: &str) -> u32 {
    let mut h: u32 = 0x811C_9DC5;
    for b in s.bytes() {
        h ^= u32::from(b);
        h = h.wrapping_mul(0x0100_0193);
    }
    h
}

fn word_runs(text: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut current = String::new();
    for c in text.chars() {
        if c.is_alphanumeric() {
            current.push(if c.is_ascii_digit() { '0' } else { c });
        } else if !current.is_empty() {
            out.push(std::mem::take(&mut current));
        }
    }
    if !current.is_empty() {
        out.push(current);
    }
    out
}

fn finish(names: impl IntoIterator<Item = String>) -> Vec<u32> {
    let mut v: Vec<u32> = names.into_iter().map(|n| fnv1a(&n) % DIM).collect();
    v.sort_unstable();
    v.dedup();
    v
}

/// The features of a text: words, pairs of words and character trigrams, hashed.
pub fn text_features(text: &str) -> Vec<u32> {
    let cut: String = text.chars().take(MAX_CHARS).collect();
    let mut tokens = word_runs(&cut.to_lowercase());
    tokens.truncate(MAX_TOKENS);
    let mut names = Vec::new();
    for (i, t) in tokens.iter().enumerate() {
        names.push(format!("w:{t}"));
        if let Some(next) = tokens.get(i + 1) {
            names.push(format!("b:{t} {next}"));
        }
        let chars: Vec<char> = t.chars().collect();
        if chars.len() >= 4 {
            let framed: Vec<char> = std::iter::once('<')
                .chain(chars)
                .chain(std::iter::once('>'))
                .collect();
            for w in framed.windows(3) {
                names.push(format!("c:{}", w.iter().collect::<String>()));
            }
        }
    }
    finish(names)
}

fn normalize_url(url: &str) -> String {
    let lowered = url.trim().replace("&amp;", "&").to_lowercase();
    let mut u: String = lowered.chars().take(MAX_URL_CHARS).collect();
    for scheme in ["https://", "http://"] {
        if let Some(rest) = u.strip_prefix(scheme) {
            u = rest.to_owned();
            break;
        }
    }
    if let Some(rest) = u.strip_prefix("www.") {
        u = rest.to_owned();
    }
    u.trim_end_matches('/').to_owned()
}

fn grams(chars: &[char], n: usize, prefix: &str, names: &mut Vec<String>) {
    if chars.len() >= n {
        for w in chars.windows(n) {
            names.push(format!("{prefix}{}", w.iter().collect::<String>()));
        }
    }
}

/// The features of a link: character n-grams of its host and path, its labels and shape.
pub fn url_features(url: &str) -> Vec<u32> {
    let u = normalize_url(url);
    if u.is_empty() {
        return Vec::new();
    }
    let end = u.find(['/', '?', '#']).unwrap_or(u.len());
    let (mut host, rest) = (u[..end].to_owned(), &u[end..]);
    let at = host.contains('@');
    if let Some(i) = host.rfind('@') {
        host = host[i + 1..].to_owned();
    }
    let port = host.contains(':');
    if let Some(i) = host.find(':') {
        host.truncate(i);
    }
    let mut names = Vec::new();
    let framed: Vec<char> = format!("^{host}$").chars().collect();
    for n in 3..=5 {
        grams(&framed, n, &format!("h{n}:"), &mut names);
    }
    let labels: Vec<&str> = host.split('.').filter(|l| !l.is_empty()).collect();
    for l in &labels {
        names.push(format!("hl:{l}"));
    }
    if let Some(last) = labels.last() {
        names.push(format!("tld:{last}"));
        names.push(format!(
            "rd:{}",
            labels[labels.len().saturating_sub(2)..].join(".")
        ));
    }
    let rest_chars: Vec<char> = rest.chars().collect();
    let head = &rest_chars[..rest_chars.len().min(120)];
    for n in 3..=4 {
        grams(head, n, &format!("p{n}:"), &mut names);
    }
    for t in word_runs(rest).into_iter().take(40) {
        names.push(format!("pt:{t}"));
    }
    let host_len = host.chars().count();
    names.push(format!("hlen:{}", (host_len / 4).min(15)));
    names.push(format!("dots:{}", host.matches('.').count().min(8)));
    names.push(format!("hyph:{}", host.matches('-').count().min(5)));
    if host.chars().any(|c| c.is_ascii_digit()) {
        names.push("hdig".to_owned());
    }
    let parts: Vec<&str> = host.split('.').collect();
    if parts.len() == 4
        && parts.iter().all(|p| {
            !p.is_empty()
                && p.chars().all(|c| c.is_ascii_digit())
                && p.parse::<u32>().is_ok_and(|v| v < 256)
        })
    {
        names.push("ip".to_owned());
    }
    if at {
        names.push("at".to_owned());
    }
    if port {
        names.push("port".to_owned());
    }
    let len = rest_chars.len();
    names.push(format!("plen:{}", usize::BITS - len.leading_zeros()));
    if rest.contains('?') {
        names.push("q".to_owned());
    }
    let mut path = rest;
    for c in ['?', '#'] {
        if let Some(i) = path.find(c) {
            path = &path[..i];
        }
    }
    let segments: Vec<&str> = path.split('/').filter(|s| !s.is_empty()).collect();
    names.push(format!("nseg:{}", segments.len().min(8)));
    if let Some(last) = segments.last()
        && last.contains('.')
        && let Some(ext) = last.rsplit('.').next()
    {
        let n = ext.chars().count();
        if (1..=5).contains(&n) && ext.chars().all(|c| c.is_ascii_alphanumeric()) {
            names.push(format!("ext:{ext}"));
        }
    }
    finish(names)
}

/// A linear model with 8-bit weights (a `.mzm` file).
#[derive(Clone, Debug)]
pub struct LinearModel {
    pub classes: Vec<String>,
    scale: f64,
    bias: Vec<f64>,
    indices: Vec<u32>,
    weights: Vec<i8>,
}

impl LinearModel {
    pub fn parse(bytes: &[u8]) -> Option<LinearModel> {
        let mut o = 0usize;
        let mut take = |n: usize| -> Option<&[u8]> {
            let s = bytes.get(o..o + n)?;
            o += n;
            Some(s)
        };
        if take(4)? != b"MZM1" {
            return None;
        }
        let u32le = |b: &[u8]| u32::from_le_bytes([b[0], b[1], b[2], b[3]]);
        let f32le = |b: &[u8]| f64::from(f32::from_le_bytes([b[0], b[1], b[2], b[3]]));
        if u32le(take(4)?) != DIM {
            return None;
        }
        let kb = take(2)?;
        let k = usize::from(u16::from_le_bytes([kb[0], kb[1]]));
        let name_len = u32le(take(4)?) as usize;
        let classes: Vec<String> = String::from_utf8(take(name_len)?.to_vec())
            .ok()?
            .split('\n')
            .map(str::to_owned)
            .collect();
        if k == 0 || classes.len() != k {
            return None;
        }
        let scale = f32le(take(4)?);
        let mut bias = Vec::with_capacity(k);
        for _ in 0..k {
            bias.push(f32le(take(4)?));
        }
        let n = u32le(take(4)?) as usize;
        let mut indices = Vec::with_capacity(n);
        let mut weights = Vec::with_capacity(n * k);
        for _ in 0..n {
            indices.push(u32le(take(4)?));
            weights.extend(take(k)?.iter().map(|&b| b as i8));
        }
        Some(LinearModel {
            classes,
            scale,
            bias,
            indices,
            weights,
        })
    }

    /// The probabilities: one (logistic) for a binary model, a distribution otherwise.
    pub fn probabilities(&self, features: &[u32]) -> Vec<f64> {
        let k = self.classes.len();
        let mut sums = vec![0i64; k];
        for f in features {
            if let Ok(i) = self.indices.binary_search(f) {
                for (c, sum) in sums.iter_mut().enumerate() {
                    *sum += i64::from(self.weights[i * k + c]);
                }
            }
        }
        let norm = if features.is_empty() {
            0.0
        } else {
            1.0 / (features.len() as f64).sqrt()
        };
        let z: Vec<f64> = (0..k)
            .map(|c| self.bias[c] + self.scale * sums[c] as f64 * norm)
            .collect();
        if k == 1 {
            return vec![1.0 / (1.0 + (-z[0]).exp())];
        }
        let m = z.iter().copied().fold(f64::NEG_INFINITY, f64::max);
        let e: Vec<f64> = z.iter().map(|v| (v - m).exp()).collect();
        let total: f64 = e.iter().sum();
        e.into_iter().map(|v| v / total).collect()
    }

    /// The most likely class and its probability.
    pub fn best(&self, features: &[u32]) -> (String, f64) {
        let p = self.probabilities(features);
        let (i, v) = p
            .iter()
            .copied()
            .enumerate()
            .fold((0, f64::NEG_INFINITY), |a, b| if b.1 > a.1 { b } else { a });
        (self.classes[i].clone(), v)
    }
}

/// The three models of the demo.
#[derive(Clone, Debug)]
pub struct Models {
    pub scam: LinearModel,
    pub category: LinearModel,
    pub url: LinearModel,
}

/// The files of the models, under `/assets/models/`.
pub const FILES: [&str; 3] = ["scam", "category", "url"];

impl Models {
    pub fn parse(scam: &[u8], category: &[u8], url: &[u8]) -> Option<Models> {
        Some(Models {
            scam: LinearModel::parse(scam)?,
            category: LinearModel::parse(category)?,
            url: LinearModel::parse(url)?,
        })
    }

    /// The models of the site, read from `public/` (the server and the tests).
    #[cfg(not(target_arch = "wasm32"))]
    pub fn from_public() -> Option<Models> {
        let read = |name: &str| {
            std::fs::read(format!(
                "{}/public/assets/models/{name}.mzm",
                env!("CARGO_MANIFEST_DIR")
            ))
            .ok()
        };
        Models::parse(&read("scam")?, &read("category")?, &read("url")?)
    }
}

/// Official domains (those of the app's Brand Check): the link model never judges them.
pub const OFFICIAL: &[&str] = &[
    "paypal.com",
    "amazon.com",
    "amazon.fr",
    "amazon.es",
    "amazon.de",
    "amazon.co.uk",
    "apple.com",
    "icloud.com",
    "microsoft.com",
    "live.com",
    "outlook.com",
    "office.com",
    "google.com",
    "google.fr",
    "google.es",
    "gmail.com",
    "youtube.com",
    "netflix.com",
    "facebook.com",
    "meta.com",
    "instagram.com",
    "whatsapp.com",
    "dhl.com",
    "dhl.de",
    "dhl.fr",
    "ups.com",
    "fedex.com",
    "chronopost.fr",
    "laposte.fr",
    "colissimo.fr",
    "laposte.net",
    "correos.es",
    "ameli.fr",
    "impots.gouv.fr",
    "caf.fr",
    "service-public.fr",
    "edf.fr",
    "orange.fr",
    "sfr.fr",
    "free.fr",
    "agenciatributaria.gob.es",
    "irs.gov",
];

/// Whether a host is an official domain or one of its subdomains.
pub fn is_official(host: &str) -> bool {
    let h = host.to_lowercase();
    OFFICIAL
        .iter()
        .any(|d| h == *d || h.ends_with(&format!(".{d}")))
}

/// The label of a family of scam of the category model.
pub fn category_label(key: &str) -> Option<&'static T3> {
    Some(match key {
        "bank" => &[
            "fausse alerte bancaire",
            "fake bank alert",
            "falsa alerta bancaria",
        ],
        "delivery" => &["faux colis", "fake parcel", "paquete falso"],
        "government" => &[
            "fausse administration",
            "fake government notice",
            "falsa administración",
        ],
        "business" => &[
            "fraude au président ou faux fournisseur",
            "CEO fraud or fake supplier",
            "fraude del CEO o falso proveedor",
        ],
        "investment" => &["faux investissement", "fake investment", "falsa inversión"],
        "romance" => &["arnaque sentimentale", "romance scam", "estafa romántica"],
        "blackmail" => &["chantage", "blackmail", "chantaje"],
        "tech_support" => &[
            "faux support technique",
            "fake tech support",
            "falso soporte técnico",
        ],
        "prize" => &["faux gain", "fake prize", "falso premio"],
        "account" => &[
            "faux message de compte",
            "fake account notice",
            "falso aviso de cuenta",
        ],
        _ => return None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hashes_like_the_reference() {
        // FNV-1a 32 bits of "a".
        assert_eq!(fnv1a("a"), 0xE40C_292C);
        assert_eq!(fnv1a(""), 0x811C_9DC5);
    }

    #[test]
    fn the_models_of_the_site_load() {
        let models = Models::from_public().expect("models in public/assets/models");
        assert_eq!(models.category.classes.len(), 10);
        let p = models.url.probabilities(&url_features(
            "https://paypa1-secure-login.xyz/verify/account.php",
        ))[0];
        assert!(p > 0.9, "{p}");
    }
}
