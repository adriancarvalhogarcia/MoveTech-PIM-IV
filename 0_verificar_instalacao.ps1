# ------------------------------------------------------------------
# MoveTech - confere se os programas necessarios estao instalados
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\0_verificar_instalacao.ps1
#
# Nao instala nem altera nada. So mostra o que esta OK e o que falta.
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

$faltando = 0

function Mostrar([string]$nome, [bool]$ok, [string]$detalhe, [string]$comoResolver) {
    if ($ok) {
        Write-Host ("[ OK  ] {0,-28} {1}" -f $nome, $detalhe) -ForegroundColor Green
    } else {
        Write-Host ("[FALTA] {0,-28} {1}" -f $nome, $comoResolver) -ForegroundColor Yellow
        $script:faltando++
    }
}

Write-Host ""
Write-Host "Conferindo os programas necessarios..." -ForegroundColor Cyan
Write-Host ""

# Git
$git = Get-Command git -ErrorAction SilentlyContinue
$v = ""; if ($git) { $v = (& git --version) }
Mostrar "Git" ($null -ne $git) $v "README, passo 1.1"

# .NET SDK 10
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
$sdk10 = $false; $v = ""
if ($dotnet) {
    $sdks = (& dotnet --list-sdks) 2>$null
    $linha = $sdks | Where-Object { $_ -match "^10\." } | Select-Object -First 1
    if ($linha) { $sdk10 = $true; $v = "SDK " + ($linha -split " ")[0] }
}
Mostrar ".NET 10 SDK" $sdk10 $v "README, passo 1.2 (precisa ser o SDK 10, nao so o Runtime)"

# MySQL
$servico = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue | Select-Object -First 1
$v = ""; if ($servico) { $v = "servico $($servico.Name): $($servico.Status)" }
Mostrar "MySQL Server" ($null -ne $servico) $v "README, passo 1.3"

# Flutter
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
$v = ""; if ($flutter) { $v = $flutter.Source }
Mostrar "Flutter SDK" ($null -ne $flutter) $v "README, passo 1.4 (e coloque C:\src\flutter\bin no PATH)"

# Android SDK
$sdkAndroid = $env:ANDROID_HOME
if (-not $sdkAndroid) { $sdkAndroid = $env:ANDROID_SDK_ROOT }
if (-not $sdkAndroid) { $sdkAndroid = Join-Path $env:LOCALAPPDATA "Android\Sdk" }
$temSdk = Test-Path (Join-Path $sdkAndroid "platform-tools")
Mostrar "Android SDK" $temSdk $sdkAndroid "README, passo 1.6 (Android Studio)"

$temCmdline = Test-Path (Join-Path $sdkAndroid "cmdline-tools")
Mostrar "Android Command-line Tools" $temCmdline "instalado" "README, passo 1.6, item 3"

# Modo de Desenvolvedor
$dev = $false
try {
    $chave = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction Stop
    $dev = ($chave.AllowDevelopmentWithoutDevLicense -eq 1)
} catch { }
Mostrar "Modo de Desenvolvedor" $dev "ligado" "README, passo 1.5"

# Pastas do projeto
$api = Test-Path (Join-Path $PSScriptRoot "backend\SmartMoveis.API\SmartMoveis.API.csproj")
Mostrar "Pasta backend (API)" $api "encontrada" "extraia o zip inteiro, sem mover as pastas"
$app = Test-Path (Join-Path $PSScriptRoot "mobile\pubspec.yaml")
Mostrar "Pasta mobile (app)" $app "encontrada" "extraia o zip inteiro, sem mover as pastas"

Write-Host ""
if ($faltando -eq 0) {
    Write-Host "Tudo pronto. Proximo passo:  .\1_preparar_banco.ps1" -ForegroundColor Green
    if ($flutter) {
        Write-Host "Dica: rode tambem 'flutter doctor' para um diagnostico completo do Flutter."
    }
} else {
    Write-Host "$faltando item(ns) pendente(s). Resolva pelo README e rode este script de novo." -ForegroundColor Yellow
}
Write-Host ""
