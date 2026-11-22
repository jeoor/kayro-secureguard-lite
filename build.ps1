[CmdletBinding()]
param([string] $OutputDirectory = (Join-Path $PSScriptRoot 'dist'))

$ErrorActionPreference = 'Stop'
$version = 'v2.0.6'
$entries = [ordered]@{
    'module.prop'        = @{ Path = 'module/module.prop'; Mode = (0x81a4 -shl 16) }
    'action.sh'          = @{ Path = 'module/action.sh'; Mode = (0x81ed -shl 16) }
    'boot-completed.sh'  = @{ Path = 'module/boot-completed.sh'; Mode = (0x81ed -shl 16) }
    'initrc/kayro_secureguard.rc' = @{ Path = 'module/initrc/kayro_secureguard.rc'; Mode = (0x81a4 -shl 16) }
    'LICENSE'            = @{ Path = 'LICENSE'; Mode = (0x81a4 -shl 16) }
}
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$timestamp = [DateTimeOffset]::new(2020, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
$zip = [IO.MemoryStream]::new()
$writer = [IO.Compression.ZipArchive]::new($zip, [IO.Compression.ZipArchiveMode]::Create, $true)
try {
    foreach ($name in $entries.Keys) {
        $spec = $entries[$name]
        $bytes = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $spec.Path))
        $source = $utf8.GetString($bytes)
        if (!$source.EndsWith("`n") -or $source.Contains("`r") -or
            $source.StartsWith([string][char]0xfeff, [StringComparison]::Ordinal) -or $source.Contains([char]0)) {
            throw "$name must use UTF-8 without BOM, LF, and a final newline."
        }
        $spec.Hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
        $entry = $writer.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = $timestamp
        $entry.ExternalAttributes = $spec.Mode
        $stream = $entry.Open()
        try { $stream.Write($bytes, 0, $bytes.Length) }
        finally { $stream.Dispose() }
    }
}
finally { $writer.Dispose() }

# ZIP 中央目录的「创建系统」随宿主变化。统一标记为 Unix，使权限可识别。
$reader = [IO.BinaryReader]::new($zip, [Text.Encoding]::ASCII, $true)
try {
    $end = $zip.Length - 22
    $zip.Position = $end
    if ($reader.ReadUInt32() -ne 0x06054b50) { throw 'Invalid ZIP directory.' }
    $zip.Position = $end + 16
    $position = $reader.ReadUInt32()
    foreach ($name in $entries.Keys) {
        $zip.Position = $position
        if ($reader.ReadUInt32() -ne 0x02014b50) { throw "Invalid ZIP header for $name." }
        $zip.Position = $position + 5
        $zip.WriteByte(3)
        $zip.Position = $position + 28
        $position += 46 + $reader.ReadUInt16() + $reader.ReadUInt16() + $reader.ReadUInt16()
    }
    if ($position -ne $end) { throw 'Unexpected extra ZIP records.' }
}
finally { $reader.Dispose() }

$zip.Position = 0
$archive = [IO.Compression.ZipArchive]::new($zip, [IO.Compression.ZipArchiveMode]::Read, $true)
try {
    if ($zip.Length -ge 64KB -or ($archive.Entries.FullName -join '/') -cne ($entries.Keys -join '/')) {
        throw 'ZIP exceeds the size limit or contains unexpected paths.'
    }
    foreach ($entry in $archive.Entries) {
        $spec = $entries[$entry.FullName]
        if ($entry.ExternalAttributes -ne $spec.Mode) {
            throw "Incorrect ZIP metadata for $($entry.FullName)."
        }
        $stream = $entry.Open()
        try { $actual = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)) }
        finally { $stream.Dispose() }
        if ($actual -cne $spec.Hash) { throw "Incorrect ZIP content for $($entry.FullName)." }
    }
}
finally { $archive.Dispose() }

$bytes = $zip.ToArray()
$zip.Dispose()
$null = [IO.Directory]::CreateDirectory($OutputDirectory)
$file = Join-Path $OutputDirectory "kayro_secureguard-$version.zip"
[IO.File]::WriteAllBytes($file, $bytes)
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLowerInvariant()
[IO.File]::WriteAllText("$file.sha256", "$hash  $([IO.Path]::GetFileName($file))`n", [Text.Encoding]::ASCII)
Write-Output "$file ($($bytes.Length) bytes)"
Write-Output "SHA-256 $hash"
