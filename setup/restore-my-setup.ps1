<#
.SYNOPSIS
  Restore Onica's personal LM Studio + opencode skills setup from this backup.
  Run this if you reinstall Windows / LM Studio / opencode and want your exact
  working configuration back.

.NOTES
  - Restores the personal skills into ~/.lmstudio/skills
  - Re-creates the opencode -> lmstudio skills junction
  - Restores opencode config (opencode.json, AGENTS.md, /websearch command, mem config)
  - Sets the LM Studio skills engine path + raises the skill cap to 30
  CLOSE LM STUDIO before running so it picks up the changes on next launch.
#>
[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = "Stop"
$repo     = Split-Path -Parent $PSScriptRoot          # repo root
$personal = Join-Path $repo "personal"
$skillsDst   = "$env:USERPROFILE\.lmstudio\skills"
$lmsSettings = "$env:USERPROFILE\.lmstudio\plugin-data\lms-skills\settings.json"
$ocDir       = "$env:USERPROFILE\.config\opencode"

Write-Host "== Restoring personal skills setup ==" -ForegroundColor Cyan

# 1. Skills -> ~/.lmstudio/skills
New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null
Copy-Item "$personal\skills\*" -Destination $skillsDst -Recurse -Force
Write-Host "  [ok] skills restored to $skillsDst"

# 2. LM Studio skills engine: path + cap=30 (create/patch settings)
New-Item -ItemType Directory -Force -Path (Split-Path $lmsSettings) | Out-Null
if (Test-Path $lmsSettings) { $s = Get-Content $lmsSettings -Raw | ConvertFrom-Json } else { $s = [pscustomobject]@{} }
$s | Add-Member -NotePropertyName skillsPaths       -NotePropertyValue @($skillsDst) -Force
$s | Add-Member -NotePropertyName autoInject        -NotePropertyValue $true         -Force
$s | Add-Member -NotePropertyName maxSkillsInContext -NotePropertyValue 30           -Force
if (-not $s.PSObject.Properties['windowsShell']) { $s | Add-Member windowsShell "powershell" -Force }
($s | ConvertTo-Json -Depth 10) | Set-Content -Encoding utf8 $lmsSettings
Write-Host "  [ok] LM Studio skills engine: path set, cap=30, autoInject on"

# 3. opencode config
New-Item -ItemType Directory -Force -Path "$ocDir\command" | Out-Null
Copy-Item "$personal\opencode\opencode.json"      -Destination "$ocDir\opencode.json" -Force
Copy-Item "$personal\opencode\AGENTS.md"          -Destination "$ocDir\AGENTS.md" -Force
Copy-Item "$personal\opencode\opencode-mem.jsonc" -Destination "$ocDir\opencode-mem.jsonc" -Force
Copy-Item "$personal\opencode\command\websearch.md" -Destination "$ocDir\command\websearch.md" -Force
Write-Host "  [ok] opencode config restored"

# 4. opencode -> lmstudio skills junction (single source of truth)
$link = "$ocDir\skill"
if (Test-Path $link) {
  if ((Get-Item $link).LinkType -ne "Junction") {
    if (-not $Force) { Write-Warning "  $link exists and is NOT a junction. Re-run with -Force to replace it."; }
    else { Remove-Item $link -Recurse -Force; New-Item -ItemType Junction -Path $link -Target $skillsDst | Out-Null; Write-Host "  [ok] junction recreated" }
  } else { Write-Host "  [ok] junction already present" }
} else {
  New-Item -ItemType Junction -Path $link -Target $skillsDst | Out-Null
  Write-Host "  [ok] junction created: $link -> $skillsDst"
}

Write-Host ""
Write-Host "Done. Open a NEW terminal / restart LM Studio to pick everything up." -ForegroundColor Green
