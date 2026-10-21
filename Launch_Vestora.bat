@echo off
title Vestora Smart Wardrobe Launcher
echo Starting Vestora Smart Wardrobe...

netstat -ano | findstr :8080 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    echo Starting background server on port 8080...
    start /b python "c:\Users\Admin\Documents\NewProject\mobile_app\run_server.py"
    timeout /t 2 /nobreak >nul
)

if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --app="http://127.0.0.1:8080" --window-size=430,920
) else (
    start "" "http://127.0.0.1:8080"
)
exit
