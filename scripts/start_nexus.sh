#!/usr/bin/env bash
# RehabBridge NEXUS / H10 - One-Click Start Script (Linux/macOS)
set -e

echo "=========================================================="
echo "  RehabBridge NEXUS / H10 - Innovation 2K26 Unified System"
echo "=========================================================="

python3 -c "
import sys
from backend.database import SessionLocal
from backend.preflight import run_preflight_checks
with SessionLocal() as db:
    res = run_preflight_checks(db)
print(f'Overall Status: {res[\"overall_status\"]} | Ready: {res[\"ready_to_start\"]}')
"

echo "Starting Local Backend Server on http://127.0.0.1:8000..."
uvicorn backend.main:app --host 127.0.0.1 --port 8000 --log-level info

