@echo off
setlocal EnableExtensions
title Nudge - public link
cd /d "%~dp0"

echo ====================================================
echo   Nudge - restore public link
echo   Starts the app if needed, then opens a tunnel
echo ====================================================
echo.

rem ---- 1. Start the app if it is not running ----
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul 2>nul
if errorlevel 1 (
  echo Starting Nudge in a separate window...
  set "NUDGE_NO_BROWSER=1"
  start "Nudge server" /min cmd /c ".\install-and-run.cmd"
)

rem ---- 2. Wait for the app to come up ----
set /a TRIES=0
:wait_server
set /a TRIES+=1
if %TRIES% gtr 30 (
  echo ERROR: Nudge did not start within 60 seconds. Check the "Nudge server" window.
  pause
  exit /b 1
)
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul 2>nul
if errorlevel 1 (
  cmd /c ping -n 3 127.0.0.1 >nul
  goto wait_server
)
echo [ok] Nudge is running on http://localhost:3000

rem ---- 3. Fresh tunnel every time (old ones go stale) ----
if not exist ".data\bin\cloudflared.exe" (
  echo ERROR: .data\bin\cloudflared.exe not found - cannot create a public link.
  echo        Nudge is still available locally at http://localhost:3000
  pause
  exit /b 1
)
taskkill /IM cloudflared.exe /F >nul 2>nul
cmd /c ping -n 2 127.0.0.1 >nul
if not exist ".data\logs" mkdir ".data\logs"
echo Creating a fresh public link...
start "Nudge tunnel" /min cmd /c ".data\bin\cloudflared.exe tunnel --url http://localhost:3000 --no-autoupdate > .data\logs\tunnel.log 2>&1"

rem ---- 4. Wait for the URL and show it ----
set "URL="
set /a TRIES=0
:wait_url
set /a TRIES+=1
if %TRIES% gtr 20 (
  echo ERROR: No public link after 40 seconds. Check your internet connection,
  echo        or look at .data\logs\tunnel.log for details.
  pause
  exit /b 1
)
cmd /c ping -n 3 127.0.0.1 >nul
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$m = Select-String -Path '.data\logs\tunnel.log' -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -First 1; if($m){$m.Matches[0].Value}"`) do set "URL=%%A"
if not defined URL goto wait_url

echo.
echo ====================================================
echo   PUBLIC LINK (share this):
echo.
echo   %URL%
echo.
echo   PIN: the NUDGE_PIN value (default 1234)
echo ====================================================
echo.
echo %URL%| clip
echo The link was copied to your clipboard. Opening it now...
echo Keep the two minimized windows (server + tunnel) open while sharing.
cmd /c ping -n 4 127.0.0.1 >nul
start "" "%URL%"
exit /b 0
