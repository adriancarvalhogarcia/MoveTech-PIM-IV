@echo off
rem Atalho: executa 2_iniciar_api.ps1 e grava o log em logs\2_api.txt
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0logs\2_api.txt' -Force | Out-Null; & '%~dp02_iniciar_api.ps1'; Stop-Transcript | Out-Null"
echo.
echo Fim. Log salvo em logs\2_api.txt
pause
