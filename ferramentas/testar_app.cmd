@echo off
rem Atalho: executa testar_app.ps1 e grava o log em logs\testar_app.txt
cd /d "%~dp0.."
if not exist "logs" mkdir "logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0..\logs\testar_app.txt' -Force | Out-Null; & '%~dp0testar_app.ps1'; Stop-Transcript | Out-Null"
echo.
pause
