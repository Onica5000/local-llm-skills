---
name: web-search
description: Use whenever you need current information from the internet, to look something up, verify a fact, find documentation, or read a web page. Prefer the dedicated web-search tool if one is available; a keyless script is the fallback.
---

# web-search

Pick the best available method — they all hit DuckDuckGo (keyless) under the hood.

## 1. Preferred: a dedicated web-search TOOL (no approval prompt)
If you have a tool you can call directly, use it — it's the smoothest path:
- **LM Studio:** the `web_search` tool (search) and `fetch_url` tool (read a page) from the
  *web-search-plus* plugin. Call them directly.
- **opencode:** the `websearch` tool (search) and the built-in `webfetch` tool (read a page).

Call the search tool first, then read the most relevant 1-2 results with the fetch/read tool
before answering. Always cite the URLs you used.

## 2. Fallback: the keyless script (when no tool is available)
If neither tool exists in this environment, run the bundled script (note: on this machine the
host shell may ask for confirmation):
```powershell
python "{{SKILLS_DIR}}\web-search\scripts\web_search.py" "your query"
python "{{SKILLS_DIR}}\web-search\scripts\web_search.py" --fetch "https://example.com/article"
```

## Workflow & rules
1. Search to get candidate URLs.
2. **Read** the best 1-2 (fetch/read tool, or `--fetch`) before stating any fact — snippets are short and can mislead.
3. Cite the URL(s) you actually used.
- If you get "no results" or a rate-limit, rephrase with fewer/more specific keywords and retry once.
- For heavy/repeated searching, the plugin can be pointed at Tavily/SearXNG (see its settings) to avoid DuckDuckGo rate limits.
