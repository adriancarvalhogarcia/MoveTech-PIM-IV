# ------------------------------------------------------------------
# MoveTech - redefine a senha do usuario root do MySQL (Windows)
#
# Use quando nao lembrar a senha do root. Precisa de administrador:
# de dois cliques em redefinir_senha_mysql.cmd e aceite o aviso do Windows.
#
# Como funciona (procedimento oficial do MySQL, "init-file"):
#  1. para o servico do MySQL;
#  2. sobe o MySQL uma vez com um arquivo que troca a senha do root;
#  3. desliga esse MySQL temporario e apaga o arquivo;
#  4. inicia o servico normalmente, ja com a senha nova.
# Nenhum dado do banco e apagado.
# ------------------------------------------------------------------

$ErrorActionPreference = "Stop"

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host "Execute pelo redefinir_senha_mysql.cmd (ele pede permissao de administrador)." -ForegroundColor Red
    exit 1
}

# 1. Localiza o servico, o mysqld.exe e o my.ini
$servico = Get-CimInstance Win32_Service | Where-Object { $_.Name -like "MySQL*" } | Select-Object -First 1
if (-not $servico) {
    Write-Host "Nenhum servico do MySQL encontrado." -ForegroundColor Red
    exit 1
}
$linha = $servico.PathName
$exe = $null
if ($linha -match '^"([^"]+mysqld\.exe)"') { $exe = $Matches[1] }
elseif ($linha -match '^(\S+mysqld\.exe)') { $exe = $Matches[1] }
$ini = $null
if ($linha -match '--defaults-file="([^"]+)"') { $ini = $Matches[1] }
elseif ($linha -match '--defaults-file=(\S+)') { $ini = $Matches[1] }

if (-not $exe -or -not (Test-Path $exe)) {
    Write-Host "Nao encontrei o mysqld.exe no servico $($servico.Name): $linha" -ForegroundColor Red
    exit 1
}
$pastaBin = Split-Path $exe
$mysqladmin = Join-Path $pastaBin "mysqladmin.exe"

Write-Host "Servico:  $($servico.Name)"
Write-Host "Programa: $exe"
if ($ini) { Write-Host "Config:   $ini" }
Write-Host ""

# 2. Senha nova (digitada duas vezes)
$s1 = [System.Net.NetworkCredential]::new("", (Read-Host "Nova senha do root" -AsSecureString)).Password
$s2 = [System.Net.NetworkCredential]::new("", (Read-Host "Repita a nova senha" -AsSecureString)).Password
if ([string]::IsNullOrEmpty($s1) -or $s1 -ne $s2) {
    Write-Host "As senhas estao vazias ou nao conferem. Nada foi alterado." -ForegroundColor Red
    exit 1
}

$arquivoInit = Join-Path $env:ProgramData "movetech_reset_root.sql"
$senhaSql = $s1.Replace("\", "\\").Replace("'", "''")
$sql = "ALTER USER 'root'@'localhost' IDENTIFIED BY '$senhaSql';`nFLUSH PRIVILEGES;`n"
[System.IO.File]::WriteAllText($arquivoInit, $sql, (New-Object System.Text.UTF8Encoding $false))

$processo = $null
try {
    # 3. Para o servico
    Write-Host "1/4 - Parando o servico $($servico.Name)..." -ForegroundColor Green
    Stop-Service -Name $servico.Name -Force
    Start-Sleep -Seconds 3

    # 4. Sobe o MySQL temporario com o init-file
    Write-Host "2/4 - Trocando a senha do root..." -ForegroundColor Green
    $argumentos = @()
    if ($ini) { $argumentos += "--defaults-file=`"$ini`"" }
    $argumentos += "--init-file=`"$($arquivoInit -replace '\\','/')`""
    $argumentos += "--console"
    $processo = Start-Process -FilePath $exe -ArgumentList $argumentos -WindowStyle Hidden -PassThru

    # Espera o MySQL temporario aceitar a senha nova (ate 90 s)
    $env:MYSQL_PWD = $s1
    $ok = $false
    for ($i = 0; $i -lt 45; $i++) {
        Start-Sleep -Seconds 2
        if ($processo.HasExited) { break }
        & $mysqladmin --user=root --host=127.0.0.1 ping 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $ok = $true; break }
    }

    # 5. Desliga o MySQL temporario
    Write-Host "3/4 - Desligando o MySQL temporario..." -ForegroundColor Green
    if ($ok) {
        & $mysqladmin --user=root --host=127.0.0.1 shutdown 2>$null | Out-Null
        $processo.WaitForExit(60000) | Out-Null
    }
    if (-not $processo.HasExited) { Stop-Process -Id $processo.Id -Force }
} finally {
    $env:MYSQL_PWD = $null
    if (Test-Path $arquivoInit) { Remove-Item $arquivoInit -Force }
    # 6. Volta o servico
    Write-Host "4/4 - Iniciando o servico $($servico.Name)..." -ForegroundColor Green
    Start-Sleep -Seconds 2
    try { Start-Service -Name $servico.Name } catch { Write-Host "Nao consegui iniciar o servico: $_" -ForegroundColor Red }
}

Write-Host ""
if ($ok) {
    Write-Host "Senha do root redefinida com sucesso." -ForegroundColor Green
    Write-Host "Agora rode o 1_preparar_banco.cmd e use a senha nova."
} else {
    Write-Host "Nao consegui confirmar a troca da senha." -ForegroundColor Red
    Write-Host "Veja o log de erro do MySQL em C:\ProgramData\MySQL\MySQL Server 8.0\Data\*.err"
}
