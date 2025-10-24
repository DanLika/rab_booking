# Auto-login script for Claude Code (PowerShell)
Write-Host "Starting Claude Code..." -ForegroundColor Cyan
Write-Host ""

# Navigate to project directory
Set-Location "C:\Users\W10\dusko1\rab_booking"

# Check if authenticated
try {
    $authCheck = & claude auth status 2>&1
    $isAuthenticated = $LASTEXITCODE -eq 0

    if (-not $isAuthenticated) {
        Write-Host "Authentication required. Opening login..." -ForegroundColor Yellow
        & claude login

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Login failed. Please try again." -ForegroundColor Red
            Read-Host "Press Enter to close"
            exit 1
        }
    }

    Write-Host "Authenticated successfully!" -ForegroundColor Green
    Write-Host ""

    # Start Claude Code
    & claude

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to close"
}
