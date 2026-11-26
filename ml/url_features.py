"""The features of the link model of MailZen, defined once and reproduced exactly in Swift
(URLFeaturizer in Models.swift): golden tests check both agree.

A URL is normalized: trimmed, `&amp;` decoded, lowercased, cut to 300 code points, its
scheme (`http://`, `https://`) and a leading `www.` removed, trailing slashes removed. The
scheme is left out on purpose: unencrypted links are a rule of their own (plainHttp).

Then: the host (before the first `/`, `?` or `#`, without the user part before an `@` and
without the port) and the rest (the path, the query). Features, hashed with FNV-1a modulo
2^18 as in features.py, each worth 1/sqrt(n):
- `h3:`, `h4:`, `h5:` the character 3-, 4- and 5-grams of `^host$`;
- `hl:` each label of the host, `tld:` the last one, `rd:` the last two;
- `p3:`, `p4:` the character 3- and 4-grams of the first 120 code points of the rest;
- `pt:` its tokens (runs of letters and numbers, ASCII digits becoming 0), the first 40;
- shapes: `hlen:` the length of the host / 4 (at most 15), `dots:` its number of dots (at
  most 8), `hyph:` its hyphens (at most 5), `hdig:` whether it has a digit, `ip`, `at`,
  `port`, `plen:` the bit length of the length of the rest, `q` a query, `ext:` the
  extension of the last segment of the path (at most 5 letters), `nseg:` the number of
  segments of the path (at most 8).
"""
from features import DIM, fnv1a, is_word

MAX_CHARS = 300


def normalize(url: str) -> str:
    u = url.strip().replace("&amp;", "&").lower()[:MAX_CHARS]
    for scheme in ("https://", "http://"):
        if u.startswith(scheme):
            u = u[len(scheme):]
            break
    if u.startswith("www."):
        u = u[4:]
    return u.rstrip("/")


def split(u: str):
    end = len(u)
    for c in "/?#":
        i = u.find(c)
        if i != -1 and i < end:
            end = i
    host, rest = u[:end], u[end:]
    at = "@" in host
    if at:
        host = host[host.rfind("@") + 1:]
    port = ":" in host
    if port:
        host = host[: host.find(":")]
    return host, rest, at, port


def path_tokens(s: str) -> list:
    out, cur = [], []
    for c in s:
        if is_word(c):
            cur.append("0" if c in "0123456789" else c)
        elif cur:
            out.append("".join(cur)); cur = []
    if cur:
        out.append("".join(cur))
    return out[:40]


def url_features(url: str) -> list:
    u = normalize(url)
    if not u:
        return []
    host, rest, at, port = split(u)
    names = []
    framed = "^" + host + "$"
    for n in (3, 4, 5):
        for j in range(len(framed) - n + 1):
            names.append(f"h{n}:" + framed[j:j + n])
    labels = [l for l in host.split(".") if l]
    for l in labels:
        names.append("hl:" + l)
    if labels:
        names.append("tld:" + labels[-1])
        names.append("rd:" + ".".join(labels[-2:]))
    head = rest[:120]
    for n in (3, 4):
        for j in range(len(head) - n + 1):
            names.append(f"p{n}:" + head[j:j + n])
    for t in path_tokens(rest):
        names.append("pt:" + t)
    names.append(f"hlen:{min(len(host) // 4, 15)}")
    names.append(f"dots:{min(host.count('.'), 8)}")
    names.append(f"hyph:{min(host.count('-'), 5)}")
    if any(c in "0123456789" for c in host):
        names.append("hdig")
    parts = host.split(".")
    if len(parts) == 4 and all(p.isascii() and p.isdigit() and int(p) < 256 for p in parts):
        names.append("ip")
    if at:
        names.append("at")
    if port:
        names.append("port")
    names.append(f"plen:{len(rest).bit_length()}")
    if "?" in rest:
        names.append("q")
    path = rest
    for c in "?#":
        i = path.find(c)
        if i != -1:
            path = path[:i]
    segs = [s for s in path.split("/") if s]
    names.append(f"nseg:{min(len(segs), 8)}")
    if segs and "." in segs[-1]:
        ext = segs[-1].rsplit(".", 1)[1]
        if 0 < len(ext) <= 5 and ext.isascii() and ext.isalnum():
            names.append("ext:" + ext)
    return sorted({fnv1a(n) % DIM for n in names})
