# Autonomy setup — let local models work without constant approval

This explains how the kit makes LM Studio and opencode operate autonomously, exactly what gets
changed, and how to replicate it on a fresh machine (scripted **and** by hand).

## Philosophy: graduated autonomy

With small local models (4–9B) that can hallucinate tool arguments, blanket "approve everything"
is dangerous. The rule instead is:

> **Auto-run anything read-only or reversible. Gate only what is destructive or outward-facing.**

So: reading/editing/creating files, running builds/tests, web search, `git add`/`commit` → no
prompt. Deleting things, `rm -rf`, `git reset --hard`, force-push, formatting disks → blocked.
`git push`, publishing, installing software → ask first.

## One-command setup

```powershell
# from the repo root (close LM Studio first)
./setup/setup.ps1            # installs skills, tools, junction, scanner
./setup/enable-autonomy.ps1  # applies the autonomy config below
# optional: also auto-approve host filesystem writes in LM Studio
./setup/enable-autonomy.ps1 -IncludeFilesystemWrite
```
Both scripts are idempotent and back up every file they edit to `*.bak-autonomy`.

---

## What changes, exactly (for manual replication)

### opencode

**1. `~/.config/opencode/opencode.json` — a `permission` block** (last-match-wins patterns):
```jsonc
"permission": {
  "edit": "allow",
  "webfetch": "allow",
  "bash": {
    "*": "allow",
    "rm *": "deny", "rm -rf*": "deny", "rmdir *": "deny", "del *": "deny",
    "Remove-Item*": "deny", "format *": "deny", "diskpart*": "deny",
    "git reset --hard*": "deny", "git clean*": "deny", "git push --force*": "deny",
    "git push*": "ask", "winget install*": "ask", "choco install*": "ask",
    "npm install -g*": "ask", "scoop install*": "ask"
  }
}
```
opencode defaults most actions to `allow`, so without this block destructive commands would run
unprompted. This block is what makes "allow by default" *safe*.

**2. `~/.config/opencode/AGENTS.md`** — rewritten from "ask a lot" to the graduated-autonomy
doctrine (act on reversible work, verify before done, recover from errors, stop only for the
dangerous few). It's loaded into every session automatically.

**3. `~/.config/opencode/agent/auto.md`** — a switchable high-autonomy agent. Use it with:
```powershell
opencode --agent auto      # or press Tab in the TUI to switch agents
```
It carries the same permission guardrails plus an "finish the task end to end" system prompt.

### LM Studio

LM Studio prompts for every tool not in `chat.skipToolConfirmationPatterns`, and it can only
whitelist **per tool** (no per-command patterns). So we auto-approve the tools that are
**safe by construction** and leave the host shell gated:

| Auto-approved (added to the whitelist) | Why it's safe |
|---|---|
| `onica5000/web-search-plus:*` | read-only web search |
| `khtsly/skills:*` | just reads skill files |
| `khtsly/computer:*` | runs in an **isolated Docker container**, not the host |
| `lmstudio/js-code-sandbox:*` | **isolated** JS sandbox |
| `lmstudio/rag-v1:*` | read-only document retrieval |

**Left gated on purpose:** `khtsly/terminal` (real host shell — it can't block `rm`, so every
command still asks). `markp03/filesystem-access` writes to the host; it's only auto-approved if
you pass `-IncludeFilesystemWrite`.

> Full hands-off LM Studio (auto-approve the host shell too) is possible by adding
> `"khtsly/terminal:*"` to the whitelist, but with a weak model that's risky — it would run any
> shell command, including destructive ones, with no checkpoint. Not recommended.

---

## Self-sufficiency (Tier 2)

Two skills back up the doctrine (both apps load them on demand):
- **`verify-work`** — a per-language checklist so the model *proves* a change works (runs
  tests/lint/type-check, re-reads edits) before saying "done".
- **`task-discipline`** — plan with a running checklist (survives the 10k context window),
  recover from errors with bounded retries, and decide proceed-vs-ask.

The `local-tools` primer and `AGENTS.md` both point the model at these.

## Unattended operation (Tier 3)

- **Headless opencode** — run a task non-interactively (great for scripting / scheduled jobs):
  ```powershell
  opencode run "update the changelog and run the tests" --agent auto
  ```
- **Audit trail** — review what an autonomous run did:
  - opencode keeps session history; `opencode` TUI → session list, or check `~/.local/share/opencode`.
  - LM Studio server logs: `~/.lmstudio/server-logs/` (and the in-app Developer logs).
- **Bigger context** — autonomy is bottlenecked by the 10k default window. Raise
  `defaultContextLength` in LM Studio (Settings) for autonomous sessions, and prefer the
  strongest local model (e.g. `qwen3.5-9b` / `qwen2.5-coder-7b`) for multi-step work.

## Safety notes

- The deny-list is the safety net — keep it. Don't let a model route around a denied command.
- Run autonomous work inside a **git repo / scoped working dir** so mistakes are recoverable.
- Revert everything: restore the `*.bak-autonomy` files this setup created.
