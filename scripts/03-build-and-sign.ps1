param([string]$Suffix = "patched")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root "tools"
$apktool = Join-Path $tools "apktool.jar"
$signer = Join-Path $tools "uber-apk-signer.jar"
$decompiled = Join-Path $root "apk\decompiled"
$patchedDir = Join-Path $root "apk\patched"
New-Item -ItemType Directory -Force $patchedDir | Out-Null

$unsigned = Join-Path $patchedDir "youtubevr-$Suffix-unsigned.apk"
Write-Host "[*] apktool b $decompiled" -ForegroundColor Cyan
& java -jar $apktool b -f -o $unsigned $decompiled
if ($LASTEXITCODE -ne 0) { Write-Host "[!] apktool build failed" -ForegroundColor Red; exit 1 }

Write-Host "[*] Signing with uber-apk-signer" -ForegroundColor Cyan
& java -jar $signer --apks $unsigned --out $patchedDir --allowResign
if ($LASTEXITCODE -ne 0) { Write-Host "[!] signing failed" -ForegroundColor Red; exit 1 }
Write-Host "[+] Signed APK in $patchedDir" -ForegroundColor Green
Get-ChildItem $patchedDir -Filter "*aligned-debugSigned*.apk" | Select-Object Name, Length | Format-Table
