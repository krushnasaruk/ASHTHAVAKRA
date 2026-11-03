# RehabBridge NEXUS / H10 - Stop Script
Write-Host "Stopping any running uvicorn servers on port 8000..." -ForegroundColor Yellow
$proc = Get-Process -Name "python", "uvicorn" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -match "backend.main:app" -or $_.CommandLine -match "8000"
}
if ($proc) {
    $proc | Stop-Process -Force
    Write-Host "Processes stopped." -ForegroundColor Green
} else {
    Write-Host "No active NEXUS server processes found." -ForegroundColor DarkGray
}

