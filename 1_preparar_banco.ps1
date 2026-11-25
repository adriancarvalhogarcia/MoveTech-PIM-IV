# ------------------------------------------------------------------
# MoveTech - prepara o banco MySQL (Windows / PowerShell)
#
# Uso:  powershell -ExecutionPolicy Bypass -File .\1_preparar_banco.ps1
#
# O que o script faz:
#  1. confere se o servico do MySQL esta rodando e tenta inicia-lo;
#  2. VERIFICA se o banco "smartmoveis" e as 5 tabelas ja existem:
#       - ja existem  -> nao cria nada, so deixa o MySQL iniciado;
#       - nao existem -> cria o banco e as tabelas (banco\01_criar_banco.sql)
#                        e o usuario admin@movetech.com / Admin@123 com
#                        dados de exemplo (banco\02_dados_iniciais.sql);
#  3. grava a connection string na API (backend\SmartMoveis.API),
#     usando user-secrets, fora do codigo-fonte.
#
# Pode ser executado toda vez antes de subir a API: nada e apagado.
# Para recriar os dados de exemplo em um banco que ja existe, use -Forcar.
# ------------------------------------------------------------------

param(
    [string]$Usuario = "root",
    [string]$Servidor = "localhost",
    [int]$Porta = 3306,
    [string]$PastaApi = "",   # vazio = backend\SmartMoveis.API deste pacote
    [switch]$SemDadosIniciais,
    [switch]$Forcar
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$banco = "smartmoveis"

if ([string]::IsNullOrWhiteSpace($PastaApi)) {
    $PastaApi = Join-Path $PSScriptRoot "backend\SmartMoveis.API"
}

# ---------------------------------------------------------------
# 1. Servico do MySQL
# ---------------------------------------------------------------
Write-Host "1/4 - Conferindo o servico do MySQL..." -ForegroundColor Green
$servico = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($null -eq $servico) {
    Write-Host "Nenhum servico do MySQL foi encontrado neste computador." -ForegroundColor Yellow
    Write-Host "Instale o MySQL Server 8 (README, passo 1.3). Se ele roda de outra forma"
    Write-Host "(XAMPP, Docker), inicie-o por la; o script vai tentar conectar mesmo assim."
} elseif ($servico.Status -ne "Running") {
    Write-Host "Servico '$($servico.Name)' esta parado. Tentando iniciar..."
    try {
        Start-Service -Name $servico.Name
        Write-Host "Servico iniciado."
    } catch {
        Write-Host "Nao foi possivel iniciar (precisa de permissao de administrador)." -ForegroundColor Red
        Write-Host "Abra o PowerShell como administrador e rode:  net start $($servico.Name)"
        Write-Host "Ou abra 'Servicos' (services.msc), localize $($servico.Name) e clique em Iniciar."
        exit 1
    }
} else {
    Write-Host "Servico '$($servico.Name)' ja esta rodando."
}

# ---------------------------------------------------------------
# 2. Localiza o cliente mysql.exe
# ---------------------------------------------------------------
$mysql = (Get-Command mysql -ErrorAction SilentlyContinue).Source
if (-not $mysql) {
    $mysql = Get-ChildItem "C:\Program Files\MySQL\MySQL Server *\bin\mysql.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $mysql) {
    $mysql = Get-ChildItem "C:\xampp\mysql\bin\mysql.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $mysql) {
    Write-Host "Nao encontrei o mysql.exe." -ForegroundColor Red
    Write-Host "Alternativa: abra os arquivos da pasta 'banco' no MySQL Workbench e execute"
    Write-Host "primeiro o 01_criar_banco.sql e depois o 02_dados_iniciais.sql."
    exit 1
}

# ---------------------------------------------------------------
# 3. Senha (nao aparece na tela nem fica gravada em arquivo)
# ---------------------------------------------------------------
# Ate 5 tentativas: cada senha e testada antes de seguir.
$maxTentativas = 5
$senha = $null
for ($tentativa = 1; $tentativa -le $maxTentativas; $tentativa++) {
    $senhaSegura = Read-Host "Senha do usuario '$Usuario' do MySQL (tentativa $tentativa de $maxTentativas)" -AsSecureString
    $candidata = [System.Net.NetworkCredential]::new("", $senhaSegura).Password
    $env:MYSQL_PWD = $candidata

    # Teste de conexao. Erro aqui e esperado quando a senha esta errada,
    # entao o "Stop" e desligado so durante o teste.
    $ErrorActionPreference = "Continue"
    & $mysql --host=$Servidor --port=$Porta --user=$Usuario --batch --skip-column-names "--execute=SELECT 1" 2>$null | Out-Null
    $conectou = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = "Stop"

    if ($conectou) {
        $senha = $candidata
        Write-Host "      Senha correta." -ForegroundColor Green
        break
    }
    if ($tentativa -lt $maxTentativas) {
        Write-Host "      Senha incorreta (ou MySQL fora do ar). Tente de novo." -ForegroundColor Yellow
    }
}
if ($null -eq $senha) {
    $env:MYSQL_PWD = $null
    Write-Host ""
    Write-Host "Nao foi possivel entrar no MySQL depois de $maxTentativas tentativas." -ForegroundColor Red
    Write-Host "Se nao lembra a senha do root, rode o redefinir_senha_mysql.cmd para criar uma nova."
    exit 1
}

# Executa uma consulta que devolve um unico numero.
function Consultar-Numero([string]$sql) {
    $saida = & $mysql --host=$Servidor --port=$Porta --user=$Usuario --batch --skip-column-names "--execute=$sql"
    if ($LASTEXITCODE -ne 0) {
        $env:MYSQL_PWD = $null
        Write-Host "Nao foi possivel conectar ao MySQL. Confira a senha e se o servico esta rodando." -ForegroundColor Red
        exit 1
    }
    return [int](($saida | Select-Object -First 1).ToString().Trim())
}

function Executar-Sql([string]$arquivo) {
    $caminho = (Join-Path $PSScriptRoot $arquivo) -replace '\\', '/'
    & $mysql --host=$Servidor --port=$Porta --user=$Usuario --default-character-set=utf8mb4 "--execute=source $caminho"
    if ($LASTEXITCODE -ne 0) {
        $env:MYSQL_PWD = $null
        Write-Host "Falha ao executar $arquivo. Confira a senha e se o MySQL esta rodando." -ForegroundColor Red
        exit 1
    }
}

$criouAgora = $false
try {
    # -----------------------------------------------------------
    # Verifica o que ja existe antes de criar qualquer coisa
    # -----------------------------------------------------------
    Write-Host "2/4 - Verificando se o banco '$banco' ja existe..." -ForegroundColor Green

    $bancoExiste = Consultar-Numero "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = '$banco'"
    $tabelas = 0
    if ($bancoExiste -gt 0) {
        $tabelas = Consultar-Numero "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$banco' AND LOWER(table_name) IN ('usuarios','clientes','produtos','vendas','itensvenda')"
    }

    if ($bancoExiste -gt 0 -and $tabelas -eq 5 -and -not $Forcar) {
        Write-Host "      O banco e as 5 tabelas ja existem. Nada foi criado nem alterado."
        Write-Host "3/4 - Dados iniciais nao alterados (banco ja existia)." -ForegroundColor Green
    } else {
        if ($bancoExiste -eq 0) {
            Write-Host "      O banco ainda nao existe. Criando o banco e as tabelas..."
        } elseif ($tabelas -lt 5) {
            Write-Host "      O banco existe, mas so tem $tabelas de 5 tabelas. Criando as que faltam..."
        } else {
            Write-Host "      -Forcar informado: conferindo a estrutura de novo..."
        }
        Executar-Sql "banco\01_criar_banco.sql"
        $criouAgora = $true

        if (-not $SemDadosIniciais) {
            Write-Host "3/4 - Criando o usuario administrador e os dados de exemplo..." -ForegroundColor Green
            Executar-Sql "banco\02_dados_iniciais.sql"
        } else {
            Write-Host "3/4 - Dados iniciais ignorados (-SemDadosIniciais)." -ForegroundColor Green
        }
    }

    $totalUsuarios = Consultar-Numero "SELECT COUNT(*) FROM $banco.usuarios"
} finally {
    $env:MYSQL_PWD = $null
}

# ---------------------------------------------------------------
# 4. Connection string da API
# ---------------------------------------------------------------
Write-Host "4/4 - Gravando a connection string na API..." -ForegroundColor Green
if (-not (Test-Path (Join-Path $PastaApi "SmartMoveis.API.csproj"))) {
    Write-Host "Nao encontrei SmartMoveis.API.csproj em $PastaApi" -ForegroundColor Red
    Write-Host "Extraia o zip inteiro, mantendo as pastas backend, mobile e banco juntas."
    exit 1
}
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "O .NET SDK nao esta instalado (README, passo 1.2)." -ForegroundColor Red
    Write-Host "O banco foi preparado, mas a API ainda nao sabe a senha. Instale o .NET e rode este script de novo."
    exit 1
}
$conexao = "server=$Servidor;port=$Porta;database=$banco;user=$Usuario;password=$senha"
dotnet user-secrets set "ConnectionStrings:DefaultConnection" $conexao --project $PastaApi | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "      Connection string gravada (user-secrets, fora do codigo-fonte)."
$senha = $null

Write-Host ""
Write-Host "Banco pronto: $banco em ${Servidor}:${Porta}" -ForegroundColor Green
if ($criouAgora -and -not $SemDadosIniciais) {
    Write-Host "Login de teste: admin@movetech.com  /  Admin@123"
} elseif ($totalUsuarios -eq 0) {
    Write-Host "ATENCAO: a tabela de usuarios esta vazia, entao ninguem consegue fazer login." -ForegroundColor Yellow
    Write-Host "Rode de novo com -Forcar para criar o usuario admin@movetech.com / Admin@123."
} else {
    Write-Host "Usuarios cadastrados: $totalUsuarios (use o login que voce ja tinha)."
}
Write-Host ""
Write-Host "Proximo passo:  .\2_iniciar_api.ps1"
