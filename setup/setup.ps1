<#
.SYNOPSIS
  Install this skills library so both LM Studio and opencode can use it.

  What it does:
   1. Copies skills/ into your LM Studio skills folder (~/.lmstudio/skills)
   2. Fills in path placeholders ({{SKILLS_DIR}} etc.) for your machine
   3. Raises the LM Studio skill cap to 30 and sets the skills path
   4. Junctions opencode's skill dir to the same folder (single source of truth)
   5. Optionally runs scan-tools.ps1 to personalize the local-tools primer

  Close LM Studio before running. Requires the 'skills' plugin installed in LM Studio
  (search the Hub for "skills"). opencode reads SKILL.md natively.

.PARAMETER SkillsDir
  Target skills folder. Default: ~/.lmstudio/skills
.PARAMETER ReferenceFile
  Optional path to a long "all my tools" doc to reference in local-tools.
.PARAMETER NoScan
  Skip the auto-scan step (keep the generic local-tools primer).
#>
[CmdletBinding()]
param(
  [string]$SkillsDir = "$env:USERPROFILE\.lmstudio\skills",
  [string]$ReferenceFile = "",
  [switch]$NoScan
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$srcSkills = Join-Path $repo "skills"

Write-Host "== Installing local-LLM skills ==" -ForegroundColor Cyan

# 1. copy skills
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
Copy-Item "$srcSkills\*" -Destination $SkillsDir -Recurse -Force
Write-Host "  [ok] skills copied to $SkillsDir"

# 2. fill placeholders in the copied SKILL.md / skill.json files
$refValue = if ($ReferenceFile) { $ReferenceFile } else { "(no reference file configured)" }
foreach ($f in Get-ChildItem $SkillsDir -Recurse -Include *.md,*.json -File) {
  $t = Get-Content $f.FullName -Raw
  $t = $t.Replace('{{SKILLS_DIR}}', $SkillsDir).Replace('{{USERPROFILE}}', $env:USERPROFILE).Replace('{{REFERENCE_FILE}}', $refValue)
  Set-Content -Encoding utf8 $f.FullName $t
}
Write-Host "  [ok] path placeholders resolved"

# 3. LM Studio skills engine settings (path + cap=30)
$lmsSettings = "$env:USERPROFILE\.lmstudio\plugin-data\lms-skills\settings.json"
New-Item -ItemType Directory -Force -Path (Split-Path $lmsSettings) | Out-Null
if (Test-Path $lmsSettings) { $s = Get-Content $lmsSettings -Raw | ConvertFrom-Json } else { $s = [pscustomobject]@{} }
$s | Add-Member skillsPaths @($SkillsDir) -Force
$s | Add-Member autoInject $true -Force
$s | Add-Member maxSkillsInContext 30 -Force
if (-not $s.PSObject.Properties['windowsShell']) { $s | Add-Member windowsShell "powershell" -Force }
($s | ConvertTo-Json -Depth 10) | Set-Content -Encoding utf8 $lmsSettings
Write-Host "  [ok] LM Studio skills engine configured (cap 30, autoInject)"

# 4. opencode junction
$ocSkill = "$env:USERPROFILE\.config\opencode\skill"
New-Item -ItemType Directory -Force -Path (Split-Path $ocSkill) | Out-Null
if (Test-Path $ocSkill) {
  if ((Get-Item $ocSkill).LinkType -eq "Junction") { Write-Host "  [ok] opencode junction already present" }
  else { Write-Warning "  $ocSkill exists and isn't a junction; leaving it. (opencode also reads ~/.config/opencode/skill)" }
} else {
  New-Item -ItemType Junction -Path $ocSkill -Target $SkillsDir | Out-Null
  Write-Host "  [ok] opencode junction created -> $SkillsDir"
}

# 5. opencode native tool + /websearch command
$ocTool = "$env:USERPROFILE\.config\opencode\tool"
$ocCmd  = "$env:USERPROFILE\.config\opencode\command"
New-Item -ItemType Directory -Force -Path $ocTool, $ocCmd | Out-Null
Get-ChildItem (Join-Path $repo "opencode\tool") -Filter *.ts -ErrorAction SilentlyContinue | ForEach-Object {
  Copy-Item $_.FullName -Destination $ocTool -Force
}
Get-ChildItem (Join-Path $repo "opencode\command") -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
  $t = (Get-Content $_.FullName -Raw).Replace('{{SKILLS_DIR}}', $SkillsDir)
  Set-Content -Encoding utf8 (Join-Path $ocCmd $_.Name) $t
}
$ocAgent = "$env:USERPROFILE\.config\opencode\agent"
New-Item -ItemType Directory -Force -Path $ocAgent | Out-Null
Get-ChildItem (Join-Path $repo "opencode\agent") -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
  Copy-Item $_.FullName -Destination $ocAgent -Force
}
Write-Host "  [ok] opencode 'websearch' tool + /websearch command + agents (auto/coder/vision) installed"

# 6. personalize the primer
if (-not $NoScan) {
  Write-Host "  Running scan-tools.ps1 to personalize local-tools..." -ForegroundColor Cyan
  & (Join-Path $PSScriptRoot "scan-tools.ps1") -SkillsDir $SkillsDir -ReferenceFile $ReferenceFile
}

Write-Host ""
Write-Host "Done. Restart LM Studio / open a new opencode session." -ForegroundColor Green
Write-Host "Test it: ask your model 'what tools do I have for video encoding?'"
Write-Host ""
Write-Host "Optional - install the native LM Studio web-search plugin:" -ForegroundColor Cyan
Write-Host "  cd '$repo\lmstudio-plugin\web-search-plus'; npm install; lms dev --install -y"
Write-Host ""
Write-Host "Optional - enable graduated autonomy (fewer approval prompts, safely):" -ForegroundColor Cyan
Write-Host "  ./setup/enable-autonomy.ps1     (see docs/autonomy.md)"
