@echo off
REM Auto-login script for Claude Code
echo Starting Claude Code...
echo.

REM Navigate to project directory
cd /d C:\Users\W10\dusko1\rab_booking

REM Check auth status silently
claude auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo Authentication required. Opening login...
    claude login
    if %errorlevel% neq 0 (
        echo Login failed. Please try again.
        pause
        exit /b 1
    )
)

REM Start Claude Code
echo Authenticated successfully!
claude

REM Keep window open if there's an error
if %errorlevel% neq 0 (
    echo.
    echo Error occurred. Press any key to close...
    pause >nul
)
