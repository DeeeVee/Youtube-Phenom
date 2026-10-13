param(
    [string]$Serial  = "",
    [string]$Package = "com.phenom.ytvr"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$patchedDir = Join-Path $root "apk\patched"
$apk = Get-ChildItem $patchedDir -Filter "*aligned-debugSigned*.apk" | Select-Object -First 1
if (-not $apk) { Write-Host "[!] No signed APK found. Run 03-build-and-sign.ps1 first." -ForegroundColor Red; exit 1 }

$adb = @(
    "C:\platform-tools\adb.exe",
    "C:\Program Files\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $adb) { $adb = "adb" }

$adbArgs = @()
if ($Serial) { $adbArgs += @("-s", $Serial) }

Write-Host "[*] Uninstalling $Package (signatures won't match)" -ForegroundColor Cyan
& $adb @adbArgs uninstall $Package 2>&1 | Out-Null

Write-Host "[*] Installing $($apk.FullName)" -ForegroundColor Cyan
& $adb @adbArgs install -r $apk.FullName
if ($LASTEXITCODE -ne 0) { Write-Host "[!] install failed" -ForegroundColor Red; exit 1 }
Write-Host "[+] Installed. Launch from Quest unknown-sources library." -ForegroundColor Green
