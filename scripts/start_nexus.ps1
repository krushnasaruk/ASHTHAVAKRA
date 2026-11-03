# RehabBridge NEXUS / H10 - One-Click Start Script (Windows PowerShell)
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  RehabBridge NEXUS / H10 - Innovation 2K26 Unified System" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check Python
$pyVer = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
Write-Host "[1/3] Python Environment: Python $pyVer" -ForegroundColor Green

# 2. Run Preflight
Write-Host "[2/3] Running System Preflight Diagnostic..." -ForegroundColor Yellow
python -c "
import sys
from backend.database import SessionLocal
from backend.preflight import run_preflight_checks
with SessionLocal() as db:
    res = run_preflight_checks(db)
print(f'Overall Status: {res[\"overall_status\"]} | Ready: {res[\"ready_to_start\"]}')
for c in res['checks']:
    print(f'  - [{c[\"status\"].upper()}] {c[\"name\"]}: {c[\"details\"]}')
"

# 3. Start Server
Write-Host "[3/3] Starting Local Backend Server on http://127.0.0.1:8000..." -ForegroundColor Green
Write-Host "Press Ctrl+C to terminate." -ForegroundColor DarkGray
uvicorn backend.main:app --host 127.0.0.1 --port 8000 --log-level info
