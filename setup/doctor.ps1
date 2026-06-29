<#
.SYNOPSIS
  Health-check the local-llm-skills setup. Verifies LM Studio + opencode are wired correctly
  (skills, junction, plugin, permissions, tools) and reports what's broken.

.EXAMPLE
  ./setup/doctor.ps1
  Exit code = number of failed checks (0 = all good).
#>
[CmdletBinding()]
param([string]$SkillsDir = "$env:USERPROFILE\.lmstudio\skills")
$ErrorActionPreference = "Continue"

$fails = 0; $warns = 0
function Pass($m) { Write-Host "  [PASS] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:warns++ }
function Fail($m) { Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:fails++ }
function Has($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

$ocDir   = "$env:USERPROFILE\.config\opencode"
$plugins = "$env:USERPROFILE\.lmstudio\extensions\plugins"

Write-Host "=== local-llm-skills doctor ===" -ForegroundColor Cyan

Write-Host "Skills library"
if (Test-Path $SkillsDir) {
  $n = (Get-ChildItem $SkillsDir -Directory).Count
  Pass "skills folder exists ($n skills) at $SkillsDir"
  if (Test-Path "$SkillsDir\local-tools\SKILL.md") { Pass "local-tools primer present" } else { Fail "local-tools/SKILL.md missing" }
  foreach ($s in @("web-search","install-tools","verify-work","task-discipline","vision-image")) {
    if (Test-Path "$SkillsDir\$s\SKILL.md") { Pass "skill '$s' present" } else { Warn "skill '$s' missing" }
  }
} else { Fail "skills folder not found: $SkillsDir" }

Write-Host "opencode"
$link = "$ocDir\skill"
if (Test-Path $link) {
  $li = Get-Item $link
  if ($li.LinkType -eq "Junction") { Pass "opencode skill junction -> $((Get-Item $link).Target)" }
  else { Warn "opencode skill path exists but is not a junction" }
} else { Fail "opencode skill junction missing ($link)" }
$ocJson = "$ocDir\opencode.json"
if (Test-Path $ocJson) {
  try {
    $j = Get-Content $ocJson -Raw | ConvertFrom-Json
    Pass "opencode.json valid"
    if ($j.permission) { Pass "permission block present" } else { Warn "no permission block (run enable-autonomy.ps1)" }
  } catch { Fail "opencode.json invalid JSON: $($_.Exception.Message)" }
} else { Fail "opencode.json missing" }
foreach ($p in @("AGENTS.md","agent\auto.md","tool\websearch.ts","command\websearch.md")) {
  if (Test-Path "$ocDir\$p") { Pass "opencode $p present" } else { Warn "opencode $p missing" }
}

Write-Host "LM Studio"
foreach ($pl in @("khtsly\skills","onica5000\web-search-plus")) {
  if (Test-Path "$plugins\$pl") { Pass "plugin '$pl' installed" } else { Warn "plugin '$pl' not installed" }
}
$skillCfg = "$env:USERPROFILE\.lmstudio\plugin-data\lms-skills\settings.json"
if (Test-Path $skillCfg) {
  $sc = Get-Content $skillCfg -Raw | ConvertFrom-Json
  if ($sc.skillsPaths -contains $SkillsDir) { Pass "skills engine points at $SkillsDir" } else { Warn "skills engine path doesn't include $SkillsDir" }
  if ($sc.maxSkillsInContext -ge 20) { Pass "maxSkillsInContext = $($sc.maxSkillsInContext)" } else { Warn "maxSkillsInContext = $($sc.maxSkillsInContext) (raise to >=30)" }
} else { Warn "skills plugin settings not found (is the LM Studio 'skills' plugin installed?)" }
$lmsSettings = "$env:USERPROFILE\.lmstudio\settings.json"
if (Test-Path $lmsSettings) {
  $ls = Get-Content $lmsSettings -Raw | ConvertFrom-Json
  $ctx = $ls.defaultContextLength.value
  if ($ctx -ge 16384) { Pass "defaultContextLength = $ctx" } else { Warn "defaultContextLength = $ctx (consider raising)" }
  $pat = @($ls.chat.skipToolConfirmationPatterns)
  if ($pat -match "web-search-plus") { Pass "web-search-plus auto-approved" } else { Warn "web-search-plus not in skip list" }
}

Write-Host "Runtimes"
if (Has "python") { Pass "python present" } else { Fail "python missing (web-search + vision scripts need it)" }
if (Has "node")   { Pass "node present (opencode tool)" } else { Warn "node missing" }
if (Has "lms")    { Pass "lms CLI present" } else { Warn "lms CLI missing" }
if (Has "git")    { Pass "git present (checkpoint.ps1)" } else { Warn "git missing" }

Write-Host ""
if ($fails -eq 0 -and $warns -eq 0) { Write-Host "All checks passed." -ForegroundColor Green }
else { Write-Host "$fails failure(s), $warns warning(s)." -ForegroundColor $(if ($fails) { "Red" } else { "Yellow" }) }
exit $fails
