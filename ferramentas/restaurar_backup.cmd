@echo off
rem Atalho: executa restaurar_backup.ps1 e grava o log em logs\restaurar_backup.txt
cd /d "%~dp0.."
if not exist "logs" mkdir "logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0..\logs\restaurar_backup.txt' -Force | Out-Null; & '%~dp0restaurar_backup.ps1'; Stop-Transcript | Out-Null"
echo.
pause
