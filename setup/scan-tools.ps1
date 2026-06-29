<#
.SYNOPSIS
  Scan this machine for installed CLI tools and GENERATE a personalized
  local-tools/SKILL.md primer, so your local LLM knows exactly what YOU have.

.PARAMETER SkillsDir
  Where your skills live. Default: ~/.lmstudio/skills

.PARAMETER ReferenceFile
  Optional path to a long "all my tools" reference doc to point the model at.

.EXAMPLE
  ./scan-tools.ps1
  ./scan-tools.ps1 -SkillsDir "D:\my-skills" -ReferenceFile "D:\docs\tools.md"
#>
[CmdletBinding()]
param(
  [string]$SkillsDir = "$env:USERPROFILE\.lmstudio\skills",
  [string]$ReferenceFile = ""
)
$ErrorActionPreference = "Stop"

# command -> which skill covers it (only found ones are written out)
$catalog = [ordered]@{
  "install-tools"       = @("winget","choco","scoop","pip","uv","npm","pnpm","cargo")
  "web-search"          = @("python","curl.exe")
  "media-ffmpeg"        = @("ffmpeg","ffprobe","ffplay")
  "audio-sox-tts"       = @("sox","edge-tts","tts")
  "images-magick-gimp"  = @("magick","gimp-console-3","gegl")
  "documents-pandoc"    = @("pandoc","md2pdf","ebook-convert","calibredb")
  "python-ml-libs"      = @("python","uv")
  "video-apps"          = @("vlc","blender","obs64")
  "android-adb"         = @("adb","fastboot","scrcpy")
  "git-github"          = @("git","gh","tig","git-lfs")
  "containers-k8s"      = @("docker","kubectl","wsl","qemu-img")
  "network-crypto"      = @("curl.exe","ssh","scp","openssl")
  "archives-files"      = @("7z","tar","robocopy")
}

function Find-Tool($name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if ($c) { return ($c | Select-Object -First 1).Source } else { return $null }
}

# --- hardware / environment ---
$gpu = (Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Name)
$cpu = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Name)
$os  = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
$psv = $PSVersionTable.PSVersion.ToString()
$gpuVendor = switch -Regex ($gpu) { "NVIDIA|GeForce|RTX|GTX" {"NVIDIA (use *_nvenc)"; break} "AMD|Radeon|RX " {"AMD (use *_amf)"; break} "Intel|Arc|UHD|Iris" {"Intel (use *_qsv)"; break} default {"unknown"} }

Write-Host "Scanning installed tools..." -ForegroundColor Cyan
$found = [ordered]@{}; $missing = @()
foreach ($skill in $catalog.Keys) {
  foreach ($tool in $catalog[$skill]) {
    if (-not $found.Contains($tool)) {
      $src = Find-Tool $tool
      if ($src) { $found[$tool] = $src } else { $missing += $tool }
    }
  }
}

# --- build the markdown ---
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("name: local-tools")
[void]$sb.AppendLine("description: Read FIRST whenever a task might need a command-line tool, program, or to run a script on this machine. Describes this PC's identity, the PowerShell rules you MUST follow, the tools actually installed here, and a map of the other skills.")
[void]$sb.AppendLine("---`n")
[void]$sb.AppendLine("# local-tools`n")
[void]$sb.AppendLine("This PC's installed toolbox (auto-detected $(Get-Date -Format yyyy-MM-dd)). Load a domain skill for exact commands.`n")
[void]$sb.AppendLine("- **OS:** $os")
[void]$sb.AppendLine("- **CPU:** $cpu")
[void]$sb.AppendLine("- **GPU:** $gpu  -> hardware video encode: **$gpuVendor**")
[void]$sb.AppendLine("- **Shell:** PowerShell $psv")
if ($ReferenceFile) { [void]$sb.AppendLine("- **Full reference:** ``$ReferenceFile``") }
[void]$sb.AppendLine("`n---`n")
[void]$sb.AppendLine("## CRITICAL PowerShell rules`n")
[void]$sb.AppendLine("1. In PowerShell 5.1, ``&&`` ``||`` ``??`` ``?.`` and ternary FAIL. Chain with ``;`` and ``if (`$?) { }``.")
[void]$sb.AppendLine("2. ``curl`` is an alias for Invoke-WebRequest - use **``curl.exe``** for real curl.")
[void]$sb.AppendLine("3. ``convert`` is a Windows disk tool - use **``magick``** for ImageMagick.")
[void]$sb.AppendLine("4. Backslash paths; quote spaces; run programs with ``& `"C:\path\app.exe`" args``.")
[void]$sb.AppendLine("5. Check a tool: ``Get-Command <name> -ErrorAction SilentlyContinue``.`n")
[void]$sb.AppendLine("---`n")
[void]$sb.AppendLine("## Installed tools by skill (only what's present on THIS machine)`n")
[void]$sb.AppendLine("| Skill to load | Detected tools |")
[void]$sb.AppendLine("|---|---|")
foreach ($skill in $catalog.Keys) {
  $have = $catalog[$skill] | Where-Object { $found.Contains($_) } | Select-Object -Unique
  if ($have) { [void]$sb.AppendLine("| ``$skill`` | $($have -join ', ') |") }
}
[void]$sb.AppendLine("`n> Tools NOT found here (load ``install-tools`` to add any you need): $((($missing | Select-Object -Unique) -join ', '))`n")
[void]$sb.AppendLine("## Honesty rule`n")
[void]$sb.AppendLine("Never claim a tool exists or that you ran a command unless you actually checked with ``Get-Command`` or executed it. If missing, say so and load ``install-tools``.")

$outDir = Join-Path $SkillsDir "local-tools"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$sb.ToString() | Set-Content -Encoding utf8 (Join-Path $outDir "SKILL.md")
@{ name="local-tools"; description="Read FIRST for tool/shell tasks: this machine's identity, PowerShell rules, installed tools, and the skill map."; tags=@("tools","windows","powershell","shell","machine","capabilities","index") } |
  ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $outDir "skill.json")

Write-Host ("Found {0} tools; {1} not installed." -f $found.Count, ($missing | Select-Object -Unique).Count) -ForegroundColor Green
Write-Host "Wrote personalized primer: $outDir\SKILL.md"
