#Requires -Version 5.1
<#
.SYNOPSIS
Blocks the 16 compromised eMudhra intermediate certificates and cross-signs.
.DESCRIPTION
Uses an offline, SHA-256 pinned manifest from the incident advisory:
https://emudhra.we-have-a-problem.com/
Only Windows certificate-store clients are covered. Independent CA bundles
must be updated separately. Run Block in an elevated PowerShell terminal.
Status and -WhatIf do not change the certificate store or require elevation.
To undo, remove only certificates reported as Added by this script from
certlm.msc > Untrusted Certificates. Preserve pre-existing vendor blocks.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Block', 'Status')]
    [string]$Action = 'Block'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$manifestPath = Join-Path $PSScriptRoot 'emudhra-compromised-intermediates.json'
$expectedHash = 'F67B3ABE9B4879F4E91874ED041BECCD71257F1DB41C588C724CCF12AA90C59E'
if ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Manifest SHA-256 mismatch. No certificates were imported.'
}
$entries = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($entries.Count -ne 16) {
    throw 'Expected exactly 16 certificates. No certificates were imported.'
}

# Validate the entire manifest before opening the store for writes.
$certificates = @()
$hasher = [System.Security.Cryptography.SHA256]::Create()
try {
    foreach ($entry in $entries) {
        $base64 = $entry.pem -replace '-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s', ''
        $der = [Convert]::FromBase64String($base64)
        $actualHash = [BitConverter]::ToString($hasher.ComputeHash($der)).Replace('-', '')
        if ($actualHash -ne $entry.sha256) {
            throw "Certificate SHA-256 mismatch: $($entry.name)"
        }
        $certificates += [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($der)
    }

    if ($Action -eq 'Block' -and -not $WhatIfPreference) {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
        if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Run Block from an elevated PowerShell terminal, or use -Action Status / -WhatIf.'
        }
    }

    $store = [System.Security.Cryptography.X509Certificates.X509Store]::new('Disallowed', 'LocalMachine')
    try {
        $flags = [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly
        if ($Action -eq 'Block' -and -not $WhatIfPreference) {
            $flags = [System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite
        }
        $store.Open($flags)
        foreach ($certificate in $certificates) {
            $present = $store.Certificates.Find(
                [System.Security.Cryptography.X509Certificates.X509FindType]::FindByThumbprint,
                $certificate.Thumbprint,
                $false
            ).Count -gt 0
            $status = 'Missing'
            if ($present) {
                $status = 'Already blocked'
            }
            elseif ($Action -eq 'Block' -and $PSCmdlet.ShouldProcess(
                "$($certificate.Subject) [$($certificate.Thumbprint)]", 'Add to LocalMachine\Disallowed'
            )) {
                $store.Add($certificate)
                if ($store.Certificates.Find('FindByThumbprint', $certificate.Thumbprint, $false).Count -eq 0) {
                    throw "Failed to verify imported certificate: $($certificate.Thumbprint)"
                }
                $status = 'Added'
            }
            [pscustomobject]@{
                Status = $status
                Subject = $certificate.Subject
                Issuer = $certificate.Issuer
                Thumbprint = $certificate.Thumbprint
            }
        }
    }
    finally {
        if ($null -ne $store) { $store.Dispose() }
    }
}
finally {
    $hasher.Dispose()
    foreach ($certificate in $certificates) { $certificate.Dispose() }
}
