<#
.SYNOPSIS
  Git safety checkpoint for autonomous runs. Snapshot your repo before letting a model
  loose, then roll back in one command if it makes a mess.

.EXAMPLE
  ./setup/checkpoint.ps1                  # save a checkpoint of the current repo state
  ./setup/checkpoint.ps1 -List           # list recent checkpoints
  ./setup/checkpoint.ps1 -Rollback       # restore the most recent checkpoint (asks first)
  ./setup/checkpoint.ps1 -Rollback -Clean -Yes   # also delete files created since, no prompt
  ./setup/checkpoint.ps1 -Path C:\my\repo        # operate on a specific repo

.NOTES
  A checkpoint = a commit of all current state (tracked + new files) plus a lightweight tag
  'checkpoint-<timestamp>'. Rollback does `git reset --hard <tag>` (and optionally
  `git clean -fd` for files created after). Recommended pre-flight before `opencode --agent auto`.
#>
[CmdletBinding(DefaultParameterSetName = "Save")]
param(
  [Parameter(ParameterSetName = "List")]   [switch]$List,
  [Parameter(ParameterSetName = "Rollback")][switch]$Rollback,
  [Parameter(ParameterSetName = "Rollback")][switch]$Clean,
  [Parameter(ParameterSetName = "Rollback")][string]$Tag,
  [switch]$Yes,
  [switch]$Init,
  [string]$Path = ".",
  [string]$Message = "before autonomous run"
)
$ErrorActionPreference = "Stop"
Set-Location $Path

# --- ensure we're in a git repo ---
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
  if ($Init) { git init | Out-Null; Write-Host "Initialized a new git repo here." }
  else { Write-Error "Not a git repository. Run 'git init' here first, or pass -Init."; return }
}

function Latest-Checkpoint { git tag -l "checkpoint-*" --sort=-creatordate | Select-Object -First 1 }

if ($List) {
  $tags = git tag -l "checkpoint-*" --sort=-creatordate
  if (-not $tags) { Write-Host "No checkpoints yet."; return }
  Write-Host "Checkpoints (newest first):" -ForegroundColor Cyan
  foreach ($t in $tags | Select-Object -First 15) {
    $info = git log -1 --format="%ci  %h  %s" "$t" 2>$null
    Write-Host ("  {0,-26} {1}" -f $t, $info)
  }
  return
}

if ($Rollback) {
  $target = if ($Tag) { $Tag } else { Latest-Checkpoint }
  if (-not $target) { Write-Error "No checkpoint to roll back to. Make one first (run with no args)."; return }
  $sha = (git rev-parse --short $target)
  $extra = if ($Clean) { "   +   git clean -fd  (deletes files created since)" } else { "" }
  Write-Host "About to restore checkpoint '$target' ($sha)." -ForegroundColor Yellow
  Write-Host "  -> git reset --hard $target$extra"
  if (-not $Yes) {
    $ans = Read-Host "This discards changes made after the checkpoint. Continue? (y/N)"
    if ($ans -ne "y") { Write-Host "Aborted."; return }
  }
  git reset --hard $target
  if ($Clean) { git clean -fd }
  Write-Host "Rolled back to $target." -ForegroundColor Green
  return
}

# --- default: SAVE a checkpoint ---
$ts  = Get-Date -Format "yyyyMMdd-HHmmss"
$tag = "checkpoint-$ts"
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
  git commit -q -m "checkpoint: $Message ($ts)" | Out-Null
  Write-Host "Committed current state." -ForegroundColor Green
} else {
  Write-Host "Working tree already clean - tagging current HEAD."
}
git tag $tag
$sha = git rev-parse --short HEAD
Write-Host "Checkpoint saved: $tag ($sha)" -ForegroundColor Green
Write-Host "Roll back later with:  ./setup/checkpoint.ps1 -Rollback        (latest)"
Write-Host "                       ./setup/checkpoint.ps1 -Rollback -Clean  (also remove new files)"
