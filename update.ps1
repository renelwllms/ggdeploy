# GG LMS Quick Update Script (PowerShell)
# This script pulls the latest changes from git and rebuilds the application
# WITHOUT doing full setup (no npm install, no server restart)

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Blue
Write-Host "GG LMS Quick Update Script" -ForegroundColor Blue
Write-Host "==================================" -ForegroundColor Blue
Write-Host ""

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$FRONTEND_DIR = Join-Path $SCRIPT_DIR "leaner_V1.1-main\leaner_V1.1-main"
$BACKEND_DIR = Join-Path $SCRIPT_DIR "server_V1.1-main\server_V1.1-main"

try {
    Write-Host "Step 1: Pulling latest frontend changes..." -ForegroundColor Cyan
    Set-Location $FRONTEND_DIR
    git pull origin master
    Write-Host "✓ Frontend updated successfully" -ForegroundColor Green
    Write-Host ""

    Write-Host "Step 2: Pulling latest backend changes..." -ForegroundColor Cyan
    Set-Location $BACKEND_DIR
    git pull origin master
    Write-Host "✓ Backend updated successfully" -ForegroundColor Green
    Write-Host ""

    Write-Host "Step 3: Rebuilding frontend..." -ForegroundColor Cyan
    Set-Location $FRONTEND_DIR
    npm run build
    Write-Host "✓ Frontend built successfully" -ForegroundColor Green
    Write-Host ""

    Write-Host "Step 4: Deploying frontend to backend..." -ForegroundColor Cyan
    $PublicDir = Join-Path $BACKEND_DIR "public"
    Remove-Item -Path "$PublicDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    $DistDir = Join-Path $FRONTEND_DIR "dist"
    Copy-Item -Path "$DistDir\*" -Destination $PublicDir -Recurse -Force
    Write-Host "✓ Frontend deployed successfully" -ForegroundColor Green
    Write-Host ""

    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✓ Update completed successfully!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: You may need to restart the server for backend changes to take effect:" -ForegroundColor Yellow
    Write-Host "  pm2 restart gg-lms" -ForegroundColor White
    Write-Host ""
    Write-Host "Or if running manually:" -ForegroundColor Yellow
    Write-Host "  1. Stop the current server (Ctrl+C)" -ForegroundColor White
    Write-Host "  2. cd $BACKEND_DIR" -ForegroundColor White
    Write-Host "  3. node app.js" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "✗ Update failed: $_" -ForegroundColor Red
    exit 1
}
