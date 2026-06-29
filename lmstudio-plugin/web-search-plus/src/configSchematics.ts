import { createConfigSchematics } from "@lmstudio/sdk";

export const configSchematics = createConfigSchematics()
  .field(
    "backend",
    "select",
    {
      displayName: "Search backend",
      hint: "DuckDuckGo needs no setup. Tavily/SearXNG are heavier-duty but need a key/URL in the plugin's global settings.",
      options: [
        { value: "duckduckgo", displayName: "DuckDuckGo (keyless, default)" },
        { value: "tavily", displayName: "Tavily (needs API key)" },
        { value: "searxng", displayName: "SearXNG (needs instance URL)" },
      ],
    },
    "duckduckgo",
  )
  .field(
    "defaultMaxResults",
    "numeric",
    {
      displayName: "Default results",
      hint: "How many search results to return when the model doesn't specify.",
      slider: { min: 1, max: 20, step: 1 },
      int: true,
    },
    6,
  )
  .field(
    "fetchMaxChars",
    "numeric",
    {
      displayName: "Max characters when reading a page",
      hint: "fetch_url truncates page text to this many characters.",
      slider: { min: 1000, max: 20000, step: 500 },
      int: true,
    },
    6000,
  )
  .build();

export const globalConfigSchematics = createConfigSchematics()
  .field(
    "tavilyApiKey",
    "string",
    {
      displayName: "Tavily API key",
      hint: "Required only if the backend is Tavily. Free tier at tavily.com. Leave empty otherwise.",
    },
    "",
  )
  .field(
    "searxngUrl",
    "string",
    {
      displayName: "SearXNG instance URL",
      hint: "Required only if the backend is SearXNG. e.g. https://searx.example.org (JSON output enabled).",
    },
    "",
  )
  .field(
    "requestTimeoutMs",
    "numeric",
    {
      displayName: "Request timeout (ms)",
      hint: "How long to wait for the search backend / a page before giving up.",
      slider: { min: 1000, max: 30000, step: 500 },
      int: true,
    },
    12000,
  )
  .build();
