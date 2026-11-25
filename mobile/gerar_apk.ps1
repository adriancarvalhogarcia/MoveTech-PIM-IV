# ------------------------------------------------------------------
# MoveTech Mobile - gera o APK para instalar no celular Android
#
# Uso (dentro da pasta do projeto):
#   powershell -ExecutionPolicy Bypass -File .\gerar_apk.ps1
#
# Opcional: informar o IP do computador que roda a API
#   powershell -ExecutionPolicy Bypass -File .\gerar_apk.ps1 -Ip 192.168.0.15
#
# O APK sai na raiz do projeto com o nome MoveTech.apk e ja abre
# apontando para http://<IP>:5071/api. O endereco tambem pode ser
# trocado dentro do app, na engrenagem da tela de login.
# ------------------------------------------------------------------

param(
    [string]$Ip = "",
    [int]$Porta = 5071
)

# Localiza o Flutter mesmo que a pasta dele nao esteja no PATH
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    foreach ($pastaFlutter in @("$env:USERPROFILE\srcflutter\bin", "C:\src\flutter\bin", "$env:USERPROFILE\flutter\bin", "$env:USERPROFILE\src\flutter\bin", "C:\flutter\bin")) {
        if (Test-Path (Join-Path $pastaFlutter "flutter.bat")) {
            $env:Path = "$pastaFlutter;$env:Path"
            break
        }
    }
}

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# 1. Garante que o projeto esta configurado
if (-not (Test-Path "android\app\src\main\AndroidManifest.xml")) {
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "configurar.ps1")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

# 2. Descobre o IP do computador na rede local
if ([string]::IsNullOrWhiteSpace($Ip)) {
    try {
        $Ip = (Get-NetIPConfiguration |
            Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq "Up" } |
            Select-Object -First 1).IPv4Address.IPAddress
    } catch {
        $Ip = ""
    }
}
if ([string]::IsNullOrWhiteSpace($Ip)) {
    Write-Host "Nao consegui descobrir o IP automaticamente." -ForegroundColor Yellow
    Write-Host "Rode 'ipconfig', veja o 'Endereco IPv4' e execute:"
    Write-Host "  .\gerar_apk.ps1 -Ip 192.168.0.15"
    exit 1
}

$url = "http://${Ip}:${Porta}/api"
Write-Host "Gerando APK apontando para $url ..." -ForegroundColor Green

# 3. Compila
flutter build apk --release "--dart-define=API_URL=$url"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 4. Copia para a raiz com um nome facil
$origem = "build\app\outputs\flutter-apk\app-release.apk"
Copy-Item $origem "MoveTech.apk" -Force

Write-Host ""
Write-Host "APK gerado: $PSScriptRoot\MoveTech.apk" -ForegroundColor Green
Write-Host "Servidor configurado no app: $url"
Write-Host ""
Write-Host "Proximos passos:"
Write-Host "  1. Suba a API:              ..\2_iniciar_api.ps1"
Write-Host "  2. Envie o APK ao celular:  ..\4_compartilhar_apk.ps1 (ou cabo USB / WhatsApp)"
Write-Host "  3. Celular e computador precisam estar no mesmo Wi-Fi."
