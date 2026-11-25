@echo off
rem Atalho: executa 5_rodar_no_emulador.ps1 e grava o log em logs\5_emulador.txt
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0logs\5_emulador.txt' -Force | Out-Null; & '%~dp05_rodar_no_emulador.ps1'; Stop-Transcript | Out-Null"
echo.
echo Fim. Log salvo em logs\5_emulador.txt
pause
