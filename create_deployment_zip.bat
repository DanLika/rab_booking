@echo off
REM RAB Booking - Create Deployment ZIP for Sevalla
REM This script creates a ZIP file from the build/web folder

echo ========================================
echo RAB Booking - Create Deployment ZIP
echo ========================================
echo.

REM Check if build/web exists
if not exist "build\web\" (
    echo ERROR: build\web\ folder not found!
    echo Please run: flutter build web --release
    echo.
    pause
    exit /b 1
)

echo [1/3] Checking build folder...
echo Found: build\web\
echo.

REM Create ZIP filename with timestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set timestamp=%mydate%_%mytime%
set zipfile=rab_booking_web_%timestamp%.zip

echo [2/3] Creating ZIP file...
echo Output: %zipfile%
echo.

REM Use PowerShell to create ZIP
powershell -command "Compress-Archive -Path 'build\web\*' -DestinationPath '%zipfile%' -Force"

if %errorlevel% neq 0 (
    echo ERROR: Failed to create ZIP file
    pause
    exit /b 1
)

echo [3/3] ZIP created successfully!
echo.
echo ========================================
echo DEPLOYMENT READY!
echo ========================================
echo.
echo ZIP File: %zipfile%
for %%I in ("%zipfile%") do echo File Size: %%~zI bytes
echo.
echo Next Steps:
echo 1. Login to https://sevalla.com
echo 2. Go to Static Site Hosting
echo 3. Create New Site
echo 4. Upload this ZIP file: %zipfile%
echo 5. Configure settings (index.html, HTTPS, SPA routing)
echo 6. Deploy!
echo.
echo For detailed instructions, see:
echo - SEVALLA_BUILD_COMPLETE.md
echo - SEVALLA_DEPLOYMENT_GUIDE.md
echo.
pause
