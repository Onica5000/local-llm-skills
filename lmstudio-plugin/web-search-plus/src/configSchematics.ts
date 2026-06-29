import { createConfigSchematics } from "@lmstudio/sdk";

export const configSchematics = createConfigSchematics()
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
    "requestTimeoutMs",
    "numeric",
    {
      displayName: "Request timeout (ms)",
      hint: "How long to wait for DuckDuckGo / a page before giving up.",
      slider: { min: 1000, max: 30000, step: 500 },
      int: true,
    },
    12000,
  )
  .build();
