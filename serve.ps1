$root = $PSScriptRoot
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://localhost:8000/')
$listener.Start()
Write-Host "Server läuft unter http://localhost:8000/"

$mimeTypes = @{
    '.html' = 'text/html'
    '.js'   = 'application/javascript'
    '.css'  = 'text/css'
    '.json' = 'application/json'
    '.glb'  = 'model/gltf-binary'
    '.gltf' = 'model/gltf+json'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.bin'  = 'application/octet-stream'
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $requestPath = $context.Request.Url.AbsolutePath
    if ($requestPath -eq '/') { $requestPath = '/index.html' }

    $fullPath = Join-Path $root ($requestPath.TrimStart('/'))
    if (Test-Path $fullPath -PathType Leaf) {
        $extension = [System.IO.Path]::GetExtension($fullPath).ToLower()
        $contentType = 'application/octet-stream'
        if ($mimeTypes.ContainsKey($extension)) { $contentType = $mimeTypes[$extension] }

        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $response = $context.Response
        $response.ContentType = $contentType
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.OutputStream.Close()
    } else {
        $response = $context.Response
        $buffer = [System.Text.Encoding]::UTF8.GetBytes('Nicht gefunden')
        $response.StatusCode = 404
        $response.ContentType = 'text/plain'
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.OutputStream.Close()
    }
}
