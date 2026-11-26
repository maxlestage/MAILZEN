"""The features of the MailZen models, defined once and reproduced exactly in Swift
(apps/ios/MailZenKit/Sources/MailZenKit/Models.swift): golden tests check both agree.

- the text is cut to 3000 Unicode code points and lowercased;
- tokens are runs of letters and numbers (general categories L* and N*), ASCII digits
  becoming 0;
- features: each token (w:), each pair of tokens (b:), and the character trigrams of the
  tokens of 4 code points or more, framed by < and > (c:); the first 400 tokens;
- each feature is hashed with FNV-1a (32 bits, UTF-8) modulo 2^18; a text is the set of
  its hashed features, each worth 1/sqrt(n).
"""
import unicodedata

DIM = 1 << 18
MAX_CHARS = 3000
MAX_TOKENS = 400


def fnv1a(s: str) -> int:
    h = 0x811C9DC5
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h


def is_word(c: str) -> bool:
    return unicodedata.category(c)[0] in ("L", "N")


def tokens(text: str) -> list:
    text = text[:MAX_CHARS].lower()
    out, cur = [], []
    for c in text:
        if is_word(c):
            cur.append("0" if c in "0123456789" else c)
        elif cur:
            out.append("".join(cur))
            cur = []
    if cur:
        out.append("".join(cur))
    return out[:MAX_TOKENS]


def features(text: str) -> list:
    toks = tokens(text)
    feats = set()
    for i, t in enumerate(toks):
        feats.add(fnv1a("w:" + t) % DIM)
        if i + 1 < len(toks):
            feats.add(fnv1a("b:" + t + " " + toks[i + 1]) % DIM)
        if len(t) >= 4:
            framed = "<" + t + ">"
            for j in range(len(framed) - 2):
                feats.add(fnv1a("c:" + framed[j : j + 3]) % DIM)
    return sorted(feats)
