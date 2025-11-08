# Extract Desktop tokens from Windows Credential Manager

Write-Host "Extracting Claude Desktop tokens from Windows Credential Manager..." -ForegroundColor Cyan
Write-Host ""

# Function to get credential from Windows Credential Manager
Add-Type -AssemblyName System.Security

function Get-StoredCredential {
    param([string]$Target)

    try {
        # Use cmdkey to check if credential exists
        $list = cmdkey /list 2>&1 | Out-String

        if ($list -match $Target) {
            Write-Host "✓ Found: $Target" -ForegroundColor Green

            # Try to read using PowerShell Credential Manager
            # This is a simplified approach - we'll need to construct the credential object

            # For now, let's try a different approach using the existing .credentials.json structure
            return $true
        } else {
            Write-Host "✗ Not found: $Target" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Error reading $Target : $_" -ForegroundColor Red
        return $false
    }
}

# Check if tokens exist
$hasAccessToken = Get-StoredCredential "Claude_AccessToken"
$hasRefreshToken = Get-StoredCredential "Claude_RefreshToken"

Write-Host ""

if ($hasAccessToken -and $hasRefreshToken) {
    Write-Host "✓ Desktop tokens found in Credential Manager!" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROBLEM: PowerShell ne može direktno pročitati DPAPI enkriptovane credentials." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "RJEŠENJE:" -ForegroundColor Cyan
    Write-Host "  1. Desktop app automatski koristi ove tokene" -ForegroundColor White
    Write-Host "  2. Možemo pokušati triggerovati Desktop da SYNCHRONIZUJE credentials" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternativa: Probaj zatvoriti SVE Claude instance i pokrenuti Desktop PA ONDA CLI" -ForegroundColor Yellow
} else {
    Write-Host "✗ Desktop tokens not found!" -ForegroundColor Red
}
