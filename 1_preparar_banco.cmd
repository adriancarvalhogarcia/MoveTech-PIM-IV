@echo off
rem Atalho: executa 1_preparar_banco.ps1 e grava o log em logs\1_banco.txt
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0logs\1_banco.txt' -Force | Out-Null; & '%~dp01_preparar_banco.ps1'; Stop-Transcript | Out-Null"
echo.
echo Fim. Log salvo em logs\1_banco.txt
pause
