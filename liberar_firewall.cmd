@echo off
rem Libera no firewall do Windows as portas da API (5071) e do download do APK (8080).
rem Pede permissao de administrador uma unica vez.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
netsh advfirewall firewall delete rule name="MoveTech API" >nul 2>&1
netsh advfirewall firewall add rule name="MoveTech API" dir=in action=allow protocol=TCP localport=5071
netsh advfirewall firewall delete rule name="MoveTech APK" >nul 2>&1
netsh advfirewall firewall add rule name="MoveTech APK" dir=in action=allow protocol=TCP localport=8080
echo.
echo Portas 5071 (API) e 8080 (download do APK) liberadas no firewall.
pause
