[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$packsRoot = Join-Path $repositoryRoot 'packs'
$outputRoot = Join-Path $repositoryRoot 'release-assets'
$fixedTimestamp = [DateTimeOffset]::new(2020, 1, 1, 0, 0, 0, [TimeSpan]::Zero)

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
Add-Type -AssemblyName System.IO.Compression

foreach ($packDirectory in Get-ChildItem -LiteralPath $packsRoot -Directory | Sort-Object Name) {
    $archivePath = Join-Path $outputRoot ($packDirectory.Name + '-1.0.0.zip')
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    $archiveStream = [System.IO.File]::Open($archivePath, [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new($archiveStream,
            [System.IO.Compression.ZipArchiveMode]::Create, $false)
        try {
            $rootPrefix = $packDirectory.FullName.TrimEnd([System.IO.Path]::DirectorySeparatorChar) +
                [System.IO.Path]::DirectorySeparatorChar
            foreach ($sourceFile in Get-ChildItem -LiteralPath $packDirectory.FullName -File -Recurse | Sort-Object FullName) {
                $entryName = $sourceFile.FullName.Substring($rootPrefix.Length).Replace('\', '/')
                $entry = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = $fixedTimestamp
                $inputStream = $sourceFile.OpenRead()
                try {
                    $outputStream = $entry.Open()
                    try { $inputStream.CopyTo($outputStream) }
                    finally { $outputStream.Dispose() }
                }
                finally { $inputStream.Dispose() }
            }
        }
        finally { $archive.Dispose() }
    }
    finally { $archiveStream.Dispose() }

    $archive = Get-Item -LiteralPath $archivePath
    $digest = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{
        Pack = $packDirectory.Name
        File = $archive.Name
        SizeBytes = $archive.Length
        Sha256 = $digest
    }
}
