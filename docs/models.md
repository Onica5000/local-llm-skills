# Model routing & context tuning

Pick the right local model for the job — a 4B model is fast but unreliable at tool calls; the
9B models are the ones that can actually drive autonomy.

## Which model for what

| Task | Model | Why |
|---|---|---|
| **Autonomous / tool-use / general** | `qwen/qwen3.5-9b` | Strongest all-rounder here; reliable tool calls. The default + the `auto` agent. |
| **Coding** (write/refactor/debug) | `qwen2.5-coder-7b-instruct` | Code-specialized. The `coder` agent. |
| **Images** (identify/OCR/describe) | `qwen/qwen2.5-vl-7b` | The only vision model. The `vision` agent + `vision-image` skill. |
| **Hard reasoning / planning** | `deepseek-r1-0528-qwen3-8b` | Good at thinking through a plan — but reasoning models can be verbose and shakier at clean tool calls, so plan with it, then execute with qwen3.5-9b. |
| **Quick/cheap chat, low VRAM** | `gemma-3-4b` / `phi-4-mini-reasoning` | Fast, but **weak at tool calling** — don't use them for autonomous tool work. |
| **Embeddings (RAG)** | `text-embedding-nomic-embed-text-v1.5` | For retrieval, not chat. |

**Tool-calling reliability** is the thing that makes or breaks autonomy. Prefer `qwen3.5-9b`
and `qwen2.5-coder-7b`. The 4B models frequently emit malformed tool calls — fine for plain
chat, bad for agents.

## opencode agents (per-task models)

Switch agent with `--agent <name>` (or Tab in the TUI). Each carries the autonomy guardrails:

```powershell
opencode --agent auto      # qwen3.5-9b  - general autonomous work
opencode --agent coder     # qwen2.5-coder-7b - coding
opencode --agent vision    # qwen2.5-vl-7b - image understanding
```
Defined in `~/.config/opencode/agent/*.md` (and shipped in this repo under `opencode/agent/`).

## Context window (the real autonomy bottleneck)

LM Studio's `defaultContextLength` is raised to **16384** in this setup (was 10000). Multi-step
autonomous work fills context fast (plan + tool outputs + history), so more headroom = fewer
"lost the thread" moments.

Trade-offs on this 8GB RX 6600:
- Bigger context = more VRAM and slower; a 9B model already splits GPU/CPU at 8GB.
- 16384 is a balanced default. Push to 24k–32k for big tasks if you accept slower / more CPU
  offload; drop back to ~8k for snappy short chats.
- You can override context **per model** at load time in LM Studio (the load dialog), which
  beats one global value.
- opencode reads whatever the loaded model exposes — set it on the LM Studio side.

Progressive-disclosure skills (this kit) already minimize idle context use, so most of the
window stays free for actual work.
