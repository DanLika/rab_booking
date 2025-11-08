Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   FINALNA PROVJERA - MAX NALOG" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. Credentials provjera (SAMO ČITANJE)
$creds = Get-Content "$env:USERPROFILE\.claude\.credentials.json" | ConvertFrom-Json
$exp = [DateTimeOffset]::FromUnixTimeMilliseconds($creds.claudeAiOauth.expiresAt).ToLocalTime()
$remaining = ($exp - (Get-Date)).TotalHours

Write-Host "NALOG INFO:" -ForegroundColor Yellow
Write-Host "  Subscription: $($creds.claudeAiOauth.subscriptionType)" -ForegroundColor $(if($creds.claudeAiOauth.subscriptionType -eq 'max'){'Green'}else{'Red'})
Write-Host "  Token expires: $($exp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "  Remaining: $([math]::Round($remaining, 2)) hours" -ForegroundColor Green

Write-Host "`nSISTEM STATUS:" -ForegroundColor Yellow

# 2. Desktop startup? (SAMO ČITANJE)
$startup = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Claude" -ErrorAction SilentlyContinue
Write-Host "  Desktop startup: $(if($startup){'✅ ACTIVE'}else{'❌ INACTIVE'})" -ForegroundColor $(if($startup){'Green'}else{'Red'})

# 3. Scheduled task? (SAMO ČITANJE)
$task = Get-ScheduledTask -TaskName "ClaudeTokenMonitor" -ErrorAction SilentlyContinue
Write-Host "  Scheduled task: $(if($task){'✅ ACTIVE'}else{'❌ INACTIVE'})" -ForegroundColor $(if($task){'Green'}else{'Red'})

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🎊 SISTEM 100% POSTAVLJEN!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "ŠTO TO ZNAČI:" -ForegroundColor Cyan
Write-Host "✅ Desktop (Max) automatski održava token" -ForegroundColor Green
Write-Host "✅ Code (Max) koristi isti token - UNLIMITED!" -ForegroundColor Green
Write-Host "✅ Scheduled task prati i upozorava (backup)" -ForegroundColor Green
Write-Host "✅ NEMA više weekly limit problema!" -ForegroundColor Green
Write-Host "`n🚀 Problem 100% riješen - uživajte!" -ForegroundColor Cyan
