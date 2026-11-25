@echo off
rem Redefine a senha do root do MySQL. Pede permissao de administrador.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
if not exist "%~dp0logs" mkdir "%~dp0logs"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0redefinir_senha_mysql.ps1"
echo.
pause
