[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$releaseUri = 'https://api.github.com/repos/yuru7/HackGen/releases/latest'
$release = Invoke-RestMethod -Uri $releaseUri -Headers @{ Accept = 'application/vnd.github+json' }
$asset = $release.assets |
    Where-Object { $_.name -match '^HackGen_NF_.*\.zip$' } |
    Select-Object -First 1

if (-not $asset) {
    $available = ($release.assets.name | Sort-Object) -join ', '
    throw "HackGen NF archive was not found in the latest release. Available assets: $available"
}

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("hackgen-nf-" + [guid]::NewGuid())
$archivePath = Join-Path $temporaryRoot $asset.name
$extractPath = Join-Path $temporaryRoot 'extracted'
$fontDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontRegistryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

try {
    New-Item -ItemType Directory -Path $temporaryRoot, $extractPath, $fontDirectory -Force | Out-Null
    New-Item -Path $fontRegistryPath -Force | Out-Null
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath
    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath -Force

    # Match the normal half-width 1:full-width 2 families while excluding the
    # HackGen35 variants that are shipped in the same Nerd Font archive.
    $fonts = Get-ChildItem -LiteralPath $extractPath -Recurse -File |
        Where-Object { $_.Name -match '^HackGen(?:Console)?NF-.*\.ttf$' }

    if (-not $fonts) {
        throw 'No HackGen NF 1:2 TrueType fonts were found in the downloaded archive.'
    }

    foreach ($font in $fonts) {
        $destination = Join-Path $fontDirectory $font.Name
        Copy-Item -LiteralPath $font.FullName -Destination $destination -Force
        $registryName = "{0} (TrueType)" -f $font.BaseName
        New-ItemProperty `
            -Path $fontRegistryPath `
            -Name $registryName `
            -Value $destination `
            -PropertyType String `
            -Force | Out-Null
        Write-Host "Installed $($font.Name)"
    }

    Write-Host 'HackGen NF (half-width 1:full-width 2) was installed for the current Windows user.'
    Write-Host 'Restart Windows Terminal, then select HackGen Console NF in its profile settings.'
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
