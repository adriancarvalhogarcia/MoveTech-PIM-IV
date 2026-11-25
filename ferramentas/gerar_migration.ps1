# ------------------------------------------------------------------
# MoveTech - gera uma migration do Entity Framework e o script SQL
# completo do banco (banco\03_script_completo_ef.sql).
#
# Feche a janela da API antes (o build nao funciona com ela aberta).
# Uso: dois cliques em ferramentas\gerar_migration.cmd
# ------------------------------------------------------------------
param([string]$Nome = "ModulosFinanceiroNotasDevolucao")

$ErrorActionPreference = "Continue"
$raiz = Split-Path $PSScriptRoot -Parent
$api = Join-Path $raiz "backend\SmartMoveis.API"
$env:DOTNET_ROLL_FORWARD = "Major"

Write-Host "1/4 - Conferindo a ferramenta dotnet-ef..." -ForegroundColor Cyan
$ferramentas = & dotnet tool list --global
if (-not ($ferramentas -match "dotnet-ef")) {
    & dotnet tool install --global dotnet-ef --version 9.0.13
}
$env:PATH = "$env:PATH;$env:USERPROFILE\.dotnet\tools"

Write-Host "2/4 - Compilando a API..." -ForegroundColor Cyan
& dotnet build $api -c Debug
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO: a API nao compilou." -ForegroundColor Red; exit 1 }

$existe = Get-ChildItem (Join-Path $api "Migrations") -Filter "*_$Nome.cs" -ErrorAction SilentlyContinue
if ($existe) {
    Write-Host "3/4 - A migration $Nome ja existe, nada a gerar." -ForegroundColor Yellow
} else {
    Write-Host "3/4 - Gerando a migration $Nome..." -ForegroundColor Cyan
    & dotnet ef migrations add $Nome --project $api --no-build
    if ($LASTEXITCODE -ne 0) { Write-Host "ERRO ao gerar a migration." -ForegroundColor Red; exit 1 }
}

Write-Host "4/4 - Gerando o script SQL completo..." -ForegroundColor Cyan
& dotnet build $api -c Debug | Out-Null
& dotnet ef migrations script --idempotent --project $api --no-build -o (Join-Path $raiz "banco\03_script_completo_ef.sql")
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO ao gerar o script SQL." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Pronto! Migration e banco\03_script_completo_ef.sql gerados." -ForegroundColor Green
