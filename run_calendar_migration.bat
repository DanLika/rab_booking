@echo off
echo ============================================
echo  RAB BOOKING - CALENDAR MIGRATION
echo ============================================
echo.
echo Running migration: 20250120000005_enhance_calendar_system.sql
echo.

cd /d "%~dp0"

REM Set connection string
set "PROJECT_REF=fnfapeopfnkzkkwobhij"
set "DB_PASSWORD=RabBooking.db"
set "DB_URL=postgresql://postgres:%DB_PASSWORD%@db.%PROJECT_REF%.supabase.co:5432/postgres"

echo Connecting to: rab-booking-dev
echo.

REM Run migration using psql
psql "%DB_URL%" -f "supabase\migrations\20250120000005_enhance_calendar_system.sql"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================
    echo  MIGRATION SUCCESSFUL!
    echo ============================================
    echo.
    echo Running verification tests...
    echo.

    psql "%DB_URL%" -f "supabase\test_calendar_functions.sql"

    echo.
    echo ============================================
    echo  CALENDAR SYSTEM DEPLOYED!
    echo ============================================
) else (
    echo.
    echo ============================================
    echo  MIGRATION FAILED!
    echo ============================================
    echo.
    echo Please check the error messages above.
)

pause
