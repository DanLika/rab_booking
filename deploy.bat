@echo off
REM =====================================================
REM RAB Booking - Quick Deployment Script (Windows)
REM =====================================================

echo.
echo ============================================
echo   RAB BOOKING - DEPLOYMENT SCRIPT
echo ============================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter: https://flutter.dev/docs/get-started/install/windows
    pause
    exit /b 1
)

echo [1/5] Checking Flutter installation...
flutter --version
echo.

echo [2/5] Cleaning previous builds...
flutter clean
echo.

echo [3/5] Getting dependencies...
flutter pub get
echo.

echo [4/5] Building for web (production)...
echo This may take 2-5 minutes...
flutter build web --release --web-renderer canvaskit
echo.

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed!
    echo Check the error messages above.
    pause
    exit /b 1
)

echo [5/5] Build completed successfully!
echo.
echo ============================================
echo   BUILD OUTPUT: build\web\
echo ============================================
echo.
echo Next steps:
echo.
echo 1. DEPLOY TO NETLIFY (Drag ^& Drop):
echo    - Visit: https://app.netlify.com/drop
echo    - Drag the "build\web" folder onto the page
echo    - Wait 30-60 seconds
echo    - Get your URL: https://random-name.netlify.app
echo.
echo 2. DEPLOY TO NETLIFY (CLI):
echo    npm install -g netlify-cli
echo    netlify login
echo    netlify deploy --prod --dir=build\web
echo.
echo 3. DEPLOY VIA GITHUB:
echo    git add .
echo    git commit -m "chore: Deploy to Netlify"
echo    git push origin mvp/saas-booking-system
echo    Then connect GitHub repo in Netlify dashboard
echo.
echo ============================================
echo.

pause
