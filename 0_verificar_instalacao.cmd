@echo off
rem Atalho: executa 0_verificar_instalacao.ps1 e grava o log em logs\0_verificar.txt
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0logs\0_verificar.txt' -Force | Out-Null; & '%~dp00_verificar_instalacao.ps1'; Stop-Transcript | Out-Null"
echo.
echo Fim. Log salvo em logs\0_verificar.txt
pause
