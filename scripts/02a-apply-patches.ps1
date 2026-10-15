#
# Apply Youtube Phenom patches to a freshly decompiled YouTube VR 1.88.10.
#
# Prereq: scripts/02-decompile.ps1 ran successfully.
# Idempotent: safe to re-run; each edit is match-first.
#

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dec  = Join-Path $root "apk\decompiled"

if (-not (Test-Path (Join-Path $dec "AndroidManifest.xml"))) {
    Write-Host "[!] No decompiled APK at $dec. Run 02-decompile.ps1 first." -ForegroundColor Red
    exit 1
}

function Edit-File([string]$path, [string]$old, [string]$new, [switch]$Required) {
    if (-not (Test-Path $path)) { if ($Required) { throw "missing: $path" } else { return } }
    $c = Get-Content $path -Raw
    if ($c -notmatch [regex]::Escape($old)) {
        Write-Host "    skip: pattern not found in $(Split-Path -Leaf $path) (already patched?)" -ForegroundColor DarkGray
        return
    }
    $c = $c.Replace($old, $new)
    Set-Content -Path $path -Value $c -NoNewline
    Write-Host "    patched: $(Split-Path -Leaf $path)" -ForegroundColor Green
}

function Replace-Method([string]$smaliPath, [string]$sigPattern, [string[]]$newBodyLines) {
    if (-not (Test-Path $smaliPath)) { throw "missing: $smaliPath" }
    $lines = Get-Content $smaliPath
    $startMatch = $lines | Select-String -Pattern $sigPattern | Select-Object -First 1
    if (-not $startMatch) {
        Write-Host "    skip: no match for $sigPattern in $(Split-Path -Leaf $smaliPath)" -ForegroundColor DarkGray
        return
    }
    $start = $startMatch.LineNumber - 1
    $end = $start
    for ($i = $start; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\.end method') { $end = $i; break }
    }
    $pre  = if ($start -gt 0) { $lines[0..($start - 1)] } else { @() }
    $post = if (($end + 1) -le ($lines.Count - 1)) { $lines[($end + 1)..($lines.Count - 1)] } else { @() }
    $out = @(); $out += $pre; $out += $newBodyLines; $out += $post
    Set-Content -Path $smaliPath -Value $out
    Write-Host "    patched: $(Split-Path -Leaf $smaliPath) :: $sigPattern" -ForegroundColor Green
}

#
# Patch 1 — Rename app to "Youtube Phenom"
#
Write-Host "[1/6] rename app" -ForegroundColor Cyan
Edit-File (Join-Path $dec "res\values\strings.xml") `
    '<string name="youtube_vr_app_name">YouTube</string>' `
    '<string name="youtube_vr_app_name">Youtube Phenom</string>'

# Also rewrite the FileProvider authority string resource that gets referenced
# as @string/authorities in the manifest. Original value collides with the
# installed YouTube VR, blocking coexistence with INSTALL_FAILED_CONFLICTING_PROVIDER.
Edit-File (Join-Path $dec "res\values\strings.xml") `
    '<string name="authorities">com.google.android.vr.inputmethod.fileprovider.youtube</string>' `
    '<string name="authorities">com.phenom.ytvr.inputmethod.fileprovider</string>'

#
# Patch 2 — Repackage to com.phenom.ytvr
#
Write-Host "[2/6] repackage to com.phenom.ytvr" -ForegroundColor Cyan
$manifest = Join-Path $dec "AndroidManifest.xml"
Edit-File $manifest 'package="com.google.android.apps.youtube.vr.oculus"' 'package="com.phenom.ytvr"'
Edit-File $manifest 'com.google.android.apps.youtube.vr.oculus.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION' 'com.phenom.ytvr.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
Edit-File $manifest 'com.google.android.apps.youtube.vr.oculus.tracing'            'com.phenom.ytvr.tracing'
Edit-File $manifest 'com.google.android.apps.youtube.vr.oculus.mlkitinitprovider'  'com.phenom.ytvr.mlkitinitprovider'
Edit-File $manifest 'com.google.android.apps.youtube.vr.oculus.firebaseinitprovider' 'com.phenom.ytvr.firebaseinitprovider'

#
# Patch 3 — Redirect the player/ad_break Innertube endpoint to a 404 path
#
Write-Host "[3/6] redirect player/ad_break endpoint" -ForegroundColor Cyan
Edit-File (Join-Path $dec "smali_classes3\ovj.smali") `
    'const-string v1, "player/ad_break"' 'const-string v1, "player/noop_phenom"'
Edit-File (Join-Path $dec "smali_classes3\ovh.smali") `
    'const-string v2, "player/ad_break"' 'const-string v2, "player/noop_phenom"'

#
# Patch 4 — Stub mqy.smali AdSlotRenderer
#   a(Lvmo;Lmwh;)Lvmo; -> empty-list via Lvmj builder
#   b(Lvmo;Lmwh;)V     -> no-op
#
Write-Host "[4/6] stub mqy.smali AdSlotRenderer" -ForegroundColor Cyan
$mqy = Join-Path $dec "smali_classes3\mqy.smali"
Replace-Method $mqy '^\.method public final a\(Lvmo;Lmwh;\)Lvmo;' @(
    '.method public final a(Lvmo;Lmwh;)Lvmo;',
    '    .locals 2',
    '',
    '    const/4 v0, 0x0',
    '',
    '    new-instance v1, Lvmj;',
    '',
    '    invoke-direct {v1, v0}, Lvmj;-><init>(I)V',
    '',
    '    invoke-virtual {v1}, Lvmj;->g()Lvmo;',
    '',
    '    move-result-object v0',
    '',
    '    return-object v0',
    '.end method'
)
Replace-Method $mqy '^\.method public final b\(Lvmo;Lmwh;\)V' @(
    '.method public final b(Lvmo;Lmwh;)V',
    '    .locals 0',
    '',
    '    return-void',
    '.end method'
)

#
# Patch 5 — Stub muk.smali AdBreak proto deserializer
#   a(Loqi;)Ljava/util/List;                         -> Lvrm;->a:Lvmo; (empty singleton)
#   b(Lmzt;Ljava/util/List;Loqi;)Ljava/util/List;    -> Lvrm;->a:Lvmo;
#
Write-Host "[5/6] stub muk.smali AdBreak deserializer" -ForegroundColor Cyan
$muk = Join-Path $dec "smali_classes3\muk.smali"
Replace-Method $muk '^\.method public final a\(Loqi;\)Ljava/util/List;' @(
    '.method public final a(Loqi;)Ljava/util/List;',
    '    .locals 1',
    '',
    '    sget-object v0, Lvrm;->a:Lvmo;',
    '',
    '    return-object v0',
    '.end method'
)
Replace-Method $muk '^\.method public final b\(Lmzt;Ljava/util/List;Loqi;\)Ljava/util/List;' @(
    '.method public final b(Lmzt;Ljava/util/List;Loqi;)Ljava/util/List;',
    '    .locals 1',
    '    .annotation runtime Ljava/lang/Deprecated;',
    '    .end annotation',
    '',
    '    sget-object v0, Lvrm;->a:Lvmo;',
    '',
    '    return-object v0',
    '.end method'
)

#
# Patch 6 — Stub mqx.smali ad-break builder (the kill shot)
#   q(Loqi;Lstd;Ljava/lang/String;)Lj$/util/Optional;        -> Optional.empty()
#   r(Loqi;Lstd;Ljava/lang/String;Lsq;)Ljava/util/List;      -> Lvrm;->a:Lvmo;
#
Write-Host "[6/6] stub mqx.smali ad-break builder" -ForegroundColor Cyan
$mqx = Join-Path $dec "smali_classes3\mqx.smali"
Replace-Method $mqx '^\.method public final q\(Loqi;Lstd;Ljava/lang/String;\)Lj\$/util/Optional;' @(
    '.method public final q(Loqi;Lstd;Ljava/lang/String;)Lj$/util/Optional;',
    '    .locals 1',
    '',
    '    invoke-static {}, Lj$/util/Optional;->empty()Lj$/util/Optional;',
    '',
    '    move-result-object v0',
    '',
    '    return-object v0',
    '.end method'
)
Replace-Method $mqx '^\.method final r\(Loqi;Lstd;Ljava/lang/String;Lsq;\)Ljava/util/List;' @(
    '.method final r(Loqi;Lstd;Ljava/lang/String;Lsq;)Ljava/util/List;',
    '    .locals 1',
    '',
    '    sget-object v0, Lvrm;->a:Lvmo;',
    '',
    '    return-object v0',
    '.end method'
)

Write-Host ""
Write-Host "[+] All patches applied. Next: scripts\03-build-and-sign.ps1" -ForegroundColor Green
