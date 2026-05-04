@echo off
setlocal EnableExtensions

title ISLA LABS

echo ==============================
echo   ISLA LABS
echo ==============================
echo.

cd /D "D:\claude-output\cloud-server"

if not exist "server.js" (
  echo [ERROR] Missing server.js
  pause
  exit /b 1
)

echo Starting server...
start /B node.exe server.js
timeout /t 2 /nobreak >nul

set HAS_TUNNEL=0
if not "%CLOUDFLARED_TOKEN%"=="" (
  echo Starting tunnel...
  start /B cloudflared.exe tunnel run --token %CLOUDFLARED_TOKEN%
  set HAS_TUNNEL=1
  timeout /t 3 /nobreak >nul
) else (
  echo [INFO] No CLOUDFLARED_TOKEN, running local only
)

echo.
echo   Local:  http://127.0.0.1:3000
if "%HAS_TUNNEL%"=="1" echo   Public: https://isla9999.com
echo.
start "" "http://127.0.0.1:3000"
echo.
echo   Press any key to stop all services...
pause >nul

echo Stopping...
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM cloudflared.exe >nul 2>&1
echo Done.
timeout /t 2 /nobreak >nul
