---
name: web-search
description: Use whenever you need current information from the internet, to look something up, verify a fact, find documentation, or read a web page. Provides a reliable keyless search command (no API key, no flaky plugin) plus a page-reader that returns clean text.
---

# web-search

This machine has a self-contained web search tool. It needs **no API key** and does not
depend on any plugin. It runs DuckDuckGo under the hood and can also fetch a page and
return it as plain text so you can read it.

Script location:
`{{SKILLS_DIR}}\web-search\scripts\web_search.py`

## Search the web
```powershell
python "{{SKILLS_DIR}}\web-search\scripts\web_search.py" "your query here"
```
Returns a numbered list of titles, URLs, and snippets. Use `-n 8` to get more results.

## Read a specific page (turn a URL into readable text)
```powershell
python "{{SKILLS_DIR}}\web-search\scripts\web_search.py" --fetch "https://example.com/article"
```
Returns the page stripped to plain text (truncated to ~6000 chars).

## JSON output (when you need to parse results in code)
```powershell
python "{{SKILLS_DIR}}\web-search\scripts\web_search.py" "query" --json
```

## Typical workflow
1. **Search** for the question to get candidate URLs.
2. Pick the most relevant 1â€“2 results.
3. **`--fetch`** those URLs to read the actual content before answering.
4. Cite the URL(s) you used in your answer.

## Notes
- Always `--fetch` a result before stating a fact from it â€” snippets are short and can be
  misleading. Read the page.
- If you get "No results", rephrase the query (fewer, more specific keywords) and retry once.
- This uses `python` (Python 3.14 at `C:\Python314`). If `python` isn't found, load the
  `install-tools` skill â€” but Python is already installed here.
- Quote URLs and queries (they contain `&`, `?`, spaces).

