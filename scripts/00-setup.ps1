#
# One-time tool download: apktool + uber-apk-signer into tools/.
# Run this once after cloning the repo.
#

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root "tools"
New-Item -ItemType Directory -Force $tools | Out-Null

$apktool = Join-Path $tools "apktool.jar"
$signer  = Join-Path $tools "uber-apk-signer.jar"
$bat     = Join-Path $tools "apktool.bat"

if (-not (Test-Path $apktool)) {
    Write-Host "[*] downloading apktool 2.11.1..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://github.com/iBotPeaches/Apktool/releases/download/v2.11.1/apktool_2.11.1.jar" `
        -OutFile $apktool
    Write-Host "[+] apktool.jar ($((Get-Item $apktool).Length) bytes)" -ForegroundColor Green
} else {
    Write-Host "[*] apktool.jar already present, skipping" -ForegroundColor DarkGray
}

if (-not (Test-Path $signer)) {
    Write-Host "[*] downloading uber-apk-signer 1.3.0..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar" `
        -OutFile $signer
    Write-Host "[+] uber-apk-signer.jar ($((Get-Item $signer).Length) bytes)" -ForegroundColor Green
} else {
    Write-Host "[*] uber-apk-signer.jar already present, skipping" -ForegroundColor DarkGray
}

@"
@echo off
java -jar "%~dp0apktool.jar" %*
"@ | Out-File -FilePath $bat -Encoding ascii

Write-Host ""
Write-Host "[+] setup complete. Next:" -ForegroundColor Green
Write-Host "    1. Connect Quest in developer mode (adb devices should list it)"
Write-Host "    2. scripts\01-pull-apk.ps1"
Write-Host "    3. scripts\02-decompile.ps1"
Write-Host "    4. scripts\02a-apply-patches.ps1"
Write-Host "    5. scripts\03-build-and-sign.ps1"
Write-Host "    6. scripts\04-install.ps1"
