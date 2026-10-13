param(
    [string]$Package = "com.google.android.apps.youtube.vr.oculus",
    [string]$Serial  = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "apk\original"
New-Item -ItemType Directory -Force $outDir | Out-Null

# Resolve the real adb binary (PowerShell's PATH often points at a broken WindowsApps shim).
$adb = @(
    "C:\platform-tools\adb.exe",
    "C:\Program Files\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $adb) { $adb = "adb" }

$adbArgs = @()
if ($Serial) { $adbArgs += @("-s", $Serial) }

Write-Host "[*] Using adb: $adb" -ForegroundColor DarkGray
Write-Host "[*] Looking for $Package on connected device..." -ForegroundColor Cyan
$pathLines = & $adb @adbArgs shell pm path $Package 2>&1
if ($LASTEXITCODE -ne 0 -or -not $pathLines -or $pathLines -match "not found|Unable|Error") {
    Write-Host "[!] Package not installed on device, or no device connected." -ForegroundColor Yellow
    Write-Host "    Known VR package names to try:" -ForegroundColor Yellow
    Write-Host "      com.google.android.apps.youtube.vr.oculus   (Meta Quest build)"
    Write-Host "      com.google.android.youtube.vr               (older Daydream build)"
    Write-Host "      com.google.vr.youtube                        (very old)"
    exit 1
}

$i = 0
foreach ($line in $pathLines) {
    $line = $line.Trim()
    if ($line -match '^package:(.+)$') {
        $remote = $Matches[1]
        $name = if ($i -eq 0) { "base.apk" } else { "split_$i.apk" }
        $local = Join-Path $outDir $name
        Write-Host "[*] Pulling $remote -> $local" -ForegroundColor Cyan
        & $adb @adbArgs pull $remote $local | Out-Null
        $i++
    }
}
Write-Host "[+] Pulled $i APK(s) to $outDir" -ForegroundColor Green
Get-ChildItem $outDir | Select-Object Name, Length | Format-Table
