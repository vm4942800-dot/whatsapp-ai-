@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Nudge - always on
cd /d "%~dp0"

echo.
echo  ============================================================
echo    Nudge watchdog - keeps your public link alive
echo.
echo    Minimize this window and LEAVE IT RUNNING.
echo    It checks every minute and auto-restarts:
echo      - the Nudge app (if it stops responding)
echo      - the public link (if the tunnel goes stale)
echo    Your current link is always saved to:
echo      Desktop\Nudge-URL.txt
echo  ============================================================
echo.

set "URLFILE=%USERPROFILE%\Desktop\Nudge-URL.txt"
set "FAILS=0"
set "LOCKFILE=%LOCALAPPDATA%\Nudge\watchdog.lock"

rem ---- single-instance guard: exit if another watchdog woke up recently ----
rem (powershell exits 1 when the lock is fresh => exit; 0 => continue)
if exist "%LOCKFILE%" (
  powershell -NoProfile -Command "exit [int](((Get-Date) - (Get-Item -LiteralPath '%LOCKFILE%').LastWriteTime).TotalMinutes -lt 3)"
  if errorlevel 1 exit /b 0
)
:lock_ok
echo %date% %time% > "%LOCKFILE%"

rem Same data-home rule as the launcher: keep WhatsApp sessions out of OneDrive.
set "NUDGE_DATA_DIR=%LOCALAPPDATA%\Nudge\data"
if not exist "%NUDGE_DATA_DIR%" mkdir "%NUDGE_DATA_DIR%"

:cycle
rem ---------- 1. keep the app alive ----------
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul 2>nul
if not errorlevel 1 goto server_ok

echo [%time%] Nudge is not running - starting it...
set "NUDGE_NO_BROWSER=1"
start "Nudge server" /min cmd /c ""%~dp0install-and-run.cmd""
set /a TRIES=0

:wait_server
rem ping-based delay works even in non-interactive (Task Scheduler) consoles
cmd /c ping -n 6 127.0.0.1 >nul
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul 2>nul
if not errorlevel 1 goto server_ok
set /a TRIES+=1
if %TRIES% lss 18 goto wait_server
echo [%time%] WARNING: Nudge failed to start - will retry next cycle.
goto sleep

:server_ok
echo [%time%] app: ok

rem ---------- 2. keep the public link alive ----------
tasklist | findstr /i "cloudflared.exe" >nul 2>nul
if errorlevel 1 goto tunnel_dead

set "URL="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$m = Select-String -Path '.data\logs\tunnel.log' -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -Last 1; if($m){$m.Matches[0].Value}"`) do set "URL=%%A"
if not defined URL goto tunnel_dead

curl.exe -s -o nul --max-time 12 "%URL%/api/gate"
if errorlevel 1 (
  set /a FAILS+=1
  echo [%time%] link check failed !FAILS!/2 - %URL%
  if !FAILS! geq 2 goto tunnel_dead
  goto sleep
)

set "FAILS=0"
echo [%time%] link: ok - %URL%
>"%URLFILE%" echo %URL%
goto sleep

rem ---------- 3. fresh tunnel when dead/stale ----------
:tunnel_dead
echo [%time%] tunnel dead or stale - creating a fresh public link...
set "FAILS=0"
taskkill /IM cloudflared.exe /F >nul 2>nul
cmd /c ping -n 3 127.0.0.1 >nul
start "Nudge tunnel" /min cmd /c ".data\bin\cloudflared.exe tunnel --url http://localhost:3000 --no-autoupdate > .data\logs\tunnel.log 2>&1"
set /a TRIES=0

:wait_url
cmd /c ping -n 5 127.0.0.1 >nul
set "URL="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$m = Select-String -Path '.data\logs\tunnel.log' -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -Last 1; if($m){$m.Matches[0].Value}"`) do set "URL=%%A"
if defined URL goto tunnel_up
set /a TRIES+=1
if %TRIES% lss 15 goto wait_url
echo [%time%] WARNING: no public link this cycle - will retry.
goto sleep

:tunnel_up
echo [%time%] public link: %URL%
>"%URLFILE%" echo %URL%
echo [%time%] link saved to %URLFILE%

:sleep
echo %date% %time% > "%LOCKFILE%"
cmd /c ping -n 61 127.0.0.1 >nul
goto cycle
