# Brza provjera statusa
$c = Get-Content "$env:USERPROFILE\.claude\.credentials.json" | ConvertFrom-Json
$e = [DateTimeOffset]::FromUnixTimeMilliseconds($c.claudeAiOauth.expiresAt).ToLocalTime()
Write-Host "Token: $($e.ToString('HH:mm')) | $($c.claudeAiOauth.subscriptionType)" -F Green

Write-Host "`nTask Log (last 5 lines):" -F Yellow
Get-Content "$env:USERPROFILE\.claude\token-monitor.log" -Tail 5 -ErrorAction SilentlyContinue

Write-Host "`nScheduled Task Info:" -F Yellow
Get-ScheduledTask -TaskName "ClaudeTokenMonitor" | Get-ScheduledTaskInfo
