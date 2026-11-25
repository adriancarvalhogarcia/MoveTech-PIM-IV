# ------------------------------------------------------------------
# MoveTech - sobe a API do PIM III aceitando conexoes da rede local
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\2_iniciar_api.ps1
#
# Deixe esta janela aberta enquanto usa o app ou o sistema web.
# Para parar a API: Ctrl+C.
#
# O que o script faz:
#  1. confere o .NET e inicia o MySQL, se estiver parado;
#  2. confere se a connection string ja foi gravada (script 1) e gera
#     a chave JWT nos user-secrets, se ainda nao existir;
#  3. libera a porta no firewall (so se o PowerShell for administrador);
#  4. mostra o endereco para usar no celular;
#  5. executa a API em http://0.0.0.0:5071 (todas as interfaces de rede).
# ------------------------------------------------------------------

param(
    [int]$Porta = 5071
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$pastaApi = Join-Path $PSScriptRoot "backend\SmartMoveis.API"

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "O .NET SDK nao esta instalado (README, passo 1.2)." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $pastaApi "SmartMoveis.API.csproj"))) {
    Write-Host "Nao encontrei a API em $pastaApi" -ForegroundColor Red
    exit 1
}

# 1. MySQL
$servico = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($servico -and $servico.Status -ne "Running") {
    Write-Host "Iniciando o servico $($servico.Name)..."
    try {
        Start-Service -Name $servico.Name
    } catch {
        Write-Host "Nao consegui iniciar o MySQL (precisa de administrador)." -ForegroundColor Red
        Write-Host "Abra o PowerShell como administrador e rode:  net start $($servico.Name)"
        exit 1
    }
}

# 2. Connection string
$segredos = & dotnet user-secrets list --project $pastaApi
if (-not ($segredos -match "ConnectionStrings:DefaultConnection")) {
    Write-Host "A API ainda nao tem a connection string do banco." -ForegroundColor Red
    Write-Host "Rode primeiro:  .\1_preparar_banco.ps1"
    exit 1
}

# 2b. Chave JWT (fica nos user-secrets, fora do codigo-fonte)
if (-not ($segredos -match "Jwt:Key")) {
    $bytes = New-Object byte[] 48
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $chave = [Convert]::ToBase64String($bytes)
    & dotnet user-secrets set "Jwt:Key" $chave --project $pastaApi | Out-Null
    Write-Host "Chave JWT gerada e guardada nos user-secrets." -ForegroundColor Green
}

# 3. Firewall
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
$regra = Get-NetFirewallRule -DisplayName "MoveTech API" -ErrorAction SilentlyContinue
if (-not $regra) {
    if ($admin) {
        New-NetFirewallRule -DisplayName "MoveTech API" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Porta | Out-Null
        Write-Host "Porta $Porta liberada no firewall do Windows." -ForegroundColor Green
    } else {
        Write-Host "ATENCAO: a porta $Porta ainda nao esta liberada no firewall." -ForegroundColor Yellow
        Write-Host "O celular nao vai conseguir conectar. Uma unica vez, abra o PowerShell"
        Write-Host "como administrador e rode:"
        Write-Host "  netsh advfirewall firewall add rule name=`"MoveTech API`" dir=in action=allow protocol=TCP localport=$Porta"
        Write-Host ""
    }
}

# 4. Endereco para o celular
$ip = ""
try {
    $ip = (Get-NetIPConfiguration |
        Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq "Up" } |
        Select-Object -First 1).IPv4Address.IPAddress
} catch { }

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " API MoveTech" -ForegroundColor Cyan
Write-Host "   Neste computador:   http://localhost:$Porta"
if ($ip) {
    Write-Host "   No celular (app):   http://${ip}:${Porta}/api" -ForegroundColor Green
    Write-Host "   Teste no navegador do celular: http://${ip}:${Porta}"
} else {
    Write-Host "   Nao descobri o IP. Rode 'ipconfig' e use o Endereco IPv4." -ForegroundColor Yellow
}
Write-Host "   Emulador Android:   http://10.0.2.2:$Porta/api"
Write-Host "   Para parar: Ctrl+C"
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# 5. Sobe a API (a primeira vez baixa os pacotes NuGet e demora mais)
dotnet run --project $pastaApi -- --urls "http://0.0.0.0:$Porta"
