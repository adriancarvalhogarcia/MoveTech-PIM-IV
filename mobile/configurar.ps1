# ------------------------------------------------------------------
# MoveTech Mobile - configuracao inicial (Windows / PowerShell)
#
# Execute dentro da pasta do projeto:
#   powershell -ExecutionPolicy Bypass -File .\configurar.ps1
#
# O que o script faz:
#  1. gera as pastas nativas (android/ e ios/) com o flutter create,
#     sem sobrescrever o codigo que ja esta em lib/;
#  2. libera acesso a internet e a HTTP (sem HTTPS) no Android, porque
#     a API do MoveTech roda em http://<ip>:5071 durante o desenvolvimento;
#  3. baixa as dependencias (flutter pub get).
#
# Pode ser executado mais de uma vez sem problema.
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
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERRO: o comando 'flutter' nao foi encontrado." -ForegroundColor Red
    Write-Host "Instale o Flutter e coloque C:\src\flutter\bin no PATH (veja o README, passo 1.4)."
    exit 1
}

$manifesto = Join-Path $PSScriptRoot "android\app\src\main\AndroidManifest.xml"

if (-not (Test-Path $manifesto)) {
    Write-Host "1/3 - Gerando pastas nativas (android/ e ios/)..." -ForegroundColor Green
    flutter create --org br.com.movetech --project-name movetech_mobile --platforms android,ios .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host "1/3 - Pastas nativas ja existem." -ForegroundColor Green
}

Write-Host "2/3 - Ajustando AndroidManifest.xml..." -ForegroundColor Green
$conteudo = [System.IO.File]::ReadAllText($manifesto)

if ($conteudo -notmatch "android.permission.INTERNET") {
    $conteudo = $conteudo -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
}
if ($conteudo -notmatch "usesCleartextTraffic") {
    $conteudo = $conteudo -replace '<application', '<application android:usesCleartextTraffic="true"'
}
$conteudo = $conteudo -replace 'android:label="movetech_mobile"', 'android:label="MoveTech"'

[System.IO.File]::WriteAllText($manifesto, $conteudo)

Write-Host "3/3 - Baixando dependencias..." -ForegroundColor Green
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Pronto!" -ForegroundColor Green
Write-Host "  Rodar no emulador ou celular via USB:  ..\5_rodar_no_emulador.ps1"
Write-Host "  Gerar o APK para instalar no celular:  ..\3_gerar_apk.ps1"
