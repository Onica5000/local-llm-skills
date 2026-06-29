import { text, tool, type ToolsProviderController } from "@lmstudio/sdk";
import { z } from "zod";
import { configSchematics, globalConfigSchematics } from "./configSchematics";

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
  const m = href.replace(/&amp;/g, "&").match(/[?&]uddg=([^&]+)/);
  if (m) return decodeURIComponent(m[1]);
  if (href.startsWith("//")) return "https:" + href;
  return href;
}

async function fetchText(url: string, timeoutMs: number, signal: AbortSignal): Promise<{ status: number; body: string }> {
  const ctrl = new AbortController();
  const onAbort = () => ctrl.abort();
  if (signal.aborted) ctrl.abort();
  else signal.addEventListener("abort", onAbort, { once: true });
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { headers: { "User-Agent": UA }, signal: ctrl.signal });
    return { status: res.status, body: await res.text() };
  } finally {
    clearTimeout(timer);
    signal.removeEventListener("abort", onAbort);
  }
}

// DuckDuckGo HTML endpoint via GET (the POST form returns an HTTP 202 anti-bot page;
// GET returns real results — this is why the common plugins are flaky).
async function ddgHtml(query: string, max: number, timeoutMs: number, signal: AbortSignal): Promise<Hit[]> {
  const { status, body } = await fetchText(
    "https://html.duckduckgo.com/html/?" + new URLSearchParams({ q: query }),
    timeoutMs,
    signal,
  );
  if (status !== 200) throw new Error(`DuckDuckGo HTTP ${status}`);
  const hits: Hit[] = [];
  const re = /<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(body)) && hits.length < max) {
    const url = decodeDdg(m[1]);
    if (!url.startsWith("http")) continue;
    const after = body.slice(re.lastIndex, re.lastIndex + 3000);
    const sn = after.match(/class="result__snippet"[^>]*>([\s\S]*?)<\/a>/);
    hits.push({ title: clean(m[2]), url, snippet: sn ? clean(sn[1]) : "" });
  }
  return hits;
}

async function ddgLite(query: string, max: number, timeoutMs: number, signal: AbortSignal): Promise<Hit[]> {
  const { body } = await fetchText(
    "https://lite.duckduckgo.com/lite/?" + new URLSearchParams({ q: query }),
    timeoutMs,
    signal,
  );
  const hits: Hit[] = [];
  const re = /<a[^>]+rel="nofollow"[^>]+href="([^"]+uddg=[^"]+)"[^>]*>([\s\S]*?)<\/a>/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(body)) && hits.length < max) {
    const url = decodeDdg(m[1]);
    if (url.startsWith("http")) hits.push({ title: clean(m[2]), url, snippet: "" });
  }
  return hits;
}

function pageToText(html: string, maxChars: number): string {
  let t = html.replace(/<(script|style|noscript)[^>]*>[\s\S]*?<\/\1>/gi, " ");
  t = t.replace(/<br\s*\/?>/gi, "\n").replace(/<\/(p|div|h[1-6]|li|tr)>/gi, "\n");
  t = clean(t).replace(/[ \t]+/g, " ");
  if (t.length > maxChars) t = t.slice(0, maxChars) + `\n\n[...truncated at ${maxChars} chars...]`;
  return t;
}

export async function toolsProvider(ctl: ToolsProviderController) {
  const config = ctl.getPluginConfig(configSchematics);
  const global = ctl.getGlobalPluginConfig(globalConfigSchematics);

  const webSearch = tool({
    name: "web_search",
    description: text`
      Search the web (keyless, via DuckDuckGo) and return ranked results with title, URL,
      and snippet. Use this for any question whose answer depends on current or public
      information: news, recent releases, prices, documentation, facts about living people.
      Summarise the snippets and cite the URLs. To read a full page, call fetch_url.
    `,
    parameters: {
      query: z.string().min(1).describe("Search query in natural language."),
      max_results: z.number().int().min(1).max(20).optional().describe("Max results (default from config)."),
    },
    implementation: async ({ query, max_results }, ctx) => {
      const max = max_results ?? config.get("defaultMaxResults");
      const timeoutMs = global.get("requestTimeoutMs");
      ctx.status(`Searching DuckDuckGo for "${query}"...`);
      let hits: Hit[] = [];
      try {
        hits = await ddgHtml(query, max, timeoutMs, ctx.signal);
      } catch (e) {
        if (ctx.signal.aborted) return { error: "Search cancelled." };
        ctx.warn(`Primary endpoint failed (${e instanceof Error ? e.message : e}); trying lite.`);
      }
      if (hits.length === 0 && !ctx.signal.aborted) {
        try {
          hits = await ddgLite(query, max, timeoutMs, ctx.signal);
        } catch (e) {
          return { error: `Web search failed: ${e instanceof Error ? e.message : String(e)}` };
        }
      }
      ctx.status(`${hits.length} result(s).`);
      if (hits.length === 0) return { query, results: [], note: "No results; try fewer, more specific keywords." };
      return { query, results: hits };
    },
  });

  const fetchUrl = tool({
    name: "fetch_url",
    description: text`
      Fetch a web page and return its readable text (HTML stripped, truncated). Use this
      AFTER web_search to read the actual content of a result before answering. Pass one
      http(s) URL.
    `,
    parameters: {
      url: z.string().url().describe("The http(s) URL to read."),
    },
    implementation: async ({ url }, ctx) => {
      const timeoutMs = global.get("requestTimeoutMs");
      const maxChars = config.get("fetchMaxChars");
      ctx.status(`Fetching ${url} ...`);
      try {
        const { status, body } = await fetchText(url, timeoutMs, ctx.signal);
        if (status !== 200) return { url, error: `HTTP ${status}` };
        return { url, text: pageToText(body, maxChars) };
      } catch (e) {
        if (ctx.signal.aborted) return { error: "Fetch cancelled." };
        return { url, error: `Could not fetch: ${e instanceof Error ? e.message : String(e)}` };
      }
    },
  });

  return [webSearch, fetchUrl];
}
