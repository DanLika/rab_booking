# HITNO - Ukloni pogrešan environment variable token

Write-Host "Uklanjam CLAUDE_CODE_OAUTH_TOKEN environment variable..." -ForegroundColor Yellow

# Ukloni env variable
[System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_OAUTH_TOKEN", $null, [System.EnvironmentVariableTarget]::User)

Write-Host "✓ Environment variable uklonjen!" -ForegroundColor Green
Write-Host ""

# Verifikuj
$token = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_OAUTH_TOKEN", [System.EnvironmentVariableTarget]::User)

if ([string]::IsNullOrEmpty($token)) {
    Write-Host "✓ USPJEŠNO! CLAUDE_CODE_OAUTH_TOKEN je uklonjen." -ForegroundColor Green
    Write-Host ""
    Write-Host "Sada ćeš nastaviti koristiti credentials iz:" -ForegroundColor Cyan
    Write-Host "  C:\Users\W10\.claude\.credentials.json" -ForegroundColor White
    Write-Host ""
    Write-Host "  → stepanic.matija@gmail.com (MAX plan)" -ForegroundColor Green
    Write-Host "  → Desktop će automatski održavati token" -ForegroundColor Green
}
else {
    Write-Host "✗ GREŠKA: Token nije uklonjen!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Restart VS Code da primjeniš promjene." -ForegroundColor Cyan
