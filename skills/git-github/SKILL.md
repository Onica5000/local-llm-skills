---
name: git-github
description: Use for version control and GitHub operations â€” git (status/diff/branch/commit/log), git-lfs, tig (history TUI), and the gh CLI (PRs, issues, repos, releases, gists, Actions). Already authenticated as Onica5000.
---

# git-github

git 2.53, git-lfs, `tig` (history TUI), and **gh 2.93** (authenticated as **Onica5000**,
HTTPS via gh) are installed.

## git â€” everyday
```powershell
git status
git diff                 # unstaged changes
git diff --staged        # staged changes
git log --oneline -20
git branch               # list; git switch -c <name> to create+switch
git add <files>; git commit -m "message"
git pull ; git push
```
> Do NOT run commit/push/init or destructive git (`reset --hard`, `clean -fd`) unless the
> user explicitly asks. For writing commit messages, the `git-commit` skill has the format.

## gh â€” GitHub CLI
```powershell
gh auth status                       # confirm logged in
gh repo clone <owner>/<repo>
gh repo create <name> --private --source . --push
gh pr create --fill                  # open a PR from current branch
gh pr list ; gh pr view <n> ; gh pr checkout <n>
gh issue list ; gh issue create --title "..." --body "..."
gh release create v1.0.0 ./dist/*    # release with assets
gh run list ; gh run view <id>       # GitHub Actions
gh gist create file.txt              # quick gist
```

## tig â€” browse history visually
```powershell
tig                  # full log TUI;  tig <file> for one file's history;  q to quit
```

## Rules
- Large binaries â†’ track with `git lfs track "*.ext"` before committing.
- Prefer `gh` for anything GitHub-side (PRs/issues/releases) â€” it's already authenticated,
  no token juggling.

