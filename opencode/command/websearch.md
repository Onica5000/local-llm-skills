---
description: Search the web (keyless, no API) and use the results to answer
---
You ran a web search for: **$ARGUMENTS**

Live results from the local keyless search tool:

!`python "{{SKILLS_DIR}}\web-search\scripts\web_search.py" "$ARGUMENTS" -n 6`

Using the results above, answer the user's request. If you need the full text of a
result, fetch it with:

`python "{{SKILLS_DIR}}\web-search\scripts\web_search.py" --fetch "<url>"`

Always cite the URL(s) you actually used.

<!--
Install: copy this file to ~/.config/opencode/command/websearch.md and replace
{{SKILLS_DIR}} with your skills folder (e.g. C:\Users\<you>\.lmstudio\skills).
-->
