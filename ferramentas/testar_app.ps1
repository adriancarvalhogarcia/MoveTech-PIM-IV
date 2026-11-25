# ------------------------------------------------------------------
# MoveTech - analise estatica e testes de unidade do app Flutter
# (mesmos passos do pipeline de CI). Resultado em logs\resultado_app.txt
# Uso: dois cliques em ferramentas\testar_app.cmd
# ------------------------------------------------------------------
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    foreach ($p in @("$env:USERPROFILE\srcflutter\bin", "C:\src\flutter\bin", "$env:USERPROFILE\flutter\bin", "C:\flutter\bin")) {
        if (Test-Path (Join-Path $p "flutter.bat")) { $env:Path = "$p;$env:Path"; break }
    }
}
$raiz = Split-Path $PSScriptRoot -Parent
Set-Location (Join-Path $raiz "mobile")
$saida = New-Object System.Collections.Generic.List[string]
Write-Host "1/2 - flutter analyze..." -ForegroundColor Cyan
$a = & flutter analyze --no-fatal-infos 2>&1 | Out-String
$okA = ($LASTEXITCODE -eq 0)
Write-Host $a
Write-Host "2/2 - flutter test..." -ForegroundColor Cyan
$t = & flutter test 2>&1 | Out-String
$okT = ($LASTEXITCODE -eq 0)
Write-Host $t
$res = @("Testes do app - $(Get-Date -Format 'dd/MM/yyyy HH:mm')",
         "flutter analyze: $(if ($okA) {'OK'} else {'FALHOU'})",
         "flutter test:    $(if ($okT) {'OK'} else {'FALHOU'})", "", "=== analyze ===", $a, "=== test ===", $t)
$res | Set-Content (Join-Path $raiz "logs\resultado_app.txt") -Encoding UTF8
Write-Host "Resumo em logs\resultado_app.txt"
