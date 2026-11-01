@echo off
echo ========================================================
echo   Setting up Ashtavakra UI Workspace for Vaishnavi Jare
echo   GitHub Handle: vaishnavijare60-hash
echo ========================================================
echo.

cd /d "%~dp0..\..\mobile"
echo [1/3] Installing Flutter dependencies...
call flutter pub get

echo.
echo [2/3] Running layout and widget tests...
call flutter test

echo.
echo [3/3] Launching live Web UI with Instant Hot-Reload in Chrome...
call flutter run -d chrome

pause
