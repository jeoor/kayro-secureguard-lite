[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    & ./build.ps1 | Out-Null
    $zip = Get-ChildItem 'dist/kayro_secureguard-*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (!$zip) { throw 'No module ZIP found.' }
    $hash1 = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip.FullName).Hash.ToLowerInvariant()

    & ./build.ps1 | Out-Null
    $zip2 = Get-ChildItem 'dist/kayro_secureguard-*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $hash2 = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip2.FullName).Hash.ToLowerInvariant()
    if ($hash1 -cne $hash2) { throw 'Build is not deterministic.' }

    $sha = (Get-Content "$($zip.FullName).sha256" -Raw).Trim()
    if ($sha -notmatch "^$hash1\s") { throw 'SHA-256 file does not match the ZIP.' }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($zip.FullName)
    try {
        $names = $archive.Entries.FullName -join ','
        $expected = 'module.prop,action.sh,customize.sh,boot-completed.sh,initrc/kayro_secureguard.rc,LICENSE'
        if ($names -cne $expected) { throw "Unexpected ZIP entries: $names" }
        foreach ($entry in $archive.Entries) {
            if ($entry.Length -le 0) { throw "Empty ZIP entry: $($entry.FullName)" }
        }
    }
    finally { $archive.Dispose() }

    $prop = Get-Content 'module/module.prop' -Raw
    foreach ($needle in @('id=kayro_secureguard', 'version=v2.0.9', 'versionCode=20009')) {
        if (!$prop.Contains($needle)) { throw "module.prop missing $needle" }
    }

    $rc = Get-Content 'module/initrc/kayro_secureguard.rc' -Raw
    foreach ($needle in @(
            'service kayro_sg_early',
            'seclabel u:r:ksu:s0',
            'on post-fs')) {
        if (!$rc.Contains($needle)) { throw "initrc missing $needle" }
    }

    $action = Get-Content 'module/action.sh' -Raw
    foreach ($needle in @('oplus_secure_guard_new', 'need kill')) {
        if (!$action.Contains($needle)) { throw "action.sh missing $needle" }
    }
    $boot = Get-Content 'module/boot-completed.sh' -Raw
    foreach ($needle in @('oplus_secure_guard_new', '✅', '⚠️', '状态未知', '自动卸载 oplus_secure_guard_new', 'override.description')) {
        if (!$boot.Contains($needle)) { throw "boot-completed.sh missing $needle" }
    }

    $custom = Get-Content 'module/customize.sh' -Raw
    foreach ($needle in @('ui_print', 'oplus_secure_guard_new', 'Target')) {
        if (!$custom.Contains($needle)) { throw "customize.sh missing $needle" }
    }
    Write-Output "OK $($zip.Name) $($zip.Length) bytes SHA-256 $hash1"
}
finally { Pop-Location }
