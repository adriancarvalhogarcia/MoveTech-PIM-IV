@echo off
rem Atalho: executa backup_banco.ps1 e grava o log em logs\backup_banco.txt
cd /d "%~dp0.."
if not exist "logs" mkdir "logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0..\logs\backup_banco.txt' -Force | Out-Null; & '%~dp0backup_banco.ps1'; Stop-Transcript | Out-Null"
echo.
pause
