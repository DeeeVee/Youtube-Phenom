param([string]$Apk = "")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root "tools"
$apktool = Join-Path $tools "apktool.jar"
$originalDir = Join-Path $root "apk\original"
$outDir = Join-Path $root "apk\decompiled"

if (-not $Apk) {
    $base = Join-Path $originalDir "base.apk"
    if (-not (Test-Path $base)) {
        Write-Host "[!] No APK path given and $base does not exist. Run 01-pull-apk.ps1 first." -ForegroundColor Red
        exit 1
    }
    $Apk = $base
}

if (Test-Path $outDir) {
    Write-Host "[*] Removing previous decompile at $outDir" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $outDir
}

Write-Host "[*] apktool d $Apk" -ForegroundColor Cyan
& java -jar $apktool d -f -o $outDir $Apk
if ($LASTEXITCODE -ne 0) { Write-Host "[!] apktool failed" -ForegroundColor Red; exit 1 }
Write-Host "[+] Decompiled to $outDir" -ForegroundColor Green
