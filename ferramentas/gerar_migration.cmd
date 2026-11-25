@echo off
rem Gera a migration do EF e o script SQL completo. Log em logs\migration.txt
cd /d "%~dp0.."
if not exist "logs" mkdir "logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0..\logs\migration.txt' -Force | Out-Null; & '%~dp0gerar_migration.ps1'; Stop-Transcript | Out-Null"
echo.
echo Fim. Log salvo em logs\migration.txt
pause
