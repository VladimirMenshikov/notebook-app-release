# ============================================================
# Notebook App - Windows Installer Builder
# ============================================================

param(
    [string]$Version = "1.0.6",
    [string]$AppFolder = "..\..\NotebookApp-$Version-windows-x64"
)

$ErrorActionPreference = "Stop"
$BuildRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Notebook App - Installer Builder" -ForegroundColor Cyan
Write-Host " Version: $Version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Inno Setup
$isccPaths = @(
    "${env:LOCALAPPDATA}\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles}\Inno Setup 6\ISCC.exe"
)
$iscc = $null
foreach($p in $isccPaths) {
    if (Test-Path $p) { $iscc = $p; break }
}
if (-not $iscc) {
    Write-Host "ERROR: Inno Setup not found" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Inno Setup: $iscc" -ForegroundColor Green

# Check app folder
$fullAppFolder = Join-Path $BuildRoot $AppFolder
if (-not (Test-Path (Join-Path $fullAppFolder "notebook_app.exe"))) {
    Write-Host "ERROR: Application folder not found:" -ForegroundColor Red
    Write-Host "  $fullAppFolder" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] App folder: $fullAppFolder" -ForegroundColor Green

# Build
$issFile = Join-Path $BuildRoot "NotebookApp.iss"
Write-Host ""
Write-Host "[BUILD] Running Inno Setup..." -ForegroundColor Cyan

& $iscc $issFile

if ($LASTEXITCODE -eq 0) {
    $outputFile = Join-Path $BuildRoot "NotebookApp-${Version}-windows-x64-setup.exe"
    if (Test-Path $outputFile) {
        $size = [math]::Round((Get-Item $outputFile).Length / 1MB, 1)
        Write-Host ""
        Write-Host "SUCCESS!" -ForegroundColor Green
        Write-Host " Output: $outputFile" -ForegroundColor Green
        Write-Host " Size:   ${size} MB" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Output not found" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ERROR: Inno Setup failed (exit: $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}