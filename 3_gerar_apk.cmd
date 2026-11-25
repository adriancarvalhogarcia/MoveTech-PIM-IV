@echo off
rem Atalho: executa 3_gerar_apk.ps1 e grava o log em logs\3_apk.txt
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0logs\3_apk.txt' -Force | Out-Null; & '%~dp03_gerar_apk.ps1'; Stop-Transcript | Out-Null"
echo.
echo Fim. Log salvo em logs\3_apk.txt
pause
