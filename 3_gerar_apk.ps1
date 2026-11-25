# ------------------------------------------------------------------
# MoveTech - gera o APK do aplicativo para instalar no celular Android
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\3_gerar_apk.ps1
#
# Opcional, se o IP detectado estiver errado:
#       powershell -ExecutionPolicy Bypass -File .\3_gerar_apk.ps1 -Ip 192.168.0.15
#
# Resultado: o arquivo MoveTech.apk nesta pasta, ja configurado para
# acessar a API em http://<IP-deste-computador>:5071/api.
# A primeira vez demora de 5 a 15 minutos (o Gradle baixa muita coisa).
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
$raiz = $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "O Flutter nao esta instalado ou nao esta no PATH (README, passo 1.4)." -ForegroundColor Red
    exit 1
}

& (Join-Path $raiz "mobile\gerar_apk.ps1") -Ip $Ip -Porta $Porta
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$origem = Join-Path $raiz "mobile\MoveTech.apk"
if (-not (Test-Path $origem)) {
    Write-Host "O APK nao foi gerado. Veja as mensagens acima." -ForegroundColor Red
    exit 1
}
Copy-Item $origem (Join-Path $raiz "MoveTech.apk") -Force

Write-Host ""
Write-Host "APK pronto: $raiz\MoveTech.apk" -ForegroundColor Green
Write-Host "Para baixar no celular pela rede:  .\4_compartilhar_apk.ps1"
