# ------------------------------------------------------------------
# MoveTech - disponibiliza o MoveTech.apk para download na rede local
#
# Uso (PowerShell aberto COMO ADMINISTRADOR):
#   powershell -ExecutionPolicy Bypass -File .\4_compartilhar_apk.ps1
#
# Depois, no navegador do celular (mesmo Wi-Fi), abra o endereco que
# o script mostrar, por exemplo:  http://192.168.0.15:8080
#
# Para encerrar: Ctrl+C.
#
# Alternativas sem este script: enviar o MoveTech.apk por cabo USB,
# Google Drive, e-mail ou WhatsApp.
# ------------------------------------------------------------------

param(
    [int]$Porta = 8080
)

$ErrorActionPreference = "Stop"
$apk = Join-Path $PSScriptRoot "MoveTech.apk"

if (-not (Test-Path $apk)) {
    Write-Host "Nao encontrei o MoveTech.apk. Gere primeiro:  .\3_gerar_apk.ps1" -ForegroundColor Red
    exit 1
}

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Host "Este script precisa do PowerShell aberto como administrador," -ForegroundColor Red
    Write-Host "porque abre uma porta de rede e libera o firewall."
    Write-Host "Menu Iniciar > digite PowerShell > botao direito > Executar como administrador."
    exit 1
}

if (-not (Get-NetFirewallRule -DisplayName "MoveTech APK" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "MoveTech APK" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Porta | Out-Null
}

$ip = ""
try {
    $ip = (Get-NetIPConfiguration |
        Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq "Up" } |
        Select-Object -First 1).IPv4Address.IPAddress
} catch { }
if (-not $ip) { $ip = "IP-DESTE-COMPUTADOR" }

$servidor = New-Object System.Net.HttpListener
$servidor.Prefixes.Add("http://+:$Porta/")
$servidor.Start()

$tamanhoMb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " No navegador do celular (mesmo Wi-Fi), abra:" -ForegroundColor Cyan
Write-Host "   http://${ip}:${Porta}" -ForegroundColor Green
Write-Host " Arquivo: MoveTech.apk ($tamanhoMb MB)"
Write-Host " Para encerrar: Ctrl+C"
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

$pagina = @"
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MoveTech - download do app</title>
<style>
body{font-family:sans-serif;background:#020704;color:#f5f7f5;text-align:center;padding:48px 20px}
a{display:inline-block;background:#32e05f;color:#021006;font-weight:bold;font-size:20px;
padding:18px 28px;border-radius:12px;text-decoration:none;margin-top:24px}
p{color:#a5aea7;max-width:420px;margin:16px auto;line-height:1.5}
</style></head><body>
<h1>MoveTech</h1>
<p>Aplicativo Android para teste na rede local.</p>
<a href="/MoveTech.apk">Baixar o aplicativo ($tamanhoMb MB)</a>
<p>Depois de baixar, toque no arquivo e autorize a instala&ccedil;&atilde;o de apps desconhecidos.</p>
</body></html>
"@

try {
    while ($servidor.IsListening) {
        # Espera assincrona, para o Ctrl+C funcionar.
        $tarefa = $servidor.GetContextAsync()
        while (-not $tarefa.AsyncWaitHandle.WaitOne(300)) { }
        $contexto = $tarefa.GetAwaiter().GetResult()
        $resposta = $contexto.Response
        $caminho = $contexto.Request.Url.AbsolutePath

        try {
            if ($caminho -eq "/MoveTech.apk") {
                $bytes = [System.IO.File]::ReadAllBytes($apk)
                $resposta.ContentType = "application/vnd.android.package-archive"
                $resposta.AddHeader("Content-Disposition", "attachment; filename=MoveTech.apk")
                $resposta.ContentLength64 = $bytes.Length
                $resposta.OutputStream.Write($bytes, 0, $bytes.Length)
                Write-Host ("{0}  download por {1}" -f (Get-Date -Format "HH:mm:ss"), $contexto.Request.RemoteEndPoint.Address)
            } else {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($pagina)
                $resposta.ContentType = "text/html; charset=utf-8"
                $resposta.ContentLength64 = $bytes.Length
                $resposta.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } catch {
            # O celular cancelou o download: segue atendendo.
        } finally {
            $resposta.Close()
        }
    }
} finally {
    $servidor.Stop()
    Write-Host "Compartilhamento encerrado."
}
