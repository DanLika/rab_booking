@echo off
echo.
echo ========================================
echo   Building BedBooking Widget for Web
echo ========================================
echo.

REM Clean previous build
echo [1/4] Cleaning previous build...
if exist build\web rmdir /s /q build\web
if exist build\web_widget rmdir /s /q build\web_widget

REM Build Flutter web app
echo.
echo [2/4] Building Flutter web app...
flutter build web --release --base-href /

REM Check if build succeeded
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Flutter build failed!
    exit /b 1
)

REM Copy to widget hosting folder
echo.
echo [3/4] Copying to widget hosting folder...
xcopy /E /I /Y build\web build\web_widget

REM Done
echo.
echo [4/4] Build complete!
echo.
echo ========================================
echo   Widget ready for deployment!
echo ========================================
echo.
echo Next steps:
echo   1. Test locally: firebase serve --only hosting:widget
echo   2. Deploy: firebase deploy --only hosting:widget
echo.
