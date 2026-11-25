@echo off
rem Abre o sistema web do PIM III em http://localhost:5500 (deixe esta janela aberta)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp06_iniciar_web.ps1"
pause
