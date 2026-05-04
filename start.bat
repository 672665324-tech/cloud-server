@echo off
setlocal EnableExtensions

title ISLA LABS

echo ==============================
echo   ISLA LABS
echo ==============================
echo.

if "%CLOUDFLARED_TOKEN%"=="" (
  echo [ERROR] CLOUDFLARED_TOKEN not set
  echo   Run: set CLOUDFLARED_TOKEN=your_token_here
  pause
  exit /b 1
)

cd /D "D:\claude-output\cloud-server"

if not exist "server.js" (
  echo [ERROR] Missing server.js
  pause
  exit /b 1
)

echo Starting server...
start /B node.exe server.js

timeout /t 2 /nobreak >nul

echo Starting tunnel...
start /B cloudflared.exe tunnel run --token %CLOUDFLARED_TOKEN%

timeout /t 3 /nobreak >nul

echo.
echo   Local:  http://127.0.0.1:3000
echo   Public: https://isla9999.com
echo.
echo   Opening browser...
start "" "https://isla9999.com"
echo.
echo   Press any key to stop all services...
pause >nul

echo Stopping...
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM cloudflared.exe >nul 2>&1
echo Done.
timeout /t 2 /nobreak >nul
