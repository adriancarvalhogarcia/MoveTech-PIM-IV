# ------------------------------------------------------------------
# MoveTech - funcoes compartilhadas pelos scripts de banco da pasta
# ferramentas. Le a conexao que o 1_preparar_banco gravou nos
# user-secrets da API, assim nenhuma senha precisa ser digitada de novo
# nem fica gravada em arquivo.
# ------------------------------------------------------------------

$script:Raiz = Split-Path $PSScriptRoot -Parent
$script:PastaApi = Join-Path $script:Raiz "backend\SmartMoveis.API"

function Obter-Conexao {
    $linhas = & dotnet user-secrets list --project $script:PastaApi
    $linha = $linhas | Where-Object { $_ -like "ConnectionStrings:DefaultConnection*" } | Select-Object -First 1
    if (-not $linha) {
        throw "Connection string nao encontrada. Rode antes o 1_preparar_banco.cmd."
    }
    $texto = ($linha -split " = ", 2)[1]
    $partes = @{}
    foreach ($p in $texto.Split(";")) {
        if ($p -match "^\s*([^=]+)=(.*)$") { $partes[$Matches[1].Trim().ToLower()] = $Matches[2] }
    }
    return [pscustomobject]@{
        Texto    = $texto
        Servidor = $partes["server"]
        Porta    = if ($partes["port"]) { $partes["port"] } else { "3306" }
        Banco    = $partes["database"]
        Usuario  = $partes["user"]
        Senha    = $partes["password"]
    }
}

function Obter-BinMysql {
    $mysql = (Get-Command mysql -ErrorAction SilentlyContinue).Source
    if (-not $mysql) {
        $mysql = Get-ChildItem "C:\Program Files\MySQL\MySQL Server *\bin\mysql.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $mysql) { throw "mysql.exe nao encontrado." }
    return Split-Path $mysql
}

# Executa SQL e devolve a saida em texto (tabulada). -Banco opcional.
function Invoke-MySql([object]$Conexao, [string]$Sql, [string]$Banco = "", [switch]$PermitirErro) {
    $ErrorActionPreference = "Continue"
    $bin = Obter-BinMysql
    $env:MYSQL_PWD = $Conexao.Senha
    try {
        $argumentos = @("--host=$($Conexao.Servidor)", "--port=$($Conexao.Porta)", "--user=$($Conexao.Usuario)",
                  "--default-character-set=utf8mb4", "--batch")
        if ($Banco) { $argumentos += "--database=$Banco" }
        $argumentos += "--execute=$Sql"
        $saida = & (Join-Path $bin "mysql.exe") @argumentos 2>&1
        $saida = $saida | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { $_ } }
        $ok = ($LASTEXITCODE -eq 0)
        if (-not $ok -and -not $PermitirErro) { throw "Erro no MySQL: $saida" }
        return [pscustomobject]@{ Ok = $ok; Saida = ($saida | Out-String).Trim() }
    } finally {
        $env:MYSQL_PWD = $null
    }
}
