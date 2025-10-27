@echo off
echo ========================================
echo FULL DEPLOYMENT - Owner App + Widget
echo ========================================
echo.

REM Build Owner App
echo [1/4] Building Owner App...
call build_owner_web.bat

REM Build Widget
echo.
echo [2/4] Building Widget...
call build_widget_web.bat

REM Deploy both to Firebase
echo.
echo [3/4] Deploying to Firebase...
firebase deploy --only hosting

echo.
echo [4/4] Deployment complete!
echo ========================================
echo.
echo Owner App: https://rab-booking-owner.web.app
echo Widget:    https://rab-booking-widget.web.app
echo.
echo ========================================
pause
