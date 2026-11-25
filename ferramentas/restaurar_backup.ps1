# ------------------------------------------------------------------
# MoveTech - RESTAURAR BACKUP
# Restaura o backup mais recente da pasta backups (ou o informado em
# -Arquivo). ATENCAO: substitui os dados atuais do banco.
# Feche a API antes. Uso: ferramentas\restaurar_backup.cmd
# ------------------------------------------------------------------
param([string]$Arquivo = "")
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_comum_mysql.ps1")

$conexao = Obter-Conexao
if (-not $Arquivo) {
    $Arquivo = Get-ChildItem (Join-Path $Raiz "backups") -Filter "*.sql" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $Arquivo -or -not (Test-Path $Arquivo)) { throw "Nenhum backup encontrado. Rode o backup_banco.cmd antes." }

Write-Host "Vai restaurar: $Arquivo" -ForegroundColor Yellow
Write-Host "Os dados atuais do banco $($conexao.Banco) serao substituidos."
$resposta = Read-Host "Digite SIM para continuar"
if ($resposta -ne "SIM") { Write-Host "Cancelado."; exit 0 }

$r = Invoke-MySql $conexao ("source " + ($Arquivo -replace '\\', '/')) -PermitirErro
if ($r.Ok) { Write-Host "Backup restaurado." -ForegroundColor Green } else { Write-Host "Falhou: $($r.Saida)" -ForegroundColor Red }
