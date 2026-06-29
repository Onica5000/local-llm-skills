# How it works

## Progressive disclosure

Both LM Studio (via its *Skills* plugin) and opencode implement the same idea: at the start of
a session they scan the skills folder and inject only a compact `<available_skills>` list —
each skill's **name + description + path**. That costs a few hundred tokens for the whole
library. When the model decides a skill is relevant, it reads that one `SKILL.md` (and only
then any scripts it references). With 14 skills installed you typically pay for 1–2 per task.

This is why a 26,000-character "all my tools" document is the wrong shape for a 10k-token
context window, but 14 small skills are not.

## One library, two apps

- **LM Studio** reads `skillsPaths` from `~/.lmstudio/plugin-data/lms-skills/settings.json`.
  We point it at `~/.lmstudio/skills` and raise `maxSkillsInContext` to 30.
- **opencode** reads `SKILL.md` skills from `~/.config/opencode/skill/`. Instead of copying,
  we make that a **directory junction** to `~/.lmstudio/skills`. One folder, both apps, no drift.

A junction (not a symlink) is used because it needs no admin rights on Windows.

## Anatomy of a skill

```
web-search/
├── SKILL.md      # YAML frontmatter (name, description) + instructions in Markdown
├── skill.json    # name/description/tags (LM Studio reads this for the injected summary)
└── scripts/
    └── web_search.py
```

- `SKILL.md` frontmatter `description` is what opencode shows in its list.
- `skill.json` `description` is what LM Studio shows. We keep both in sync.
- Scripts/assets are loaded only if the model follows an instruction that references them.

## Placeholders

The shipped skills use `{{SKILLS_DIR}}`, `{{USERPROFILE}}`, and `{{REFERENCE_FILE}}`.
`setup.ps1` replaces these with real paths at install time, so the model always sees absolute,
runnable paths (important — a local model can't resolve "the script in this skill's folder").

## The scanner

`scan-tools.ps1` walks a catalog of tool names, checks each with
`Get-Command <name> -ErrorAction SilentlyContinue`, detects CPU/GPU/OS/PowerShell version, and
writes a `local-tools/SKILL.md` listing only what's present — plus which GPU encoder family to
use (`*_nvenc` / `*_amf` / `*_qsv`). This is what makes the primer match *your* machine instead
of the author's.

## Web search design

`web_search.py` is intentionally dependency-free (Python stdlib only): it queries
DuckDuckGo's HTML endpoint, falls back to the lite endpoint, decodes DDG's redirect links, and
can fetch+strip a page to plain text. It forces UTF-8 stdout so it doesn't crash on the Windows
`cp1252` console when a page contains non-Latin characters. No API key, nothing to rot.
