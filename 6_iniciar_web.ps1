# ------------------------------------------------------------------
# MoveTech - abre o sistema web do PIM III em http://localhost:5500
#
# Uso: dois cliques em 6_iniciar_web.cmd (deixe a janela aberta).
# A API so aceita o site vindo de localhost:5500 (regra de CORS),
# por isso o site e servido nesta porta. Nao precisa de administrador.
# Para parar: feche a janela ou Ctrl+C.
# ------------------------------------------------------------------

param(
    [int]$Porta = 5500
)

$ErrorActionPreference = "Stop"
$raiz = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "frontend"))
if (-not (Test-Path (Join-Path $raiz "index.html"))) {
    Write-Host "Nao encontrei frontend\index.html" -ForegroundColor Red
    exit 1
}

$tipos = @{
    ".html" = "text/html; charset=utf-8"; ".htm" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8";  ".js"  = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"; ".png" = "image/png"
    ".jpg"  = "image/jpeg"; ".jpeg" = "image/jpeg"; ".svg" = "image/svg+xml"
    ".ico"  = "image/x-icon"; ".woff2" = "font/woff2"; ".gif" = "image/gif"
}

$servidor = New-Object System.Net.HttpListener
$servidor.Prefixes.Add("http://localhost:$Porta/")
$servidor.Start()

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " Sistema web MoveTech:  http://localhost:$Porta/index.html" -ForegroundColor Green
Write-Host " Login: admin@movetech.com  /  Admin@123"
Write-Host " A API (2_iniciar_api.cmd) precisa estar aberta tambem."
Write-Host " Para parar: feche esta janela."
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

try {
    Start-Process "http://localhost:$Porta/index.html" | Out-Null
} catch { }

try {
    while ($servidor.IsListening) {
        $tarefa = $servidor.GetContextAsync()
        while (-not $tarefa.AsyncWaitHandle.WaitOne(300)) { }
        $contexto = $tarefa.GetAwaiter().GetResult()
        $resposta = $contexto.Response
        try {
            $caminho = [System.Uri]::UnescapeDataString($contexto.Request.Url.AbsolutePath).TrimStart("/")
            if ([string]::IsNullOrWhiteSpace($caminho)) { $caminho = "index.html" }
            $arquivo = [System.IO.Path]::GetFullPath((Join-Path $raiz $caminho))

            if ($arquivo.StartsWith($raiz, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path $arquivo -PathType Leaf)) {
                $bytes = [System.IO.File]::ReadAllBytes($arquivo)
                $ext = [System.IO.Path]::GetExtension($arquivo).ToLower()
                $tipo = $tipos[$ext]
                if (-not $tipo) { $tipo = "application/octet-stream" }
                $resposta.ContentType = $tipo
                $resposta.AddHeader("Cache-Control", "no-cache")
                $resposta.ContentLength64 = $bytes.Length
                $resposta.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $resposta.StatusCode = 404
                $bytes = [System.Text.Encoding]::UTF8.GetBytes("Nao encontrado")
                $resposta.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } catch {
        } finally {
            $resposta.Close()
        }
    }
} finally {
    $servidor.Stop()
}
