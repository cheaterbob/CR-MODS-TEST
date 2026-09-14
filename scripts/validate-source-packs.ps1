[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $repositoryRoot 'catalog-v1.json'
$catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json

if ($catalog.schemaVersion -ne 1 -or $null -eq $catalog.packs) {
    throw 'catalog-v1.json must use schemaVersion 1 and contain a packs array.'
}

$ids = @{}
foreach ($packDirectory in Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'packs') -Directory) {
    $manifestPath = Join-Path $packDirectory.FullName 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Missing manifest.json in $($packDirectory.Name)."
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.id -ne $packDirectory.Name) {
        throw "Pack folder $($packDirectory.Name) does not match manifest ID $($manifest.id)."
    }
    if ($ids.ContainsKey($manifest.id)) {
        throw "Duplicate pack ID $($manifest.id)."
    }
    $ids[$manifest.id] = $true
    foreach ($root in $manifest.contentRoots) {
        $contentRoot = Join-Path $packDirectory.FullName $root
        if (-not (Test-Path -LiteralPath $contentRoot -PathType Container)) {
            throw "Missing content root $root for $($manifest.id)."
        }
        Get-ChildItem -LiteralPath $contentRoot -Filter '*.json' -File -Recurse |
            ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json | Out-Null }
    }
}

Write-Host "Validated $($ids.Count) source packs and catalog JSON."

