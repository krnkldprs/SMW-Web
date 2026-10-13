# serve.ps1 - Servidor HTTP local mínimo para probar el proyecto SMW-Web.
# Uso:  powershell -ExecutionPolicy Bypass -File .\serve.ps1  [-Port 8080] [-Root <ruta>]
param(
    [int]$Port = 8080,
    [string]$Root = $PSScriptRoot
)

$Root = (Resolve-Path $Root).Path
$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.htm'  = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.wasm' = 'application/wasm'
    '.sfc'  = 'application/octet-stream'
    '.smc'  = 'application/octet-stream'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.bin'  = 'application/octet-stream'
    '.txt'  = 'text/plain; charset=utf-8'
}

try {
    $listener.Start()
} catch {
    Write-Host "No se pudo iniciar en el puerto $Port. Prueba otro: -Port 8081" -ForegroundColor Red
    exit 1
}

Write-Host "Sirviendo '$Root'" -ForegroundColor Green
Write-Host "Abre: $prefix" -ForegroundColor Cyan
Write-Host "Ctrl+C para detener." -ForegroundColor DarkGray

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response
        $isHead = ($req.HttpMethod -eq 'HEAD')

        # Un error en una petición no debe tumbar el servidor
        try {
            $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($rel)) { $rel = 'index.html' }

            $full = Join-Path $Root $rel
            $resolved = [System.IO.Path]::GetFullPath($full)

            # Evita salir de la raíz
            if (-not $resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
                $res.StatusCode = 403
            }
            elseif (Test-Path -LiteralPath $resolved -PathType Container) {
                $resolved = Join-Path $resolved 'index.html'
                if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { $res.StatusCode = 404 }
            }

            if ($res.StatusCode -eq 200 -and (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                $fi = New-Object System.IO.FileInfo($resolved)
                $ext = [System.IO.Path]::GetExtension($resolved).ToLowerInvariant()
                $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }

                foreach ($h in @(@('Cache-Control', 'no-cache'), @('Accept-Ranges', 'bytes'),
                                 @('Last-Modified', $fi.LastWriteTimeUtc.ToString('R')))) {
                    try { $res.Headers.Add($h[0], $h[1]) } catch { }
                }

                $length = $fi.Length
                $start = 0
                $rangeHeader = $req.Headers['Range']

                if ($rangeHeader -and $rangeHeader -match 'bytes=(\d*)-(\d*)') {
                    $start = if ($matches[1]) { [int64]$matches[1] } else { 0 }
                    $end = if ($matches[2]) { [int64]$matches[2] } else { $length - 1 }
                    if ($end -ge $length) { $end = $length - 1 }
                    if ($start -gt $end -or $start -ge $length) {
                        $res.StatusCode = 416
                        $res.Headers.Add('Content-Range', "bytes */$length")
                    } else {
                        $count = [int]($end - $start + 1)
                        $res.StatusCode = 206
                        try { $res.Headers.Add('Content-Range', "bytes $start-$end/$length") } catch { }
                        $res.ContentLength64 = $count
                        if (-not $isHead) {
                            $fs = [System.IO.File]::OpenRead($resolved)
                            try {
                                [void]$fs.Seek($start, [System.IO.SeekOrigin]::Begin)
                                $buf = New-Object byte[] 65536
                                $remaining = $count
                                while ($remaining -gt 0) {
                                    $toRead = [Math]::Min($buf.Length, $remaining)
                                    $read = $fs.Read($buf, 0, $toRead)
                                    if ($read -le 0) { break }
                                    $res.OutputStream.Write($buf, 0, $read)
                                    $remaining -= $read
                                }
                            } finally { $fs.Close() }
                        }
                    }
                } else {
                    $res.ContentLength64 = $length
                    if (-not $isHead) {
                        $res.OutputStream.Write([System.IO.File]::ReadAllBytes($resolved), 0, [int]$length)
                    }
                }
            }
            elseif ($res.StatusCode -eq 404) {
                $msg = [System.Text.Encoding]::UTF8.GetBytes("404 - No encontrado: $rel")
                $res.ContentType = 'text/plain; charset=utf-8'
                $res.ContentLength64 = $msg.Length
                if (-not $isHead) { $res.OutputStream.Write($msg, 0, $msg.Length) }
            }
        } catch {
            Write-Host "[error] $($req.HttpMethod) $($req.Url.AbsolutePath): $($_.Exception.Message)" -ForegroundColor DarkYellow
            try { if ($res.ContentLength64 -eq 0) { $res.StatusCode = 500 } } catch { }
        } finally {
            try { $res.OutputStream.Close() } catch { }
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
