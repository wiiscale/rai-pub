# RAi installer — Windows PowerShell
# Usage: irm https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.ps1 | iex

param(
    [string]$Version = "",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$REPO = "wiiscale/rai-pub"
$INSTALL_DIR = if ($env:RAI_INSTALL_DIR) { $env:RAI_INSTALL_DIR } else { "$env:LOCALAPPDATA\rai\bin" }

# Release public key. It authenticates checksums.txt, so a tampered archive (or
# an attacker-controlled checksum file) cannot pass verification.
# Owner: run 'task release:keygen' and paste rai-release.pub here.
$RAI_RELEASE_PUBKEY = '-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqisonAhetRCMmT1n/ulr
5AP1FqCa398fNTYtGt/7KeIcTE9/PyHoV5RpwZhbWx2hLKBRLBY6puFXxAWAXOTF
USjSP+MNcjRdSiDkAvjL8N6jwdQoSfaRjKstBy6VgvhQWiwjcH21VgcH98BqC0Nz
ZibXGBM41SPxdDuQZc7FtBnA3z5AmFMydBIOSp+eAloqK9leVAEHIu1QknumndGW
LwIZDvR20nJYQDVlPiRaKqhOqu5ptfvcrFr+HZNjvlXytKiDmbFaEEr1NI0znnx+
9fMCgsGVYzuNeIoSJL+kYLwHSxUHHyjHIodBcqvXYupl3leN/XjVvqxdbHOkAyga
q6mhGSNu6LIi9+aHsw5le656P1xonF9ctiyAw/uV9lmPL7Jk6fbJjHddUxcZwzkS
pwZtKZaCdmeE3fuHWXZOR+iRmYVksUGDiuErr7w13hY8f8lHKqCWyUBrWGT1RwSj
Zt4pTkdEJAM19dh2Mn0cv11wEF7u0tddNMIUZGdrtjBmc5saRKyxZOmV2FUIh4uK
C0zvcf58IKI6DJuBWy8RBgYYJWmUKs6xO1RBpV2LGvygo59dXwhyRxzuPcfWrpae
MTFWbBYntasa/cNVH9O4WY5FO2cvs+kWR2JEbiTUBnckDzIz0AOhgXR+VhQS0NzF
heVGOkn1eh9oHph1j3l0zSECAwEAAQ==
-----END PUBLIC KEY-----'

# Where release assets are downloaded from. Override only for local testing
# (the trust anchor above still decides what is accepted).
$RAI_RELEASE_BASE_URL = if ($env:RAI_RELEASE_BASE_URL) {
    $env:RAI_RELEASE_BASE_URL
} else {
    "https://github.com/$REPO/releases/download"
}

if ($Help) {
    Write-Host "Usage: .\install.ps1 [-Version vX.Y.Z]"
    exit 0
}

Write-Host ""
Write-Host "  ██████╗  █████╗ ██╗     ██████╗ ██████╗ ██████╗ ███████╗"
Write-Host "  ██╔══██╗██╔══██╗██║    ██╔════╝██╔═══██╗██╔══██╗██╔════╝"
Write-Host "  ██████╔╝███████║██║    ██║     ██║   ██║██║  ██║█████╗ "
Write-Host "  ██╔══██╗██╔══██║██║    ██║     ██║   ██║██║  ██║██╔══╝"
Write-Host "  ██║  ██║██║  ██║██║    ╚██████╗╚██████╔╝██████╔╝███████╗"
Write-Host "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═════╝ ╚═════╝╚══════╝ ╚══════╝"
Write-Host "  Reasonary Ai Code — AI-powered coding assistant"
Write-Host ""

$arch = $env:PROCESSOR_ARCHITECTURE
if ($arch -ne "AMD64") {
    Write-Host "ERROR: Unsupported architecture: $arch (only x64 supported)" -ForegroundColor Red
    exit 1
}
$TARGET = "windows-amd64"

# Resolve version
if (-not $Version) {
    Write-Host "-> Resolving latest release..."
    try {
        $Version = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$REPO/main/VERSION").Content.Trim()
    } catch {
        Write-Host "ERROR: Could not resolve latest version" -ForegroundColor Red
        exit 1
    }
}
Write-Host "-> Installing rai $Version ($TARGET)..."

$DOWNLOAD_URL = "$RAI_RELEASE_BASE_URL/$Version/rai-$Version-$TARGET.zip"
$CHECKSUM_URL = "$RAI_RELEASE_BASE_URL/$Version/checksums.txt"
$SIGN_URL = "$RAI_RELEASE_BASE_URL/$Version/checksums.txt.sig"

$TMPDIR = Join-Path $env:TEMP "rai-install-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Force -Path $TMPDIR | Out-Null

try {
    # Download
    Write-Host "-> Downloading..."
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile "$TMPDIR\rai.zip"
    Invoke-WebRequest -Uri $CHECKSUM_URL -OutFile "$TMPDIR\checksums.txt"
    try {
        Invoke-WebRequest -Uri $SIGN_URL -OutFile "$TMPDIR\checksums.txt.sig"
    } catch {
        Write-Host "ERROR: missing checksums.txt.sig for $Version - refusing to install an unsigned release" -ForegroundColor Red
        exit 1
    }

    # Verify the release signature before trusting checksums.txt
    if ($RAI_RELEASE_PUBKEY -eq 'PASTE_PUBLIC_KEY_HERE') {
        Write-Host "ERROR: this installer has no release public key embedded (RAI_RELEASE_PUBKEY)." -ForegroundColor Red
        Write-Host "       Owner: run 'task release:keygen' and paste rai-release.pub into install.ps1." -ForegroundColor Red
        exit 1
    }
    Write-Host "-> Verifying release signature..."
    $pubPath = "$TMPDIR\rai-release.pub"
    Set-Content -Path $pubPath -Value $RAI_RELEASE_PUBKEY
    $verified = $false
    if (Get-Command openssl -ErrorAction SilentlyContinue) {
        & openssl dgst -sha256 -verify $pubPath -signature "$TMPDIR\checksums.txt.sig" "$TMPDIR\checksums.txt" | Out-Null
        $verified = ($LASTEXITCODE -eq 0)
    } elseif ($PSVersionTable.PSEdition -eq 'Core') {
        $rsa = [System.Security.Cryptography.RSA]::Create()
        $rsa.ImportFromPem($RAI_RELEASE_PUBKEY)
        $data = [System.IO.File]::ReadAllBytes("$TMPDIR\checksums.txt")
        $sig = [System.IO.File]::ReadAllBytes("$TMPDIR\checksums.txt.sig")
        $verified = $rsa.VerifyData($data, $sig,
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
    } else {
        Write-Host "ERROR: PowerShell 7+ or openssl on PATH is required to verify the release signature." -ForegroundColor Red
        exit 1
    }
    if (-not $verified) {
        Write-Host "ERROR: release signature verification FAILED - refusing to install." -ForegroundColor Red
        exit 1
    }

    # Verify checksum
    Write-Host "-> Verifying checksum..."
    $expected = (Select-String -Path "$TMPDIR\checksums.txt" -Pattern "rai-$Version-$TARGET.zip" | ForEach-Object { $_.Line.Split()[0] })
    $actual = (Get-FileHash -Path "$TMPDIR\rai.zip" -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) {
        Write-Host "ERROR: Checksum mismatch!" -ForegroundColor Red
        Write-Host "  Expected: $expected" -ForegroundColor Red
        Write-Host "  Actual:   $actual" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Checksum OK"

    # Extract
    Expand-Archive -Path "$TMPDIR\rai.zip" -DestinationPath "$TMPDIR\extracted"

    # Install
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    Copy-Item -Path "$TMPDIR\extracted\rai.exe" -Destination "$INSTALL_DIR\rai.exe" -Force

    # Built-in browser tools require no separate npm/Node/Playwright setup.
    Write-Host "-> Preparing browser runtime..."
    & "$INSTALL_DIR\rai.exe" browser install
    if ($LASTEXITCODE -ne 0) {
        throw "Browser runtime installation failed. Retry the installer or run rai browser install."
    }

    # Add to PATH for current session
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$INSTALL_DIR*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$INSTALL_DIR", "User")
        $env:PATH = "$env:PATH;$INSTALL_DIR"
    }

    Write-Host ""
    Write-Host "  -> Installed: $INSTALL_DIR\rai.exe"
    Write-Host ""
    Write-Host "  Run 'rai' to get started!"
    Write-Host "  (Restart your terminal if 'rai' is not found in PATH)"
} finally {
    Remove-Item -Recurse -Force $TMPDIR -ErrorAction SilentlyContinue
}
