---
name: verify-work
description: Load before declaring any task done. A checklist for actually verifying a change worked — running tests/linters/type-checks per language, re-reading edits, and confirming output — instead of assuming success.
---

# verify-work

You are not done until you have **checked** that the work is correct. Assuming success is the
#1 cause of an autonomous run going wrong. Always verify, then report what you ran and saw.

## Universal steps
1. **Re-read your edit.** Open the changed lines; confirm syntax, indentation, and that you
   changed what you intended (and nothing else).
2. **Run the right check** (below) and READ the output. Don't just run it — interpret it.
3. **Fix and re-check** on failure. Report "done" only after a check actually passes.

## Per-language / per-task checks
| Task | Verify with |
|---|---|
| Python | `python -c "import ast,sys; ast.parse(open('f.py',encoding='utf-8').read())"` for syntax; `python f.py` or `pytest -q` to run; `ruff check` if available |
| Node/TS | `node --check f.js`; `tsc --noEmit` for types; `npm test` |
| JSON | `python -c "import json;json.load(open('f.json',encoding='utf-8-sig'))"` |
| PowerShell | run it with safe/dummy args; remember PS 5.1 has no `&&`/`??`; .ps1 must be ASCII |
| A CLI tool you installed | `Get-Command <tool>` then `<tool> --version` |
| A file you generated (pdf/img/gif/audio) | inspect it: `ffprobe`/`magick identify`/open dimensions — don't trust that it wrote correctly |
| Web/API change | actually call the endpoint and check the status + body |
| An edit to fix a bug | reproduce the original failure first, then confirm it's gone |

## Rules
- A green check beats a confident claim. If you can't verify, SAY you couldn't and why.
- Quantify: "ran pytest, 12 passed" not "tests look fine".
- If verification needs something destructive or outward-facing, stop and ask (see autonomy rules).
- Don't loop forever: if a check keeps failing, switch to the `task-discipline` recovery rule.
