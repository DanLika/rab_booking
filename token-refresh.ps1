# Shortcut za brzi token refresh
# Poziva Quick-TokenRefresh.ps1 iz .claude foldera

Write-Host "UPOZORENJE: Browser će se otvoriti za OAuth autentikaciju!" -ForegroundColor Yellow
$confirm = Read-Host "Nastavi? (Y/N)"

if ($confirm -eq "Y" -or $confirm -eq "y") {
    & "$env:USERPROFILE\.claude\Quick-TokenRefresh.ps1"
} else {
    Write-Host "Otkazano." -ForegroundColor Red
}
