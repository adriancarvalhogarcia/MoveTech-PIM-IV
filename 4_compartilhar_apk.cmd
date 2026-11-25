@echo off
rem Atalho: executa 4_compartilhar_apk.ps1 e grava o log em logs\4_compartilhar.txt
rem Precisa de administrador: botao direito no arquivo > Executar como administrador.
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0logs\4_compartilhar.txt' -Force | Out-Null; & '%~dp04_compartilhar_apk.ps1'; Stop-Transcript | Out-Null"
echo.
echo Fim. Log salvo em logs\4_compartilhar.txt
pause
