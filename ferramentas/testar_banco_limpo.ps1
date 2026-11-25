# ------------------------------------------------------------------
# MoveTech - TESTE DO BANCO EM UM SERVIDOR LIMPO (Etapa 7)
#
# Cria um banco temporario "smartmoveis_teste_limpo", roda nele os
# scripts 01 e 02, sobe uma segunda API (porta 5072) que aplica as
# migrations, triggers e procedures, testa tudo e apaga o banco de
# teste no final. O banco real "smartmoveis" nao e tocado.
#
# Tambem exporta o modelo logico (tabelas, colunas, chaves) para
# banco\05_modelo_logico.md.
#
# Pode deixar a API normal (2_iniciar_api) aberta: este teste usa a 5072.
# Uso: dois cliques em ferramentas\testar_banco_limpo.cmd
# ------------------------------------------------------------------
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_comum_mysql.ps1")

$teste = "smartmoveis_teste_limpo"
$porta = 5072
$base = "http://localhost:$porta"
$resultados = New-Object System.Collections.Generic.List[string]
$falhas = 0
function Registrar([string]$nome, [bool]$ok, [string]$detalhe = "") {
    $marca = if ($ok) { "[ OK ]" } else { "[FALHOU]" }
    if (-not $ok) { $script:falhas++ }
    $linha = "$marca $nome" + $(if ($detalhe) { " - $detalhe" } else { "" })
    $script:resultados.Add($linha)
    Write-Host $linha -ForegroundColor $(if ($ok) { "Green" } else { "Red" })
}

$conexao = Obter-Conexao
$dll = Join-Path $PastaApi "bin\Debug\net10.0\SmartMoveis.API.dll"
if (-not (Test-Path $dll)) { throw "API ainda nao compilada. Rode o 2_iniciar_api.cmd uma vez." }
$pastaTmp = Join-Path $Raiz "logs\tmp_banco_limpo"
New-Item -ItemType Directory -Force -Path $pastaTmp | Out-Null

Write-Host "1/6 - Criando o banco de teste $teste (vazio)..." -ForegroundColor Cyan
Invoke-MySql $conexao "DROP DATABASE IF EXISTS $teste;" | Out-Null

Write-Host "2/6 - Rodando 01_criar_banco.sql e 02_dados_iniciais.sql no banco de teste..." -ForegroundColor Cyan
foreach ($arq in @("01_criar_banco.sql", "02_dados_iniciais.sql")) {
    $conteudo = Get-Content (Join-Path $Raiz "banco\$arq") -Raw -Encoding UTF8
    $conteudo = $conteudo -creplace "\bsmartmoveis\b", $teste
    $tmp = Join-Path $pastaTmp $arq
    [System.IO.File]::WriteAllText($tmp, $conteudo, (New-Object System.Text.UTF8Encoding $false))
    $r = Invoke-MySql $conexao ("source " + ($tmp -replace '\\', '/')) -PermitirErro
    Registrar "Script $arq em banco limpo" $r.Ok $(if (-not $r.Ok) { $r.Saida } else { "" })
}

Write-Host "3/6 - Subindo uma API de teste na porta $porta (aplica as migrations)..." -ForegroundColor Cyan
$conexaoTeste = $conexao.Texto -replace "database=[^;]+", "database=$teste"
$env:ConnectionStrings__DefaultConnection = $conexaoTeste
$env:ASPNETCORE_ENVIRONMENT = "Development"
$logApi = Join-Path $Raiz "logs\banco_limpo_api.txt"
$processo = Start-Process -FilePath "dotnet" -ArgumentList @("`"$dll`"", "--urls", $base) `
    -WorkingDirectory $PastaApi -PassThru -NoNewWindow `
    -RedirectStandardOutput $logApi -RedirectStandardError (Join-Path $Raiz "logs\banco_limpo_api_erros.txt")
$env:ConnectionStrings__DefaultConnection = $null

try {
    $saude = $null
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Seconds 2
        try { $saude = Invoke-RestMethod "$base/health" -TimeoutSec 3; break } catch { }
        if ($processo.HasExited) { break }
    }
    Registrar "API de teste subiu e /health respondeu" ($saude -eq "Healthy") "$saude"

    Write-Host "4/6 - Conferindo tabelas, triggers e procedures criadas..." -ForegroundColor Cyan
    $tabelas = (Invoke-MySql $conexao "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$teste' AND table_name <> '__EFMigrationsHistory';").Saida -split "`n" | Select-Object -Last 1
    Registrar "Tabelas criadas" ([int]$tabelas -ge 14) "$tabelas tabelas"
    $trg = (Invoke-MySql $conexao "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='$teste';").Saida -split "`n" | Select-Object -Last 1
    Registrar "Triggers criadas" ([int]$trg -eq 4) "$trg triggers"
    $sp = (Invoke-MySql $conexao "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='$teste' AND routine_type='PROCEDURE';").Saida -split "`n" | Select-Object -Last 1
    Registrar "Procedures criadas" ([int]$sp -eq 4) "$sp procedures"
    $mig = (Invoke-MySql $conexao "SELECT COUNT(*) FROM __EFMigrationsHistory;" $teste).Saida -split "`n" | Select-Object -Last 1
    Registrar "Migrations registradas" ([int]$mig -ge 7) "$mig migrations"

    Write-Host "5/6 - Testando triggers e procedures..." -ForegroundColor Cyan
    $r = Invoke-MySql $conexao "UPDATE Produtos SET QuantidadeEstoque = -1 WHERE Id = (SELECT Id FROM (SELECT MIN(Id) AS Id FROM Produtos) x);" $teste -PermitirErro
    Registrar "Trigger bloqueia estoque negativo (UPDATE)" ((-not $r.Ok) -and ($r.Saida -match "Estoque nao pode ser negativo")) ($r.Saida -replace "\s+", " ")
    $r = Invoke-MySql $conexao "INSERT INTO Produtos (Nome, Categoria, Preco, QuantidadeEstoque, EstoqueMinimo, CustoMedio, Ativo, CriadoEm) VALUES ('Teste', 'Teste', 1, -5, 0, 0, 1, NOW());" $teste -PermitirErro
    Registrar "Trigger bloqueia estoque negativo (INSERT)" ((-not $r.Ok) -and ($r.Saida -match "Estoque nao pode ser negativo")) ($r.Saida -replace "\s+", " ")
    $r = Invoke-MySql $conexao "INSERT INTO ContasFinanceiras (Tipo, Descricao, Origem, NumeroParcela, TotalParcelas, Valor, Vencimento, Status, CriadoEm) VALUES ('Pagar', 'Teste', 'Manual', 1, 1, 0, CURDATE(), 'Aberta', NOW());" $teste -PermitirErro
    Registrar "Trigger bloqueia conta com valor zero" ((-not $r.Ok) -and ($r.Saida -match "maior que zero")) ($r.Saida -replace "\s+", " ")

    $login = Invoke-RestMethod "$base/api/auth/login" -Method Post -ContentType "application/json" `
        -Body '{"email":"admin@movetech.com","senha":"Admin@123"}'
    $h = @{ Authorization = "Bearer $($login.token)" }
    Registrar "Login do admin no banco limpo" ([bool]$login.token)

    $cliente = (Invoke-RestMethod "$base/api/clientes" -Headers $h) | Select-Object -First 1
    $produto = (Invoke-RestMethod "$base/api/produtos" -Headers $h) | Where-Object { $_.quantidadeEstoque -gt 0 } | Select-Object -First 1
    $corpo = @{ clienteId = $cliente.id; formaPagamento = "Pix"; parcelas = 1; itens = @(@{ produtoId = $produto.id; quantidade = 1 }) } | ConvertTo-Json -Depth 4
    $venda = Invoke-RestMethod "$base/api/vendas" -Method Post -Headers $h -ContentType "application/json" -Body $corpo
    Registrar "Venda registrada pela API" ([bool]$venda.id) "venda #$($venda.id), produto $($produto.nome)"

    $mov = Invoke-RestMethod "$base/api/relatorios/banco/movimentacoes-estoque?produtoId=$($produto.id)&limite=5" -Headers $h
    $m = $mov.itens | Select-Object -First 1
    Registrar "Trigger de auditoria gravou a saida" ($m.tipo -eq "SAIDA" -and $m.diferenca -eq -1) "$($m.quantidadeAnterior) -> $($m.quantidadeNova)"

    $res = Invoke-RestMethod "$base/api/relatorios/banco/resumo-vendas" -Headers $h
    Registrar "sp_resumo_vendas_periodo" ($res.resumo.quantidadeVendas -ge 1) "vendas: $($res.resumo.quantidadeVendas), liquido: $($res.resumo.faturamentoLiquido)"
    $eb = Invoke-RestMethod "$base/api/relatorios/banco/estoque-baixo" -Headers $h
    Registrar "sp_produtos_estoque_baixo" ($null -ne $eb.itens) "$(@($eb.itens).Count) produto(s)"
    $cv = Invoke-RestMethod "$base/api/relatorios/banco/contas-vencidas" -Headers $h
    Registrar "sp_contas_vencidas" ($null -ne $cv.itens) "$(@($cv.itens).Count) conta(s)"

    Write-Host "6/6 - Exportando o modelo logico para banco\05_modelo_logico.md..." -ForegroundColor Cyan
    $colunas = (Invoke-MySql $conexao "SELECT c.TABLE_NAME, c.COLUMN_NAME, c.COLUMN_TYPE, c.IS_NULLABLE, c.COLUMN_KEY, IFNULL(CONCAT(k.REFERENCED_TABLE_NAME,'.',k.REFERENCED_COLUMN_NAME),'') FROM information_schema.columns c LEFT JOIN information_schema.key_column_usage k ON k.TABLE_SCHEMA=c.TABLE_SCHEMA AND k.TABLE_NAME=c.TABLE_NAME AND k.COLUMN_NAME=c.COLUMN_NAME AND k.REFERENCED_TABLE_NAME IS NOT NULL WHERE c.TABLE_SCHEMA='$teste' AND c.TABLE_NAME <> '__EFMigrationsHistory' ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;").Saida -split "`r?`n" | Select-Object -Skip 1
    $md = New-Object System.Text.StringBuilder
    [void]$md.AppendLine("# MoveTech - Modelo logico do banco smartmoveis")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("Gerado por ferramentas\testar_banco_limpo.ps1 em $(Get-Date -Format 'dd/MM/yyyy HH:mm') a partir de um banco criado do zero (scripts 01/02 + migrations).")
    [void]$md.AppendLine("PK = chave primaria, FK = chave estrangeira, UNI/MUL = indice.")
    $atual = ""
    foreach ($l in $colunas) {
        # O Trim() da saida remove tabs vazios do fim da ultima linha: completa ate 6 campos.
        $c = @($l -split "`t") + @("", "", "")
        if ($c.Count -lt 7 -or -not $c[1]) { continue }
        if ($c[0] -ne $atual) {
            $atual = $c[0]
            [void]$md.AppendLine(""); [void]$md.AppendLine("## $atual"); [void]$md.AppendLine("")
            [void]$md.AppendLine("| Coluna | Tipo | Nulo | Chave | Referencia |"); [void]$md.AppendLine("|---|---|---|---|---|")
        }
        $chave = switch ($c[4]) { "PRI" { "PK" } "UNI" { "UNI" } "MUL" { if ($c[5]) { "FK" } else { "MUL" } } default { "" } }
        [void]$md.AppendLine("| $($c[1]) | $($c[2]) | $($c[3]) | $chave | $($c[5]) |")
    }
    [System.IO.File]::WriteAllText((Join-Path $Raiz "banco\05_modelo_logico.md"), $md.ToString(), (New-Object System.Text.UTF8Encoding $false))
    Registrar "Modelo logico exportado" ($colunas.Count -gt 50) "$($colunas.Count) colunas"
}
catch {
    Registrar "Erro inesperado" $false $_.Exception.Message
}
finally {
    if ($processo -and -not $processo.HasExited) { Stop-Process -Id $processo.Id -Force }
    Start-Sleep -Seconds 1
    Invoke-MySql $conexao "DROP DATABASE IF EXISTS $teste;" -PermitirErro | Out-Null
    Remove-Item $pastaTmp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Banco de teste apagado. O banco smartmoveis nao foi alterado."
}

$resumo = Join-Path $Raiz "logs\resultado_banco_limpo.txt"
@("Teste do banco limpo - $(Get-Date -Format 'dd/MM/yyyy HH:mm')", "") + $resultados + @("", "Falhas: $falhas") |
    Set-Content -Path $resumo -Encoding UTF8
Write-Host ""
Write-Host $(if ($falhas -eq 0) { "TUDO OK." } else { "$falhas teste(s) falharam." }) -ForegroundColor $(if ($falhas -eq 0) { "Green" } else { "Red" })
Write-Host "Resumo em logs\resultado_banco_limpo.txt"
