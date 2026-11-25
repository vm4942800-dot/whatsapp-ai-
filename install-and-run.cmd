@echo off
setlocal EnableExtensions
title Nudge - one-click launcher
cd /d "%~dp0"
set "NEXT_TELEMETRY_DISABLED=1"

rem Keep app data (WhatsApp sessions, uploads) OUT of OneDrive —
rem sync placeholders and file locks break sessions and builds.
set "NUDGE_DATA_DIR=%LOCALAPPDATA%\Nudge\data"
if not exist "%NUDGE_DATA_DIR%" mkdir "%NUDGE_DATA_DIR%"

echo ====================================================
echo   Nudge - one-click installer and launcher
echo   Installs Node.js if missing, then starts the app
echo ====================================================
echo.

rem ----------------------------------------------------
rem 0. If Nudge is already running, just open the app
rem ----------------------------------------------------
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul 2>nul
if not errorlevel 1 (
  echo Nudge already seems to be running. Opening it in your browser...
  start "" http://localhost:3000
  cmd /c ping -n 4 127.0.0.1 >nul
  exit /b 0
)

set "USE_SYSTEM_NPM=0"
set "NODE_EXE="
set "NPM_CLI="

rem ----------------------------------------------------
rem 1. Is Node.js already installed on this PC?
rem ----------------------------------------------------
where node >nul 2>nul && where npm >nul 2>nul && set "USE_SYSTEM_NPM=1"

rem ----------------------------------------------------
rem 2. Node.js provisioned by pip (nodejs-wheel-binaries)?
rem ----------------------------------------------------
if "%USE_SYSTEM_NPM%"=="0" call :find_wheel_node

rem ----------------------------------------------------
rem 3. Portable Node.js downloaded by this script before?
rem ----------------------------------------------------
if "%USE_SYSTEM_NPM%"=="0" if not defined NODE_EXE call :find_portable_node

rem ----------------------------------------------------
rem 4. Last resort: download portable Node.js (no admin needed)
rem ----------------------------------------------------
if "%USE_SYSTEM_NPM%"=="0" if not defined NODE_EXE call :download_node

if "%USE_SYSTEM_NPM%"=="0" if not defined NODE_EXE (
  echo.
  echo ERROR: Could not find or install Node.js.
  echo        - Check your internet connection and try again, or
  echo        - install Node.js manually from https://nodejs.org
  echo.
  pause
  exit /b 1
)

echo.
if "%USE_SYSTEM_NPM%"=="1" (
  echo [ok] Using the Node.js already installed on this PC:
) else (
  rem Put the Node folder on PATH so npm run-scripts can spawn "node"
  for %%D in ("%NODE_EXE%") do set "PATH=%%~dpD;%PATH%"
  echo [ok] Using Node.js at:
  echo      %NODE_EXE%
)
echo.

rem ----------------------------------------------------
rem 5. Install project dependencies on first run
rem ----------------------------------------------------
if exist "node_modules\next\package.json" (
  echo [1/2] Dependencies already installed - skipping npm install.
) else (
  echo [1/2] Installing dependencies - first run only, may take a few minutes.
  echo       ^(This also downloads the browser engine used by WhatsApp Web^)
  echo.
  if "%USE_SYSTEM_NPM%"=="1" (
    call npm install
  ) else (
    "%NODE_EXE%" "%NPM_CLI%" install
  )
  if errorlevel 1 (
    echo.
    echo ERROR: npm install failed. Read the messages above for the cause.
    pause
    exit /b 1
  )
)

rem ----------------------------------------------------
rem 6. Open the app in the browser once the server is up
rem ----------------------------------------------------
if not defined NUDGE_NO_BROWSER (
  start "" /min powershell -NoProfile -Command "Start-Sleep -Seconds 8; Start-Process 'http://localhost:3000'"
)

rem ----------------------------------------------------
rem 7. Start Nudge
rem ----------------------------------------------------
echo.
echo [2/2] Starting Nudge on http://localhost:3000
echo       Keep this window OPEN while you use Nudge.
echo       To stop: click the window and press Ctrl+C.
echo.
if "%USE_SYSTEM_NPM%"=="1" (
  if exist ".next\BUILD_ID" (
    echo       Running the production server.
    call npm run start -- -p 3000
  ) else (
    call npm run dev -- --port 3000
  )
) else (
  if exist ".next\BUILD_ID" (
    echo       Running the production server.
    "%NODE_EXE%" "node_modules\next\dist\bin\next" start -p 3000
  ) else (
    "%NODE_EXE%" "%NPM_CLI%" run dev -- --port 3000
  )
)

echo.
echo Nudge has stopped.
pause
exit /b 0

rem ==================== subroutines ====================

:find_wheel_node
for %%V in (Python314 Python313 Python312) do (
  if not defined NODE_EXE if exist "%APPDATA%\Python\%%V\site-packages\nodejs_wheel\node.exe" if exist "%APPDATA%\Python\%%V\site-packages\nodejs_wheel\lib\node_modules\npm\bin\npm-cli.js" (
    set "NODE_EXE=%APPDATA%\Python\%%V\site-packages\nodejs_wheel\node.exe"
    set "NPM_CLI=%APPDATA%\Python\%%V\site-packages\nodejs_wheel\lib\node_modules\npm\bin\npm-cli.js"
  )
)
goto :eof

:find_portable_node
set "NODE_BASE=%LOCALAPPDATA%\Nudge\node"
set "NODE_HOME="
if exist "%NODE_BASE%\current.txt" set /p NODE_HOME=<"%NODE_BASE%\current.txt"
if not defined NODE_HOME for /d %%D in ("%NODE_BASE%\node-v*") do set "NODE_HOME=%%D"
if defined NODE_HOME if exist "%NODE_HOME%\node.exe" if exist "%NODE_HOME%\node_modules\npm\bin\npm-cli.js" (
  set "NODE_EXE=%NODE_HOME%\node.exe"
  set "NPM_CLI=%NODE_HOME%\node_modules\npm\bin\npm-cli.js"
)
goto :eof

:download_node
set "NODE_BASE=%LOCALAPPDATA%\Nudge\node"
if not exist "%NODE_BASE%" mkdir "%NODE_BASE%"
echo Node.js was not found on this PC.
echo Downloading a portable copy of Node.js 24 to:
echo   %NODE_BASE%
echo ^(No admin rights needed. About 30 MB, one time only.^)
echo.

set "ZIP_NAME="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$c=(Invoke-WebRequest -UseBasicParsing 'https://nodejs.org/dist/latest-v24.x/').Content; if($c -match 'node-v[0-9.]+-win-x64\.zip'){$Matches[0]}"`) do set "ZIP_NAME=%%A"
if not defined ZIP_NAME set "ZIP_NAME=node-v24.21.0-win-x64.zip"

set "ZIP_FILE=%NODE_BASE%\%ZIP_NAME%"
if not exist "%ZIP_FILE%" (
  echo Downloading %ZIP_NAME% ...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri 'https://nodejs.org/dist/latest-v24.x/%ZIP_NAME%' -OutFile '%ZIP_FILE%'"
  if errorlevel 1 (
    echo.
    echo ERROR: Download failed. Check the internet connection and try again.
    goto :eof
  )
)

echo Extracting...
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP_FILE%' -DestinationPath '%NODE_BASE%' -Force" >nul 2>nul
if errorlevel 1 tar -xf "%ZIP_FILE%" -C "%NODE_BASE%"

set "NODE_HOME=%NODE_BASE%\%ZIP_NAME:~0,-4%"
if not exist "%NODE_HOME%\node.exe" (
  echo.
  echo ERROR: Could not extract Node.js. Try again, or install Node.js from https://nodejs.org
  goto :eof
)
> "%NODE_BASE%\current.txt" echo %NODE_HOME%
set "NODE_EXE=%NODE_HOME%\node.exe"
set "NPM_CLI=%NODE_HOME%\node_modules\npm\bin\npm-cli.js"
echo Node.js ready: %NODE_HOME%
echo.
goto :eof
