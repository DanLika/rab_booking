# Provjeri sve backup credentials fajlove

Write-Host "Provjeravam sve credentials backup-e..." -ForegroundColor Cyan
Write-Host ""

$backups = Get-ChildItem C:\Users\W10\.claude\.credentials*.json

foreach ($backup in $backups) {
    try {
        $content = Get-Content $backup.FullName | ConvertFrom-Json
        $exp = [DateTimeOffset]::FromUnixTimeMilliseconds($content.claudeAiOauth.expiresAt)
        $now = Get-Date
        $isExpired = $exp -lt $now

        $status = if ($isExpired) { "EXPIRED" } else { "VALID" }
        $color = if ($isExpired) { "Red" } else { "Green" }

        Write-Host "$($backup.Name):" -ForegroundColor White
        Write-Host "  Expires: $($exp.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        Write-Host "  Status: $status" -ForegroundColor $color
        Write-Host "  Subscription: $($content.claudeAiOauth.subscriptionType)" -ForegroundColor Gray
        Write-Host ""
    } catch {
        Write-Host "$($backup.Name): ERROR reading" -ForegroundColor Red
        Write-Host ""
    }
}
