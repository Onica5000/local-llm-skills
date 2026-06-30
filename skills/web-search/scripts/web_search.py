#!/usr/bin/env python3
"""
web_search.py - keyless web search + page reader for local LLMs.

Zero external dependencies (Python stdlib only). Uses DuckDuckGo's HTML
endpoints, with an automatic fallback, and can fetch a page and strip it to
plain text so the model can actually read a result.

USAGE
  python web_search.py "your query"            # search, print top results
  python web_search.py "your query" -n 8       # return up to 8 results
  python web_search.py --fetch <URL>           # download a page as plain text
  python web_search.py "query" --json          # machine-readable JSON output

Designed to be robust: if one DuckDuckGo endpoint changes or rate-limits, it
tries the lite endpoint before giving up.
"""
import sys
import re
import json
import html
import gzip
import time
import argparse
import urllib.parse
import urllib.request
from io import BytesIO

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
TIMEOUT = 20

# Windows consoles default to cp1252, which crashes on non-Latin page text.
# Force UTF-8 output so --fetch never dies on a unicode character.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except Exception:  # noqa: BLE001
        pass


def _get(url, data=None):
    """HTTP GET/POST returning decoded text, transparently handling gzip."""
    headers = {
        "User-Agent": UA,
        "Accept": "text/html,application/xhtml+xml",
        "Accept-Encoding": "gzip",
        "Accept-Language": "en-US,en;q=0.9",
    }
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        raw = resp.read()
        if resp.headers.get("Content-Encoding") == "gzip":
            raw = gzip.GzipFile(fileobj=BytesIO(raw)).read()
        return raw.decode("utf-8", errors="replace")


def _clean(text):
    return html.unescape(re.sub(r"<.*?>", "", text)).strip()


def _decode_ddg_link(href):
    """DDG wraps results as /l/?uddg=<urlencoded>. Unwrap to the real URL."""
    if "uddg=" in href:
        q = urllib.parse.urlparse(href).query
        params = urllib.parse.parse_qs(q)
        if "uddg" in params:
            return params["uddg"][0]
    if href.startswith("//"):
        return "https:" + href
    return href


def _ddg_html(query, n):
    """DuckDuckGo HTML endpoint (GET — the POST form returns an anti-bot 202)."""
    url = "https://html.duckduckgo.com/html/?" + urllib.parse.urlencode({"q": query})
    body = _get(url)
    out = []
    for m in re.finditer(r'<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>(.*?)</a>', body, re.S):
        link = _decode_ddg_link(html.unescape(m.group(1)))
        if not link.startswith("http"):
            continue
        # snippet sits ~1500 chars after the title link; scan a window for it
        after = body[m.end():m.end() + 3000]
        sn = re.search(r'class="result__snippet"[^>]*>(.*?)</a>', after, re.S)
        out.append({"title": _clean(m.group(2)), "url": link, "snippet": _clean(sn.group(1)) if sn else ""})
        if len(out) >= n:
            break
    return out


def _ddg_lite(query, n):
    """Lite endpoint fallback (rel=nofollow uddg links)."""
    url = "https://lite.duckduckgo.com/lite/?" + urllib.parse.urlencode({"q": query})
    body = _get(url)
    out = []
    for m in re.finditer(r'<a[^>]+rel="nofollow"[^>]+href="([^"]+uddg=[^"]+)"[^>]*>(.*?)</a>', body, re.S):
        link = _decode_ddg_link(html.unescape(m.group(1)))
        if link.startswith("http"):
            out.append({"title": _clean(m.group(2)), "url": link, "snippet": ""})
        if len(out) >= n:
            break
    return out


def search(query, n=6):
    """Return a list of {title, url, snippet} dicts, with backoff + lite fallback."""
    # Primary endpoint, retried with backoff to ride out transient rate-limits.
    for attempt in range(3):
        try:
            hits = _ddg_html(query, n)
            if hits:
                return hits[:n]
        except Exception as e:  # noqa: BLE001
            sys.stderr.write(f"[primary attempt {attempt + 1} failed: {e}]\n")
        if attempt < 2:
            time.sleep(1.5 * (attempt + 1))  # 1.5s, then 3s
    # Fallback endpoint
    try:
        return _ddg_lite(query, n)[:n]
    except Exception as e:  # noqa: BLE001
        sys.stderr.write(f"[fallback endpoint failed: {e}]\n")
    return []


def fetch(url, max_chars=6000):
    """Download a page and return it as collapsed plain text."""
    body = _get(url)
    body = re.sub(r"<(script|style|noscript)[^>]*>.*?</\1>", " ", body, flags=re.S | re.I)
    body = re.sub(r"<br\s*/?>", "\n", body, flags=re.I)
    body = re.sub(r"</(p|div|h[1-6]|li|tr)>", "\n", body, flags=re.I)
    text = _clean(body)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n\s*\n\s*\n+", "\n\n", text)
    if len(text) > max_chars:
        text = text[:max_chars] + f"\n\n[...truncated at {max_chars} chars...]"
    return text


def main():
    ap = argparse.ArgumentParser(description="Keyless web search for local LLMs.")
    ap.add_argument("query", nargs="*", help="search terms")
    ap.add_argument("-n", "--max", type=int, default=6, help="max results (default 6)")
    ap.add_argument("--fetch", metavar="URL", help="fetch a URL as plain text instead of searching")
    ap.add_argument("--json", action="store_true", help="output JSON")
    args = ap.parse_args()

    if args.fetch:
        text = fetch(args.fetch)
        if args.json:
            print(json.dumps({"url": args.fetch, "text": text}, indent=2))
        else:
            print(f"# {args.fetch}\n\n{text}")
        return

    query = " ".join(args.query).strip()
    if not query:
        ap.error("provide a search query, or use --fetch <URL>")

    hits = search(query, args.max)
    if args.json:
        print(json.dumps(hits, indent=2))
        return

    if not hits:
        print("No results (both DuckDuckGo endpoints returned nothing — try rephrasing, "
              "or check the internet connection).")
        return

    print(f"# Web results for: {query}\n")
    for i, h in enumerate(hits, 1):
        print(f"{i}. **{h['title']}**")
        print(f"   {h['url']}")
        if h["snippet"]:
            print(f"   {h['snippet']}")
        print()
    print("To read one of these, run: python web_search.py --fetch \"<url>\"")


if __name__ == "__main__":
    main()
