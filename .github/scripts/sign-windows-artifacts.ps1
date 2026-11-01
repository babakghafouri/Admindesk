param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$ExpectedThumbprint,

    [switch]$ExportThumbprint
)

$ErrorActionPreference = "Stop"

$pfxBase64 = $env:WINDOWS_CODESIGN_PFX_BASE64
$pfxPassword = $env:WINDOWS_CODESIGN_PFX_PASSWORD

if ([string]::IsNullOrWhiteSpace($pfxBase64) -and [string]::IsNullOrWhiteSpace($pfxPassword)) {
    Write-Host "::notice::No GitHub Windows code-signing certificate is configured. Continuing with unsigned Windows artifacts."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($pfxBase64) -or [string]::IsNullOrWhiteSpace($pfxPassword)) {
    throw "Configure both WINDOWS_CODESIGN_PFX_BASE64 and WINDOWS_CODESIGN_PFX_PASSWORD GitHub Actions secrets, or leave both empty."
}

$pfxPath = Join-Path $env:RUNNER_TEMP "admindesk-windows-codesign.pfx"

try {
    $pfxBytes = [Convert]::FromBase64String(($pfxBase64 -replace "\s", ""))
    [System.IO.File]::WriteAllBytes($pfxPath, $pfxBytes)

    $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable -bor
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $pfxPath,
        $pfxPassword,
        $flags
    )

    if (-not $certificate.HasPrivateKey) {
        throw "The GitHub code-signing PFX does not contain a private key."
    }

    $now = Get-Date
    if ($certificate.NotBefore -gt $now -or $certificate.NotAfter -le $now) {
        throw "The GitHub code-signing certificate is not currently valid."
    }

    $ekuExtension = $certificate.Extensions |
        Where-Object { $_.Oid.Value -eq "2.5.29.37" } |
        Select-Object -First 1
    $ekuOids = @()
    if ($null -ne $ekuExtension) {
        $ekuOids = @($ekuExtension.EnhancedKeyUsages | ForEach-Object { $_.Value })
    }
    if ($ekuOids -notcontains "1.3.6.1.5.5.7.3.3") {
        throw "The certificate does not include the Code Signing extended key usage."
    }

    $expected = $ExpectedThumbprint
    if ([string]::IsNullOrWhiteSpace($expected)) {
        $expected = $env:ADMIN_DESK_SIGNER_THUMBPRINT
    }
    if (-not [string]::IsNullOrWhiteSpace($expected) -and
        $certificate.Thumbprint -ne $expected) {
        throw "The signing certificate changed between application and installer signing."
    }

    $programFilesX86 = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86)
    $kitRoot = Join-Path $programFilesX86 "Windows Kits\10\bin"
    $signTool = Get-ChildItem -Path $kitRoot -Filter "signtool.exe" -Recurse -File |
        Where-Object { $_.Directory.Name -eq "x64" } |
        Sort-Object -Property FullName -Descending |
        Select-Object -First 1
    if ($null -eq $signTool) {
        throw "Windows SDK signtool.exe (x64) was not found on the GitHub Actions runner."
    }

    $extensions = @(
        ".exe", ".dll", ".sys", ".vxd", ".msix", ".msixbundle",
        ".appx", ".appxbundle", ".msi", ".msp", ".msm", ".cab",
        ".ps1", ".psm1"
    )
    $files = @(
        Get-ChildItem -LiteralPath $Path -Recurse -File |
            Where-Object {
                $extension = $_.Extension.ToLowerInvariant()
                $isSignable = $extensions -contains $extension
                $isSeparatelySignedDriverPayload =
                    $_.FullName -match "(?i)[\\/](RustDeskPrinterDriver|usbmmidd_v2)([\\/]|$)"
                $isSignable -and
                    (-not $isSeparatelySignedDriverPayload -or $extension -eq ".exe")
            }
    )

    if ($files.Count -eq 0) {
        throw "No signable Windows files were found under $Path."
    }

    foreach ($file in $files) {
        $signArgs = @(
            "sign",
            "/fd", "SHA256",
            "/f", $pfxPath,
            "/p", $pfxPassword,
            "/d", "AdminDesk",
            "/tr", "http://timestamp.digicert.com",
            "/td", "SHA256",
            $file.FullName
        )
        & $signTool.FullName @signArgs
        if ($LASTEXITCODE -ne 0) {
            throw "SignTool failed for $($file.FullName) with exit code $LASTEXITCODE."
        }

        $signature = Get-AuthenticodeSignature -LiteralPath $file.FullName
        if ($signature.Status.ToString() -ne "Valid") {
            throw "Authenticode verification failed for $($file.FullName): $($signature.Status)."
        }
        if ($null -eq $signature.SignerCertificate -or
            $signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint) {
            throw "The resulting signature does not match the configured AdminDesk certificate: $($file.Name)."
        }

        Write-Host "Verified $($file.Name) | $($certificate.Subject) | Thumbprint $($certificate.Thumbprint) | Expires $($certificate.NotAfter.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss UTC'))"
    }

    if ($ExportThumbprint) {
        "ADMIN_DESK_SIGNER_THUMBPRINT=$($certificate.Thumbprint)" |
            Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
    }
}
finally {
    if (Test-Path -LiteralPath $pfxPath) {
        Remove-Item -LiteralPath $pfxPath -Force
    }
}
