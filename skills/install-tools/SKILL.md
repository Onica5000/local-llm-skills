---
name: install-tools
description: Use when a needed command-line tool, app, language, or library is MISSING and you need to download/install it on this Windows machine. Covers checking whether something is installed, then picking the right package manager (winget, choco, scoop, pip/uv, npm, cargo) and verifying the install.
---

# install-tools

When a tool you need is not present, follow this exact workflow. **Never edit PATH or
download random EXEs from the web â€” use a package manager.**

## Step 1 â€” Confirm it is actually missing
```powershell
Get-Command <name> -ErrorAction SilentlyContinue
```
If this prints a path, the tool exists â€” stop, just use it (check `local-tools` for
invocation quirks). Only continue if it returns nothing.

## Step 2 â€” Pick the right installer

| What you're installing | Use | Command |
|---|---|---|
| A Windows app / GUI program / CLI tool | **winget** (preferred) | `winget install <Id>` |
| Same, if winget has no package | **choco** | `choco install <pkg>` |
| A dev CLI tool, portable, no admin | **scoop** | `scoop install <pkg>` |
| A Python package | **uv** (fast) or pip | `uv pip install <pkg>`  Â·  `pip install <pkg>` |
| A Node package (global CLI) | **npm** | `npm install -g <pkg>` |
| A Rust crate / CLI | **cargo** | `cargo install <pkg>` |
| A local LLM model | **ollama** | `ollama pull <model>` |

Notes:
- **winget** is the default for real programs (ffmpeg, git, vlc, 7zip, etc.). Find the id:
  `winget search <name>`. Install: `winget install <Publisher.App>` (e.g. `winget install Gyan.FFmpeg`).
- **scoop** for dev tools you want without admin: `scoop search <name>` then `scoop install <name>`.
- **choco** sometimes needs an elevated shell. If it errors on permissions, tell the user to
  run the command in an Administrator PowerShell (you can prefix with `sudo` on Win11:
  `sudo choco install <pkg>`).
- **Python** lives at `C:\Python314`. Prefer `uv pip install` (much faster) over plain `pip`.

## Step 3 â€” Search before installing (find the correct package name)
```powershell
winget search <name>        # most apps
scoop search <name>         # dev/CLI tools
choco search <name>         # fallback
pip index versions <name>   # python (or just try: uv pip install <name>)
```

## Step 4 â€” Verify it worked
After installing, ALWAYS confirm:
```powershell
Get-Command <name> -ErrorAction SilentlyContinue
<name> --version
```
If `Get-Command` still can't find it, the install put it on PATH but **this shell is stale**.
Tell the user to open a NEW terminal (PATH is read at shell start), or give the full path to
the new EXE.

## Step 5 â€” Keep things current (only if asked)
```powershell
winget upgrade --all
scoop update *
choco upgrade all
```

## Rules
- Confirm with the user before installing anything large (ROCm, CUDA, IDEs, VMs) or anything
  that needs admin. State what you'll run first.
- Never run an install you can't name the exact package for â€” search first (Step 3).
- One tool at a time; verify each before moving on.

