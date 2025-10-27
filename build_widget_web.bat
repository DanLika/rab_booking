@echo off
echo ========================================
echo Building WIDGET (Embeddable iframe)
echo ========================================

REM Clean previous build
if exist build\web_widget rmdir /s /q build\web_widget

REM Build widget
flutter build web --target lib/widget_main.dart --output build/web_widget --release

echo.
echo ========================================
echo Widget build complete!
echo Output: build/web_widget
echo ========================================
echo.
echo To deploy to Firebase:
echo firebase deploy --only hosting:widget
echo.
echo Embed code:
echo ^<iframe src="https://widget.rabbooking.com/?unit=UNIT_ID" width="100%%" height="800"^>^</iframe^>
echo.
pause
