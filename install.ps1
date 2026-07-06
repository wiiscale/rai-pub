# rai installer — Windows PowerShell
# Downloads from public mirror wiiscale/rai-pub releases (no auth required).
# Usage: .\install.ps1 [-Version vX.Y.Z] [-Help]
param(
    [string]$Version = "",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$REPO = "wiiscale/rai-pub"
$INSTALL_DIR = if ($env:RAI_INSTALL_DIR) { $env:RAI_INSTALL_DIR } else { "$env:LOCALAPPDATA\rai\bin" }

if ($Help) {
    Write-Host "Usage: .\install.ps1 [-Version vX.Y.Z] [-Help]"
    Write-Host "  -Version  Pin to a specific release tag (default: latest)"
    Write-Host "  -Help     Show this help"
    exit 0
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  ██████╗  █████╗ ██╗     ██████╗ ██████╗ ██████╗ ███████╗"
Write-Host "  ██╔══██╗██╔══██╗██║    ██╔════╝██╔═══██╗██╔══██╗██╔════╝"
Write-Host "  ██████╔╝███████║██║    ██║     ██║   ██║██║  ██║█████╗ "
Write-Host "  ██╔══██╗██╔══██║██║    ██║     ██║   ██║██║  ██║██╔══╝"
Write-Host "  ██║  ██║██║  ██║██║    ╚██████╗╚██████╔╝██████╔╝███████╗"
Write-Host "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═════╝ ╚═════╝╚══════╝ ╚══════╝"
Write-Host "  Reasonary Ai Code — AI-powered coding assistant"
Write-Host ""

# ---------------------------------------------------------------------------
# Detect target
# ---------------------------------------------------------------------------
$arch = $env:PROCESSOR_ARCHITECTURE
if ($arch -ne "AMD64") {
    Write-Host "ERROR: Unsupported architecture: $arch (only AMD64/x64 supported)" -ForegroundColor Red
    exit 1
}
$TARGET = "windows-x64"

# ---------------------------------------------------------------------------
# Resolve version
# ---------------------------------------------------------------------------
if (-not $Version) {
    Write-Host "-> Resolving latest release..."
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest"
        $Version = $release.tag_name
    } catch {
        Write-Host "ERROR: Could not determine latest release." -ForegroundColor Red
        exit 1
    }
    if (-not $Version) {
        Write-Host "ERROR: Could not determine latest release." -ForegroundColor Red
        exit 1
    }
}

$TAG = $Version
$V_NUM = $Version -replace '^v', ''
$ASSET = "rai-v${V_NUM}-${TARGET}.zip"

Write-Host "-> Installing rai ${TAG} for ${TARGET}..."

# ---------------------------------------------------------------------------
# tmp in install dir to avoid EXDEV cross-filesystem issues
# ---------------------------------------------------------------------------
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}

$TMP_ARCHIVE = Join-Path $INSTALL_DIR ".rai-installer-archive-$PID.zip"
$TMP_CHECKSUMS = Join-Path $INSTALL_DIR ".rai-installer-checksums-$PID.txt"
$TMP_EXTRACT = Join-Path $INSTALL_DIR ".rai-installer-extract-$PID"

try {
    # -----------------------------------------------------------------------
    # Download archive + checksums from public mirror
    # -----------------------------------------------------------------------
    $baseUrl = "https://github.com/$REPO/releases/download/$TAG"

    Write-Host "-> Downloading ${ASSET}..."
    Invoke-WebRequest -Uri "$baseUrl/$ASSET" -OutFile $TMP_ARCHIVE -UseBasicParsing

    Write-Host "-> Downloading checksums.txt..."
    Invoke-WebRequest -Uri "$baseUrl/checksums.txt" -OutFile $TMP_CHECKSUMS -UseBasicParsing

    # -----------------------------------------------------------------------
    # Verify SHA256 checksum (handles both binary mode "HASH  FILE" and
    # text mode "HASH *FILE" produced by sha256sum)
    # -----------------------------------------------------------------------
    Write-Host "-> Verifying checksum..."
    $lines = Get-Content $TMP_CHECKSUMS
    $line = $lines | Where-Object { $_ -match [regex]::Escape($ASSET) } | Select-Object -First 1
    if (-not $line) {
        Write-Host "ERROR: No checksum found for ${ASSET} in checksums.txt" -ForegroundColor Red
        exit 1
    }
    $EXPECTED = ($line -split '\s+', 2)[0].TrimStart('*').ToLower()

    $ACTUAL = (Get-FileHash $TMP_ARCHIVE -Algorithm SHA256).Hash.ToLower()

    if ($EXPECTED -ne $ACTUAL) {
        Write-Host "ERROR: Checksum mismatch!" -ForegroundColor Red
        Write-Host "  Expected: $EXPECTED" -ForegroundColor Red
        Write-Host "  Got:      $ACTUAL" -ForegroundColor Red
        exit 1
    }
    Write-Host "  OK Checksum verified" -ForegroundColor Green

    # -----------------------------------------------------------------------
    # Extract archive
    # -----------------------------------------------------------------------
    if (Test-Path $TMP_EXTRACT) { Remove-Item $TMP_EXTRACT -Recurse -Force }
    Expand-Archive -Path $TMP_ARCHIVE -DestinationPath $TMP_EXTRACT -Force

    $binarySrc = Join-Path $TMP_EXTRACT "rai.exe"
    if (-not (Test-Path $binarySrc)) {
        Write-Host "ERROR: rai.exe not found in archive" -ForegroundColor Red
        exit 1
    }

    # -----------------------------------------------------------------------
    # rename existing rai.exe -> rai.exe.old (rustup/scoop pattern)
    # -----------------------------------------------------------------------
    $installPath = Join-Path $INSTALL_DIR "rai.exe"

    if (Test-Path $installPath) {
        $oldPath = "${installPath}.old"
        if (Test-Path $oldPath) { Remove-Item $oldPath -Force }
        Move-Item $installPath $oldPath -Force
        Write-Host "-> Renamed existing binary to rai.exe.old"
    }

    Copy-Item $binarySrc $installPath -Force
    Write-Host "-> Installed to ${installPath}"

    # -----------------------------------------------------------------------
    # PATH hint + persist
    # -----------------------------------------------------------------------
    $sessionPath = $env:Path
    if ($sessionPath -notmatch [regex]::Escape($INSTALL_DIR)) {
        $env:Path = "${INSTALL_DIR};${sessionPath}"
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notmatch [regex]::Escape($INSTALL_DIR)) {
        $newPath = if ($userPath) { "${userPath};${INSTALL_DIR}" } else { $INSTALL_DIR }
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "-> Added ${INSTALL_DIR} to user PATH (restart terminal to take effect)"
    }

    # -----------------------------------------------------------------------
    # Verify
    # -----------------------------------------------------------------------
    Write-Host "-> Verifying installation..."
    & $installPath --version

    Write-Host ""
    Write-Host "rai ${TAG} installed successfully." -ForegroundColor Green

    Write-Host ""
    Write-Host "Quick start:"
    Write-Host "  rai                          # interactive mode"
    Write-Host "  rai prompt 'hello world'     # one-shot prompt"
    Write-Host "  rai doctor                   # health check"

} finally {
    # -----------------------------------------------------------------------
    # Cleanup temp files
    # -----------------------------------------------------------------------
    if (Test-Path $TMP_ARCHIVE)    { Remove-Item $TMP_ARCHIVE -Force -ErrorAction SilentlyContinue }
    if (Test-Path $TMP_CHECKSUMS)  { Remove-Item $TMP_CHECKSUMS -Force -ErrorAction SilentlyContinue }
    if (Test-Path $TMP_EXTRACT)    { Remove-Item $TMP_EXTRACT -Recurse -Force -ErrorAction SilentlyContinue }
}
