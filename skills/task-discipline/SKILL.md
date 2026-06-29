---
name: task-discipline
description: Load for any multi-step or long-running task you should complete autonomously. How to plan, keep a running checklist that survives a small context window, recover from errors without stalling, and decide when to proceed vs. stop and ask.
---

# task-discipline

For work that takes more than one or two steps, stay organized so you can finish it without a
human re-steering you — and so you don't lose the thread when context fills up.

## 1. Plan first, in writing
Before starting, write a short numbered checklist of the steps. Keep it in your reply and
**update it as you go** (mark items done). On a small context window this is your memory — if
you get summarized mid-task, the checklist tells you where you were.
```
Plan:
[x] 1. Read the failing module
[ ] 2. Fix the off-by-one in parse()
[ ] 3. Run pytest
[ ] 4. Verify the original error is gone
```

## 2. Work one step at a time
Do a step, observe the result, update the checklist, move on. Don't fire many speculative
actions at once. Prefer the most direct tool for each step (a CLI tool over hand-written code;
the right skill for the domain).

## 3. Recover from errors — don't stall (max 3 tries)
On failure: read the actual error -> form a specific hypothesis -> change ONE thing -> retry.
- Never repeat the identical failing command hoping for a different result.
- After 3 real attempts, stop and report: what you tried, the exact error, your best guess.
- A missing tool is not a dead end — load `install-tools` and offer to install it.

## 4. Proceed vs. stop
- **Proceed** (state your assumption, keep going) when the requirement is merely underspecified
  and a sensible default exists.
- **Stop and ask** only for: destructive/irreversible actions, anything outward-facing
  (push/publish/send/deploy), installing software, or a fork where guessing wrong wastes
  significant work.

## 5. Finish properly
- Run the `verify-work` checks before declaring done.
- Give a short summary: what changed, what you verified (with the command + result), and any
  follow-ups or things you deliberately left for the user.
