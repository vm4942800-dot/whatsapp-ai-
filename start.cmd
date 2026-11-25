@echo off
rem Starts the WhatsApp Message Scheduler dev server.
rem Uses the Node.js runtime provisioned via pip (nodejs-wheel-binaries),
rem falling back to system Node if present.
setlocal
set "WHEEL=%APPDATA%\Python\Python314\site-packages\nodejs_wheel"
set "NODE_EXE=%WHEEL%\node.exe"
set "NPM_CLI=%WHEEL%\lib\node_modules\npm\bin\npm-cli.js"

if exist "%NODE_EXE%" (
  for %%D in ("%NODE_EXE%") do set "PATH=%%~dpD;%PATH%"
  "%NODE_EXE%" "%NPM_CLI%" run dev -- --port 3000
) else (
  npm run dev -- --port 3000
)
