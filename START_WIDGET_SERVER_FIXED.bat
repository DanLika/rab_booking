@echo off
echo ========================================
echo 🚀 Starting Widget Server
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "build\web\index.html" (
    echo ❌ ERROR: build\web\index.html not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

cd build\web

echo ✅ Found widget files!
echo.
echo Widget will be available at:
echo.
echo   http://localhost:8080/?unit=test-unit-123
echo.
echo Or use the test page:
echo   Open web/widget_test.html in browser
echo.
echo Press Ctrl+C to stop the server
echo.
echo ========================================
echo.

python -m http.server 8080
