@echo off
rem Atalho: executa testar_banco_limpo.ps1 e grava o log em logs\testar_banco_limpo.txt
cd /d "%~dp0.."
if not exist "logs" mkdir "logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0..\logs\testar_banco_limpo.txt' -Force | Out-Null; & '%~dp0testar_banco_limpo.ps1'; Stop-Transcript | Out-Null"
echo.
pause
