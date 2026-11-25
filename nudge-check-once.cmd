@echo off
setlocal EnableExtensions
rem ============================================================
rem  Nudge single-cycle health check - runs ONE check and exits.
rem  Invoked every 5 minutes by Task Scheduler (NudgeAlwaysOn-5min)
rem  and once at logon via the Startup folder shortcut.
rem  Long-lived watchdog loops kept getting killed; this design has
rem  nothing to kill: Task Scheduler itself does the looping.
rem ============================================================
cd /d "%~dp0"
set "NUDGE_DATA_DIR=%LOCALAPPDATA%\Nudge\data"
if not exist "%NUDGE_DATA_DIR%" mkdir "%NUDGE_DATA_DIR%"
set "URLFILE=%USERPROFILE%\Desktop\Nudge-URL.txt"
set "LOCKFILE=%LOCALAPPDATA%\Nudge\watchdog.lock"

rem ---- skip if another cycle ran less than 4 minutes ago ----
rem (powershell exits 1 when the lock is fresh => skip; 0 => run)
if exist "%LOCKFILE%" (
  powershell -NoProfile -Command "exit [int](((Get-Date) - (Get-Item -LiteralPath '%LOCKFILE%').LastWriteTime).TotalMinutes -lt 4)"
  if errorlevel 1 exit /b 0
)
echo %date% %time% > "%LOCKFILE%"

rem ---------- 1. keep the app alive ----------
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul 2>nul
if not errorlevel 1 goto server_ok

echo [%date% %time%] Nudge not running - starting...
set "NUDGE_NO_BROWSER=1"
start "" /min cmd /c "\"%~dp0install-and-run.cmd\""
set /a TRIES=0

:wait_server
cmd /c ping -n 6 127.0.0.1 >nul
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul 2>nul
if not errorlevel 1 goto server_ok
set /a TRIES+=1
if %TRIES% lss 18 goto wait_server
echo [%date% %time%] WARNING: Nudge failed to start - retry next cycle.
echo %date% %time% > "%LOCKFILE%"
exit /b 1

:server_ok

rem ---------- 2. keep the public link alive ----------
set "URL="
if exist ".data\logs\tunnel.log" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$m = Select-String -Path '.data\logs\tunnel.log' -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -Last 1; if($m){$m.Matches[0].Value}"`) do set "URL=%%A"
if not defined URL goto tunnel_dead

rem external liveness probe: a 530/timeout means the URL is a zombie
curl.exe -s -o nul --max-time 12 "%URL%/api/gate"
if errorlevel 1 goto tunnel_dead

echo [%date% %time%] ok - %URL%
>"%URLFILE%" echo %URL%
rem keep the landing page (index.html + config.json) pointing at the live URL
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0landing-sync.ps1" -Url "%URL%" >nul 2>nul
echo %date% %time% > "%LOCKFILE%"
exit /b 0

rem ---------- 3. fresh tunnel when dead/stale ----------
:tunnel_dead
echo [%date% %time%] tunnel dead or stale - creating a fresh public link...
taskkill /IM cloudflared.exe /F >nul 2>nul
cmd /c ping -n 3 127.0.0.1 >nul
start "" /min cmd /c ".data\bin\cloudflared.exe tunnel --url http://localhost:3000 --no-autoupdate > .data\logs\tunnel.log 2>&1"
set /a TRIES=0

:wait_url
cmd /c ping -n 5 127.0.0.1 >nul
set "URL="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$m = Select-String -Path '.data\logs\tunnel.log' -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -Last 1; if($m){$m.Matches[0].Value}"`) do set "URL=%%A"
if defined URL goto tunnel_up
set /a TRIES+=1
if %TRIES% lss 12 goto wait_url
echo [%date% %time%] WARNING: no public link this cycle - will retry.
echo %date% %time% > "%LOCKFILE%"
exit /b 1

:tunnel_up
echo [%date% %time%] public link: %URL%
>"%URLFILE%" echo %URL%
rem keep the landing page (index.html + config.json) pointing at the live URL
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0landing-sync.ps1" -Url "%URL%" >nul 2>nul
echo %date% %time% > "%LOCKFILE%"
exit /b 0
