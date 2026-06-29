/**
 * websearch - native opencode tool: keyless web search via DuckDuckGo.
 *
 * Drop this file in ~/.config/opencode/tool/ (global) or .opencode/tool/ (project).
 * No build step, no API key, no external dependency beyond what opencode ships.
 * The model calls it directly as the `websearch` tool.
 *
 * Better than the shell/command approach: structured results, no python, no
 * tool-confirmation prompt for running a shell command.
 */
import { tool } from "@opencode-ai/plugin/tool";

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/124.0 Safari/537.36";

type Hit = { title: string; url: string; snippet: string };

function clean(s: string): string {
  return s
    .replace(/<[^>]*>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#x27;|&#39;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function decodeDdg(href: string): string {
  const m = href.match(/[?&]uddg=([^&]+)/);
  if (m) return decodeURIComponent(m[1]);
  if (href.startsWith("//")) return "https:" + href;
  return href;
}

async function ddgHtml(query: string, max: number, signal: AbortSignal): Promise<Hit[]> {
  // NOTE: must be GET. The POST form returns an HTTP 202 anti-bot page (this is the
  // bug that made the old web-search plugins flaky). GET returns real results.
  const res = await fetch("https://html.duckduckgo.com/html/?" + new URLSearchParams({ q: query }), {
    headers: { "User-Agent": UA },
    signal,
  });
  if (!res.ok) throw new Error(`DuckDuckGo HTTP ${res.status}`);
  const html = await res.text();
  const hits: Hit[] = [];
  const re = /<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) && hits.length < max) {
    const url = decodeDdg(m[1]);
    if (!url.startsWith("http")) continue;
    const after = html.slice(re.lastIndex, re.lastIndex + 3000);
    const sn = after.match(/class="result__snippet"[^>]*>([\s\S]*?)<\/a>/);
    hits.push({ title: clean(m[2]), url, snippet: sn ? clean(sn[1]) : "" });
  }
  return hits;
}

async function ddgLite(query: string, max: number, signal: AbortSignal): Promise<Hit[]> {
  const res = await fetch("https://lite.duckduckgo.com/lite/?" + new URLSearchParams({ q: query }), {
    headers: { "User-Agent": UA },
    signal,
  });
  if (!res.ok) throw new Error(`DuckDuckGo lite HTTP ${res.status}`);
  const html = await res.text();
  const hits: Hit[] = [];
  const re = /<a[^>]+rel="nofollow"[^>]+href="([^"]+uddg=[^"]+)"[^>]*>([\s\S]*?)<\/a>/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) && hits.length < max) {
    const url = decodeDdg(m[1].replace(/&amp;/g, "&"));
    if (url.startsWith("http")) hits.push({ title: clean(m[2]), url, snippet: "" });
  }
  return hits;
}

// Optional heavier-duty backends, enabled by env vars (else keyless DuckDuckGo is used):
//   TAVILY_API_KEY=...     -> Tavily   |   SEARXNG_URL=https://...  -> SearXNG
async function tavily(query: string, max: number, key: string, signal: AbortSignal): Promise<Hit[]> {
  const res = await fetch("https://api.tavily.com/search", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    body: JSON.stringify({ query, max_results: max, search_depth: "basic" }),
    signal,
  });
  if (!res.ok) throw new Error(`Tavily HTTP ${res.status}`);
  const data: any = await res.json();
  return (data.results ?? []).slice(0, max).map((r: any) => ({
    title: String(r.title ?? ""),
    url: String(r.url ?? ""),
    snippet: clean(String(r.content ?? "")),
  }));
}

async function searxng(query: string, max: number, baseUrl: string, signal: AbortSignal): Promise<Hit[]> {
  const url = baseUrl.replace(/\/+$/, "") + "/search?" + new URLSearchParams({ q: query, format: "json", safesearch: "1" });
  const res = await fetch(url, { headers: { "User-Agent": UA }, signal });
  if (!res.ok) throw new Error(`SearXNG HTTP ${res.status}`);
  const data: any = await res.json();
  return (data.results ?? []).slice(0, max).map((r: any) => ({
    title: String(r.title ?? ""),
    url: String(r.url ?? ""),
    snippet: clean(String(r.content ?? "")),
  }));
}

export default tool({
  description:
    "Search the web (keyless, via DuckDuckGo) and return ranked results with title, URL, " +
    "and snippet. Use for anything needing current/public info: news, releases, prices, " +
    "docs, facts about living people. Cite the URLs; read a page with the webfetch tool " +
    "before stating details from it.",
  args: {
    query: tool.schema.string().min(1).describe("Search query in natural language."),
    maxResults: tool.schema
      .number()
      .int()
      .min(1)
      .max(20)
      .optional()
      .describe("Max results to return (default 6)."),
  },
  async execute(args, ctx) {
    const max = args.maxResults ?? 6;
    let hits: Hit[] = [];
    let used = "duckduckgo";

    // Optional premium backend via env var; falls back to DuckDuckGo on any failure.
    const tavilyKey = process.env.TAVILY_API_KEY;
    const searxngUrl = process.env.SEARXNG_URL;
    try {
      if (tavilyKey) { used = "tavily"; hits = await tavily(args.query, max, tavilyKey, ctx.abort); }
      else if (searxngUrl) { used = "searxng"; hits = await searxng(args.query, max, searxngUrl, ctx.abort); }
    } catch {
      hits = []; used = "duckduckgo"; // fall back to DDG below
    }

    if (hits.length === 0) {
      used = "duckduckgo";
      try {
        hits = await ddgHtml(args.query, max, ctx.abort);
      } catch {
        /* fall through to lite */
      }
    }
    if (hits.length === 0) {
      try {
        hits = await ddgLite(args.query, max, ctx.abort);
      } catch (e) {
        return `Web search failed: ${e instanceof Error ? e.message : String(e)}. Check the connection or rephrase.`;
      }
    }
    if (hits.length === 0) {
      return `No results for "${args.query}". Try fewer, more specific keywords.`;
    }
    const body = hits
      .map((h, i) => `${i + 1}. ${h.title}\n   ${h.url}${h.snippet ? `\n   ${h.snippet}` : ""}`)
      .join("\n\n");
    return {
      title: `${hits.length} result(s) for "${args.query}" (via ${used})`,
      output: `Web results for "${args.query}":\n\n${body}\n\nRead a page with the webfetch tool, then cite the URL(s) you used.`,
      metadata: { count: hits.length, backend: used, results: hits },
    };
  },
});
