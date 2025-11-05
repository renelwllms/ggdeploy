@echo off
REM GG LMS Quick Update Script (Batch)
REM This script pulls the latest changes from git and rebuilds the application

echo ==================================
echo GG LMS Quick Update Script
echo ==================================
echo.

cd /d "%~dp0"

echo Step 1: Pulling latest frontend changes...
cd leaner_V1.1-main\leaner_V1.1-main
git pull origin master
if errorlevel 1 (
    echo Failed to pull frontend changes
    pause
    exit /b 1
)
echo Frontend updated successfully
echo.

echo Step 2: Pulling latest backend changes...
cd ..\..
cd server_V1.1-main\server_V1.1-main
git pull origin master
if errorlevel 1 (
    echo Failed to pull backend changes
    pause
    exit /b 1
)
echo Backend updated successfully
echo.

echo Step 3: Rebuilding frontend...
cd ..\..
cd leaner_V1.1-main\leaner_V1.1-main
call npm run build
if errorlevel 1 (
    echo Failed to build frontend
    pause
    exit /b 1
)
echo Frontend built successfully
echo.

echo Step 4: Deploying frontend to backend...
cd ..\..
cd server_V1.1-main\server_V1.1-main
if exist public\* del /Q public\*
xcopy /E /I /Y ..\..\leaner_V1.1-main\leaner_V1.1-main\dist\* public\
if errorlevel 1 (
    echo Failed to deploy frontend
    pause
    exit /b 1
)
echo Frontend deployed successfully
echo.

echo ==================================
echo Update completed successfully!
echo ==================================
echo.
echo Note: You may need to restart the server for backend changes to take effect
echo.
pause
