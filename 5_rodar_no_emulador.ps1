# ------------------------------------------------------------------
# MoveTech - roda o app direto no emulador ou em um celular ligado
# pelo cabo USB (modo desenvolvimento, sem gerar APK)
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\5_rodar_no_emulador.ps1
#
# Antes: abra o emulador no Android Studio (Virtual Device Manager)
# ou conecte o celular com a Depuracao USB ativada.
# ------------------------------------------------------------------

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
$mobile = Join-Path $PSScriptRoot "mobile"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "O Flutter nao esta instalado ou nao esta no PATH (README, passo 1.4)." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path (Join-Path $mobile "android\app\src\main\AndroidManifest.xml"))) {
    & (Join-Path $mobile "configurar.ps1")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Set-Location $mobile
flutter run
