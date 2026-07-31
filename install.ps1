# RAi installer — Windows PowerShell
# Usage: irm https://raw.githubusercontent.com/wiiscale/rai-pub/main/install.ps1 | iex

param(
    [string]$Version = "",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$REPO = "wiiscale/rai-pub"
$INSTALL_DIR = if ($env:RAI_INSTALL_DIR) { $env:RAI_INSTALL_DIR } else { "$env:LOCALAPPDATA\rai\bin" }

if ($Help) {
    Write-Host "Usage: .\install.ps1 [-Version vX.Y.Z]"
    exit 0
}

Write-Host ""
Write-Host "  RAi — Reasonary AI Code"
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

$DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$Version/rai-$Version-$TARGET.zip"
$CHECKSUM_URL = "https://github.com/$REPO/releases/download/$Version/checksums.txt"

$TMPDIR = Join-Path $env:TEMP "rai-install-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Force -Path $TMPDIR | Out-Null

try {
    # Download
    Write-Host "-> Downloading..."
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile "$TMPDIR\rai.zip"
    Invoke-WebRequest -Uri $CHECKSUM_URL -OutFile "$TMPDIR\checksums.txt"

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
