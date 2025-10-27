@echo off
echo ========================================
echo 🚀 Starting Widget Server
echo ========================================
echo.

cd build\web

echo Widget will be available at:
echo.
echo   http://localhost:8080/?unit=test-unit-123
echo.
echo Press Ctrl+C to stop the server
echo.
echo ========================================

python -m http.server 8080
