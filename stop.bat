@echo off
cd /d "%~dp0"

echo Enviando STOP al servidor...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\rcon-stop.ps1"

echo.
pause
