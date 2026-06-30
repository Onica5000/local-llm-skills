<#
.SYNOPSIS
  Turn on graduated autonomy for opencode + LM Studio (Tier 1).
  - opencode: adds a `permission` block (allow safe, deny destructive, ask outward-facing)
  - opencode: installs the autonomous AGENTS.md rules + the `auto` agent
  - LM Studio: auto-approves sandboxed/read-only tools, leaves host shell (terminal) gated

  Idempotent. Backs up any file it edits to <file>.bak-autonomy. Close LM Studio first.
  See docs/autonomy.md for the full explanation and the manual equivalent.
#>
[CmdletBinding()]
param([switch]$IncludeFilesystemWrite)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot

function Backup($f) { if (Test-Path $f) { Copy-Item $f "$f.bak-autonomy" -Force } }

Write-Host "== Enabling graduated autonomy ==" -ForegroundColor Cyan

# ---------- opencode: permission block ----------
$ocJson = "$env:USERPROFILE\.config\opencode\opencode.json"
if (Test-Path $ocJson) {
  Backup $ocJson
  $j = Get-Content $ocJson -Raw | ConvertFrom-Json
  $bash = [ordered]@{
    "*" = "allow"
    "rm *" = "deny"; "rm -rf*" = "deny"; "rmdir *" = "deny"; "rd *" = "deny"; "del *" = "deny"; "erase *" = "deny"
    "Remove-Item*" = "deny"; "Clear-Content*" = "deny"
    "format *" = "deny"; "diskpart*" = "deny"; "bcdedit*" = "deny"; "dd *" = "deny"; "mkfs*" = "deny"; "cipher /w*" = "deny"
    "reg delete*" = "deny"; "reg.exe delete*" = "deny"; "sc delete*" = "deny"; "schtasks /delete*" = "deny"; "shutdown*" = "deny"
    "git reset --hard*" = "deny"; "git clean*" = "deny"; "git push --force*" = "deny"; "gh repo delete*" = "deny"
    "git push*" = "ask"; "winget install*" = "ask"; "choco install*" = "ask"
    "npm install -g*" = "ask"; "scoop install*" = "ask"
  }
  $perm = [ordered]@{ edit = "allow"; webfetch = "allow"; bash = $bash }
  $j | Add-Member permission ([pscustomobject]$perm) -Force
  ($j | ConvertTo-Json -Depth 20) | Set-Content -Encoding utf8 $ocJson
  Write-Host "  [ok] opencode.json permission block written"
} else { Write-Warning "  opencode.json not found; skipping permission block." }

# ---------- opencode: AGENTS.md + auto agent ----------
$ocDir = "$env:USERPROFILE\.config\opencode"
New-Item -ItemType Directory -Force -Path "$ocDir\agent" | Out-Null
Backup "$ocDir\AGENTS.md"
Copy-Item "$repo\opencode\AGENTS.md" "$ocDir\AGENTS.md" -Force
Copy-Item "$repo\opencode\agent\auto.md" "$ocDir\agent\auto.md" -Force
Write-Host "  [ok] opencode AGENTS.md + 'auto' agent installed"

# ---------- LM Studio: auto-approve safe tools ----------
$lms = "$env:USERPROFILE\.lmstudio\settings.json"
if (Test-Path $lms) {
  Backup $lms
  $s = Get-Content $lms -Raw | ConvertFrom-Json
  $safe = @(
    "onica5000/web-search-plus:*",   # our search plugin
    "khtsly/skills:*",               # skills engine
    "khtsly/computer:*",             # sandboxed Docker container - safe
    "lmstudio/js-code-sandbox:*",    # isolated JS sandbox - safe
    "lmstudio/rag-v1:*"              # read-only retrieval
  )
  if ($IncludeFilesystemWrite) { $safe += "markp03/filesystem-access:*" }  # host FS incl. writes
  $cur = @(); if ($s.chat.skipToolConfirmationPatterns) { $cur = @($s.chat.skipToolConfirmationPatterns) }
  $s.chat.skipToolConfirmationPatterns = @($cur + $safe | Select-Object -Unique)
  # keep host shell gated on purpose: do NOT add khtsly/terminal here.
  ($s | ConvertTo-Json -Depth 40) | Set-Content -Encoding utf8 $lms
  Write-Host "  [ok] LM Studio: safe tools auto-approved (host shell 'terminal' stays gated)"
} else { Write-Warning "  LM Studio settings.json not found; skipping." }

Write-Host ""
Write-Host "Done. Restart LM Studio / start a new opencode session." -ForegroundColor Green
Write-Host "opencode: run the autonomous mode with  opencode --agent auto" -ForegroundColor Green
Write-Host "Backups saved as *.bak-autonomy next to each edited file."
