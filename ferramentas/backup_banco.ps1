# ------------------------------------------------------------------
# MoveTech - BACKUP DO BANCO (Etapa 8: backup e recuperacao)
#
# Gera backups\smartmoveis_AAAAMMDD_HHMM.sql com tabelas, dados,
# triggers e procedures (mysqldump --routines --triggers) e mantem
# os 7 backups mais recentes. Pode ser agendado no Agendador de
# Tarefas do Windows para rodar todo dia.
#
# Restaurar: ferramentas\restaurar_backup.cmd (escolhe o mais recente)
# Uso: dois cliques em ferramentas\backup_banco.cmd
# ------------------------------------------------------------------
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_comum_mysql.ps1")

$conexao = Obter-Conexao
$bin = Obter-BinMysql
$pasta = Join-Path $Raiz "backups"
New-Item -ItemType Directory -Force -Path $pasta | Out-Null
$arquivo = Join-Path $pasta ("{0}_{1}.sql" -f $conexao.Banco, (Get-Date -Format "yyyyMMdd_HHmm"))

Write-Host "Gerando backup de $($conexao.Banco)..." -ForegroundColor Cyan
$env:MYSQL_PWD = $conexao.Senha
$ErrorActionPreference = "Continue"
try {
    & (Join-Path $bin "mysqldump.exe") "--host=$($conexao.Servidor)" "--port=$($conexao.Porta)" "--user=$($conexao.Usuario)" `
        --single-transaction --routines --triggers --default-character-set=utf8mb4 `
        --databases $conexao.Banco "--result-file=$arquivo"
    if ($LASTEXITCODE -ne 0) { throw "mysqldump falhou." }
} finally {
    $env:MYSQL_PWD = $null
}

$info = Get-Item $arquivo
$triggers = @(Select-String -Path $arquivo -Pattern "TRIGGER ``trg_").Count
$procs = @(Select-String -Path $arquivo -Pattern "PROCEDURE ``sp_.*\(").Count
Write-Host ("Backup criado: backups\{0} ({1:N0} KB, {2} triggers, {3} procedures)" -f $info.Name, ($info.Length / 1KB), $triggers, $procs) -ForegroundColor Green

# Rotacao: mantem os 7 mais recentes
Get-ChildItem $pasta -Filter "$($conexao.Banco)_*.sql" | Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 7 | Remove-Item -Force
