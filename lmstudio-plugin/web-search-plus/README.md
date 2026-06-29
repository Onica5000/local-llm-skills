# web-search-plus (LM Studio plugin)

A keyless **web search + page reader** plugin for LM Studio. Gives your local model two
first-class tools it can call directly:

- **`web_search`** — DuckDuckGo search, returns title / URL / snippet.
- **`fetch_url`** — downloads a page and returns readable text (so the model can actually
  read a result, not just see a snippet).

## Why it's better than the usual web-search plugins

Most LM Studio web-search plugins POST to `html.duckduckgo.com`, which now returns an
**HTTP 202 anti-bot page** — so they silently return nothing. This plugin uses the **GET**
endpoint (which still returns real results), falls back to the `lite` endpoint, decodes
DuckDuckGo's redirect links, and adds the `fetch_url` reader the others lack. No API key,
no SearXNG instance to host, no configuration required.

## Install

```powershell
# from this folder
npm install
lms dev --install -y      # bundles + installs into LM Studio
```

Then in LM Studio, make sure the plugin is enabled for your chat. Ask the model something
that needs current info ("what's the latest LM Studio version?") and it will call
`web_search`, then `fetch_url` to read the best result.

## Develop

```powershell
npm install
lms dev                   # hot-reloading dev server
```

## Config (in LM Studio plugin settings)

Per-chat:
- **Search backend**: `DuckDuckGo` (keyless, default), `Tavily`, or `SearXNG`. If Tavily/SearXNG
  is selected but not configured (or it fails), it falls back to DuckDuckGo automatically.
- **Default results**: how many results when unspecified (default 6).
- **Max characters when reading a page**: `fetch_url` truncation (default 6000).

Global:
- **Tavily API key**: needed only for the Tavily backend (free tier at tavily.com).
- **SearXNG instance URL**: needed only for the SearXNG backend (JSON output enabled).
- **Request timeout (ms)**: default 12000.

## License

MIT
