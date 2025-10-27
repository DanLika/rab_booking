@echo off
echo ========================================
echo Building OWNER APP (Web)
echo ========================================

REM Clean previous build
if exist build\web_owner rmdir /s /q build\web_owner

REM Build owner app
flutter build web --target lib/main.dart --output build/web_owner --release

echo.
echo ========================================
echo Owner App build complete!
echo Output: build/web_owner
echo ========================================
echo.
echo To deploy to Firebase:
echo firebase deploy --only hosting:owner
echo.
pause
