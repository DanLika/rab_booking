@echo off
cls
echo.
echo ========================================
echo   Widget Server Starting...
echo ========================================
echo.
echo Widget URL: http://localhost:8080/?unit=test-unit-123
echo.
echo Press Ctrl+C to stop
echo ========================================
echo.

cd /d "%~dp0build\web"
python -m http.server 8080

pause
