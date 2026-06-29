---
name: local-tools
description: Read FIRST whenever a task might need a command-line tool, program, or to run a script on this machine. Describes this PC's shell rules and maps the other skills that cover each tool domain (media, audio, images, web search, installing tools, git, etc.).
---

# local-tools

This Windows PC has a toolbox of CLI programs installed. Before saying "I can't do that,"
check the map below — there is probably a tool for it. When a task touches one of these
domains, load that domain's skill for the exact commands.

> **Personalize this file:** run `setup/scan-tools.ps1` from the skills repo to regenerate
> this primer with YOUR machine's detected tools, versions, and hardware. Until then, the
> map below is generic.

- **Default shell:** PowerShell **5.1** (Windows PowerShell) unless you know PowerShell 7 is installed.
- **Full reference (optional):** `{{REFERENCE_FILE}}` — a long file listing every installed tool; read only if a skill doesn't answer your question.

---

## CRITICAL PowerShell 5.1 rules — follow these every time

1. **No PS7 syntax.** `&&`, `||`, `??`, `??=`, `?.`, `?[]`, ternary `? :` FAIL in 5.1.
   Use `;` to chain, and `if ($?) { ... }` to run-on-success.
2. **`curl` is NOT curl** — it's an alias for `Invoke-WebRequest`. Call **`curl.exe`** for real curl.
3. **`convert` is NOT ImageMagick** — it's a Windows disk tool. Use **`magick`**.
4. **Paths use backslashes** (`C:\...`). Quote paths with spaces.
5. Run a program with `& "C:\path\to\app.exe" args`, or just `toolname args` if it's on PATH.
6. **Check if a tool exists:** `Get-Command <name> -ErrorAction SilentlyContinue`.

---

## Map of tool skills (load the one you need — do NOT load them all)

| If the task involves… | Load skill |
|---|---|
| Installing / downloading a missing tool or package | `install-tools` |
| Searching the web, looking something up online | `web-search` |
| Video/audio convert, encode, GPU encode, streaming | `media-ffmpeg` |
| Audio editing, text-to-speech, voice cloning | `audio-sox-tts` |
| Image convert/resize/edit, batch image processing | `images-magick-gimp` |
| Understanding/reading an image (identify, OCR, describe) | `vision-image` |
| Converting documents (md/docx/pdf/epub) | `documents-pandoc` |
| Writing Python for media/ML (ffmpeg bindings, whisper, etc.) | `python-ml-libs` |
| 3D render, video editing app, screen capture | `video-apps` |
| Android phone control, adb, screen mirroring | `android-adb` |
| Git or GitHub operations | `git-github` |
| Docker, containers, Kubernetes | `containers-k8s` |
| SSH, curl, OpenSSL, certificates, networking | `network-crypto` |
| Zip/7z/tar archives, robust file copy | `archives-files` |
| Multi-step / long-running work, planning, error recovery | `task-discipline` |
| Checking that a change actually worked before saying done | `verify-work` |

If no skill matches, check the full reference file above (if present).

---

## Autonomy doctrine — work without constant approval

Act on your own for routine, **reversible** work; stop only for the dangerous few.
- **Just do it** (no asking): read/list/search files; edit or create files for the task; run
  builds, linters, and **tests**; search the web; retry after fixing an error.
- **Stop and ask** only for: deleting things you didn't create, other destructive/irreversible
  acts, anything **outward-facing** (push/publish/send/deploy), and **installing software**.
- **Verify before "done"** — run the check and read the result (load `verify-work`).
- **Recover, don't stall** — on error, diagnose and retry up to 3 times (load `task-discipline`).
- If a requirement is merely vague, pick the sensible default, state the assumption, and proceed.

---

## Honesty rule

Never claim a tool exists, or that you ran a command, unless you actually checked with
`Get-Command` or actually executed it. If a tool is missing, say so and load `install-tools`.
